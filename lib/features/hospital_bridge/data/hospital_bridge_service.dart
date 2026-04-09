import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../core/utils/livekit_ui_sounds.dart';
import '../../../core/utils/livekit_url.dart';
import '../domain/bridge_voice_state.dart';

class HospitalBridgeService extends ChangeNotifier {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _micOn = true;
  bool _deafened = false;
  final Set<String> _speakingIdentities = {};
  final List<BridgeChatMessage> _messages = [];
  final Map<String, String> _participantDisplayNames = {};

  Room? get room => _room;
  bool get isConnected => _room != null;
  bool get micOn => _micOn;
  bool get deafened => _deafened;
  List<BridgeChatMessage> get messages => List.unmodifiable(_messages);
  Set<String> get speakingIdentities => Set.unmodifiable(_speakingIdentities);
  Map<String, String> get participantDisplayNames =>
      Map.unmodifiable(_participantDisplayNames);

  Future<Room> connect({
    required String serverId,
    required String channelId,
    required String userId,
    required String displayName,
    required String? hospitalId,
  }) async {
    await disconnect();

    final callable = FirebaseFunctions.instance.httpsCallable(
      'getHospitalBridgeToken',
    );
    final res = await callable.call({
      'serverId': serverId,
      'channelId': channelId,
      'canPublishAudio': _micOn && !_deafened,
    });

    final data = (res.data as Map?) ?? const {};
    final token = (data['token'] ?? '').toString();
    final url = LivekitUrl.normalizeForClient((data['url'] ?? '').toString());
    final roomName = (data['roomName'] ?? '').toString();

    if (token.isEmpty || url.isEmpty || roomName.isEmpty) {
      throw StateError(
        'Hospital Bridge LiveKit token response missing fields.',
      );
    }

    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    await room.connect(url, token);

    final local = room.localParticipant;
    if (local == null) {
      throw StateError('LiveKit local participant is null after connect.');
    }
    await local.setMicrophoneEnabled(_micOn && !_deafened);

    _room = room;
    _setupListeners(userId, displayName, hospitalId);

    if (kIsWeb) {
      unawaited(room.startAudio());
    }

    notifyListeners();
    return room;
  }

  void _setupListeners(String userId, String displayName, String? hospitalId) {
    final room = _room;
    if (room == null) return;

    _listener = room.createListener()
      ..on<ParticipantConnectedEvent>((e) {
        _participantDisplayNames[e.participant.identity] = _extractDisplayName(
          e.participant,
        );
        LivekitUiSounds.playJoin();
        notifyListeners();
      })
      ..on<ParticipantDisconnectedEvent>((e) {
        _participantDisplayNames.remove(e.participant.identity);
        _speakingIdentities.remove(e.participant.identity);
        LivekitUiSounds.playLeave();
        notifyListeners();
      })
      ..on<ActiveSpeakersChangedEvent>((e) {
        _speakingIdentities
          ..clear()
          ..addAll(
            e.speakers
                .map((s) => s.identity.trim())
                .where((id) => id.isNotEmpty),
          );
        notifyListeners();
      })
      ..on<TrackPublishedEvent>((_) => notifyListeners())
      ..on<TrackSubscribedEvent>((_) => notifyListeners())
      ..on<TrackUnsubscribedEvent>((_) => notifyListeners())
      ..on<DataReceivedEvent>((e) {
        if (e.topic != 'bridge_chat') return;
        try {
          final obj = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>;
          if (obj['type'] == 'bridge_chat') {
            _messages.add(BridgeChatMessage.fromData(obj));
            notifyListeners();
          }
        } catch (_) {}
      });

    _participantDisplayNames[room.localParticipant?.identity ?? ''] =
        displayName;
  }

  String _extractDisplayName(RemoteParticipant p) {
    final metadata = p.metadata;
    if (metadata != null && metadata.isNotEmpty) {
      try {
        final obj = jsonDecode(metadata) as Map<String, dynamic>;
        final name = (obj['displayName'] as String?)?.trim();
        if (name != null && name.isNotEmpty) return name;
      } catch (_) {}
    }
    final identity = p.identity;
    if (identity.startsWith('hosp_')) return 'Hospital Admin';
    if (identity.startsWith('master_')) return 'Master Admin';
    return identity;
  }

  Future<void> disconnect() async {
    _listener?.dispose();
    _listener = null;
    final r = _room;
    _room = null;
    _speakingIdentities.clear();
    _messages.clear();
    _participantDisplayNames.clear();
    if (r != null) {
      try {
        await r.localParticipant?.setMicrophoneEnabled(false);
      } catch (_) {}
      await r.disconnect();
      await r.dispose();
    }
    _micOn = true;
    _deafened = false;
    notifyListeners();
  }

  Future<void> toggleMic() async {
    final r = _room;
    if (r == null) return;
    _micOn = !_micOn;
    try {
      await r.localParticipant?.setMicrophoneEnabled(_micOn && !_deafened);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleDeafen() async {
    final r = _room;
    if (r == null) return;
    _deafened = !_deafened;
    try {
      await r.localParticipant?.setMicrophoneEnabled(_micOn && !_deafened);
      for (final rp in r.remoteParticipants.values) {
        for (final trackPub in rp.audioTrackPublications) {
          if (_deafened) {
            await trackPub.unsubscribe();
          } else {
            await trackPub.subscribe();
          }
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> sendChatMessage({
    required String userId,
    required String displayName,
    String? hospitalId,
    required String content,
  }) async {
    final r = _room;
    if (r == null || content.trim().isEmpty) return;
    final local = r.localParticipant;
    if (local == null) return;

    final msg = BridgeChatMessage.createLocal(
      userId: userId,
      displayName: displayName,
      hospitalId: hospitalId,
      content: content.trim(),
    );
    _messages.add(msg);
    notifyListeners();

    try {
      await local.publishData(
        utf8.encode(jsonEncode(msg.toData())),
        reliable: true,
        topic: 'bridge_chat',
      );
    } catch (_) {
      _messages.remove(msg);
      notifyListeners();
    }
  }

  List<BridgeVoiceState> getVoiceStates() {
    final r = _room;
    if (r == null) return [];
    final states = <BridgeVoiceState>[];

    final lp = r.localParticipant;
    if (lp != null) {
      states.add(
        BridgeVoiceState(
          participantId: lp.identity,
          displayName: _participantDisplayNames[lp.identity] ?? 'You',
          isLocal: true,
          mic: _micOn ? BridgeMicState.on : BridgeMicState.muted,
          hearing: _deafened
              ? BridgeHearState.deafened
              : BridgeHearState.hearing,
          isSpeaking: _speakingIdentities.contains(lp.identity),
        ),
      );
    }

    for (final rp in r.remoteParticipants.values) {
      final identity = rp.identity;
      states.add(
        BridgeVoiceState(
          participantId: identity,
          displayName: _participantDisplayNames[identity] ?? identity,
          isLocal: false,
          isSpeaking: _speakingIdentities.contains(identity),
        ),
      );
    }

    return states;
  }

  @override
  void dispose() {
    unawaited(disconnect());
    super.dispose();
  }
}
