import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/copilot_prefs.dart';
import '../core/utils/livekit_url.dart';

/// EmergencyOS: CopilotAgentSosCallback in lib/services/copilot_livekit_service.dart.
typedef CopilotAgentSosCallback = void Function(String reason, String nonce);

/// LiveKit room `copilot_{uid}` + data channel for page context and agent actions.
class CopilotLivekitController extends ChangeNotifier {
  CopilotLivekitController();

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _connecting = false;

  CopilotAgentSosCallback? onAgentRequestedSos;

  Room? get room => _room;

  bool get isConnecting => _connecting;

  bool get isConnected =>
      _room != null && _room!.connectionState == ConnectionState.connected;

  /// True when any participant (usually the agent) is speaking.
  bool get hasActiveSpeakers =>
      _room != null && _room!.activeSpeakers.isNotEmpty;

  Future<void> connect({required bool publishMic}) async {
    if (_connecting || isConnected) return;
    _connecting = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final walkthrough =
          prefs.getBool(CopilotPrefs.voiceWalkthroughEnabled) ?? false;

      final ensure = FirebaseFunctions.instance.httpsCallable('ensureCopilotAgent');
      await ensure.call(<String, dynamic>{'walkthrough': walkthrough});

      final tokenFn = FirebaseFunctions.instance.httpsCallable('getCopilotLivekitToken');
      final res = await tokenFn.call(<String, dynamic>{
        'canPublishAudio': publishMic,
      });

      final data = (res.data as Map?) ?? const {};
      final token = (data['token'] ?? '').toString();
      final url = LivekitUrl.normalizeForClient((data['url'] ?? '').toString());
      if (token.isEmpty || url.isEmpty) {
        throw StateError('Copilot token response missing fields.');
      }

      final room = Room(
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );
      await room.connect(
        url,
        token,
      );

      final local = room.localParticipant;
      if (local != null) {
        await local.setMicrophoneEnabled(publishMic);
      }

      await _listener?.cancelAll();
      _listener = room.createListener()
        ..on<DataReceivedEvent>((e) {
          if (e.topic != 'copilot_action') return;
          try {
            final obj = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>?;
            if (obj == null) return;
            if (obj['type'] == 'request_sos') {
              final reason = (obj['reason'] ?? '').toString();
              final nonce = (obj['nonce'] ?? '').toString();
              onAgentRequestedSos?.call(reason, nonce);
            }
          } catch (_) {}
        });

      room.addListener(_onRoomChanged);
      _room = room;

      final lastContext = await _loadPersistedContext();
      if (lastContext != null && room.localParticipant != null) {
        try {
          await room.localParticipant!.publishData(
            utf8.encode(jsonEncode(lastContext)),
            reliable: true,
            topic: 'copilot_context',
          );
          debugPrint('[Copilot] restored persisted context');
        } catch (e) {
          debugPrint('[Copilot] failed to restore context: $e');
        }
      }
    } catch (e, st) {
      debugPrint('[Copilot] connect failed: $e\n$st');
      await _cleanupRoom();
    } finally {
      _connecting = false;
      notifyListeners();
    }
  }

  void _onRoomChanged() {
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _cleanupRoom();
    notifyListeners();
  }

  Future<void> _cleanupRoom() async {
    _room?.removeListener(_onRoomChanged);
    final r = _room;
    _room = null;
    await _listener?.cancelAll();
    _listener = null;
    if (r != null) {
      try {
        await r.disconnect();
        await r.dispose();
      } catch (_) {}
    }
  }

  static Future<void> _persistContext(Map<String, dynamic> context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('copilot_last_context', jsonEncode(context));
      await prefs.setString(
          'copilot_session_start', DateTime.now().toIso8601String());
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> _loadPersistedContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('copilot_last_context');
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('copilot_last_context');
      await prefs.remove('copilot_session_start');
    } catch (_) {}
  }

  /// Pushes latest route/title to the agent (topic `copilot_context`).
  Future<void> publishPageContext({
    required String route,
    required String title,
    String digest = '',
    required bool walkthrough,
  }) async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final payload = jsonEncode(<String, dynamic>{
      'route': route,
      'title': title,
      'digest': digest,
      'walkthrough': walkthrough,
    });
    try {
      await local.publishData(
        utf8.encode(payload),
        reliable: true,
        topic: 'copilot_context',
      );
      unawaited(_persistContext(<String, dynamic>{
        'route': route,
        'title': title,
        'digest': digest,
        'walkthrough': walkthrough,
      }));
    } catch (e) {
      debugPrint('[Copilot] publishPageContext: $e');
    }
  }

  @override
  void dispose() {
    unawaited(_cleanupRoom());
    super.dispose();
  }
}

final copilotLivekitProvider =
    ChangeNotifierProvider<CopilotLivekitController>((ref) {
  final c = CopilotLivekitController();
  ref.onDispose(c.dispose);
  return c;
});
