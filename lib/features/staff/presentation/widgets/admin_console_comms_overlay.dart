import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/utils/livekit_ui_sounds.dart';
import '../../../../core/widgets/livekit_voice_party_strip.dart';
import '../../../../services/livekit_admin_console_service.dart';
import '../../domain/admin_panel_access.dart';

class _ChatEntry {
  _ChatEntry({
    required this.text,
    required this.sender,
    required this.mine,
    required this.at,
  });

  final String text;
  final String sender;
  final bool mine;
  final DateTime at;
}

/// Floating entry to LiveKit `admin_console_bridge`: voice + text chat between master and hospital consoles.
class AdminConsoleCommsOverlay extends StatefulWidget {
  const AdminConsoleCommsOverlay({super.key, required this.access});

  final AdminPanelAccess access;

  @override
  State<AdminConsoleCommsOverlay> createState() => _AdminConsoleCommsOverlayState();
}

class _AdminConsoleCommsOverlayState extends State<AdminConsoleCommsOverlay> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _busy = false;
  bool _panelOpen = false;
  bool _micOn = true;
  final _chatCtrl = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_ChatEntry>[];
  final Set<String> _speakingIdentities = {};

  @override
  void dispose() {
    _listener?.dispose();
    final r = _room;
    _room = null;
    if (r != null) {
      unawaited(r.disconnect());
      unawaited(r.dispose());
    }
    _chatCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _selfLabel {
    final u = FirebaseAuth.instance.currentUser;
    if (widget.access.role == AdminConsoleRole.master) {
      final p = widget.access.previewAsHospitalDocId?.trim();
      if (p != null && p.isNotEmpty) {
        return '${u?.email ?? 'Master'} (as $p)';
      }
      return u?.email ?? 'Master console';
    }
    final hid = widget.access.boundHospitalDocId ?? '';
    return hid.isEmpty ? 'Hospital console' : 'Hospital ($hid)';
  }

  String _remoteBridgeLabel(RemoteParticipant p) {
    final id = p.identity;
    if (id.startsWith('adm_m_')) return 'Master console';
    if (id.startsWith('adm_h_')) return 'Hospital console';
    return id.isEmpty ? 'Guest' : id;
  }

  List<LivekitVoicePartyAvatar> _partyAvatars(Room room) {
    final out = <LivekitVoicePartyAvatar>[];
    final lp = room.localParticipant;
    if (lp != null) {
      final id = lp.identity.trim();
      out.add(
        LivekitVoicePartyAvatar(
          label: _selfLabel,
          isLocal: true,
          isSpeaking: id.isNotEmpty && _speakingIdentities.contains(id),
        ),
      );
    }
    for (final p in room.remoteParticipants.values) {
      final id = p.identity.trim();
      out.add(
        LivekitVoicePartyAvatar(
          label: _remoteBridgeLabel(p),
          isSpeaking: id.isNotEmpty && _speakingIdentities.contains(id),
        ),
      );
    }
    return out;
  }

  Future<void> _connect() async {
    if (_busy || _room != null) return;
    setState(() => _busy = true);
    try {
      await _disconnect();
      final room = await LivekitAdminConsoleService.connect(
        access: widget.access,
        canPublishAudio: _micOn,
      );
      if (!mounted) {
        await room.disconnect();
        await room.dispose();
        return;
      }
      if (kIsWeb) {
        unawaited(room.startAudio());
      }

      _listener = room.createListener()
        ..on<ParticipantConnectedEvent>((e) {
          final lid = room.localParticipant?.identity ?? '';
          final pid = e.participant.identity;
          if (pid.isNotEmpty && pid != lid) {
            unawaited(LivekitUiSounds.playJoin());
          }
          if (mounted) setState(() {});
        })
        ..on<ParticipantDisconnectedEvent>((e) {
          final lid = room.localParticipant?.identity ?? '';
          final pid = e.participant.identity;
          if (pid.isNotEmpty && pid != lid) {
            unawaited(LivekitUiSounds.playLeave());
          }
          if (mounted) setState(() {});
        })
        ..on<ActiveSpeakersChangedEvent>((e) {
          if (!mounted) return;
          setState(() {
            _speakingIdentities
              ..clear()
              ..addAll(
                e.speakers.map((s) => s.identity.trim()).where((id) => id.isNotEmpty),
              );
          });
        })
        ..on<DataReceivedEvent>((e) {
          if (e.topic != LivekitAdminConsoleService.chatTopic) return;
          try {
            final obj = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>?;
            if (obj == null) return;
            final text = (obj['text'] ?? '').toString();
            if (text.isEmpty) return;
            final sender = (obj['sender'] ?? 'Console').toString();
            final from = (obj['fromUid'] ?? '').toString();
            final mine = from == FirebaseAuth.instance.currentUser?.uid;
            if (!mounted) return;
            setState(() {
              _messages.add(_ChatEntry(
                text: text,
                sender: sender,
                mine: mine,
                at: DateTime.now(),
              ));
            });
            _scrollToEnd();
          } catch (_) {}
        })
        ..on<RoomDisconnectedEvent>((_) {
          if (!mounted) return;
          setState(() => _room = null);
        });

      setState(() => _room = room);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Console bridge: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    _listener?.dispose();
    _listener = null;
    final r = _room;
    _room = null;
    if (r != null) {
      await r.disconnect();
      await r.dispose();
    }
    if (mounted) {
      setState(() {
        _speakingIdentities.clear();
      });
    }
  }

  Future<void> _toggleMic(bool on) async {
    setState(() => _micOn = on);
    final lp = _room?.localParticipant;
    if (lp != null) {
      try {
        await lp.setMicrophoneEnabled(on);
      } catch (_) {}
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendChat() async {
    final raw = _chatCtrl.text.trim();
    if (raw.isEmpty) return;
    final room = _room;
    final lp = room?.localParticipant;
    if (lp == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join the bridge before sending chat.')),
        );
      }
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final payload = jsonEncode({
      'v': 1,
      'text': raw,
      'sender': _selfLabel,
      'fromUid': uid,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    try {
      await lp.publishData(
        utf8.encode(payload),
        reliable: true,
        topic: LivekitAdminConsoleService.chatTopic,
      );
      setState(() {
        _messages.add(_ChatEntry(text: raw, sender: _selfLabel, mine: true, at: DateTime.now()));
        _chatCtrl.clear();
      });
      _scrollToEnd();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_panelOpen)
          Positioned(
            right: 220,
            bottom: 16,
            child: _buildPanel(context),
          ),
        if (!_panelOpen)
          Positioned(
            right: 228,
            bottom: 24,
            child: FloatingActionButton.extended(
              heroTag: 'admin_console_comms_fab',
              onPressed: () => setState(() => _panelOpen = true),
              icon: const Icon(Icons.headset_mic_rounded),
              label: const Text('Hospital bridge'),
              backgroundColor: const Color(0xFF0D9488),
            ),
          ),
      ],
    );
  }

  Widget _buildPanel(BuildContext context) {
    final connected = _room != null && _room!.connectionState == ConnectionState.connected;
    final room = _room;

    return Material(
      elevation: 12,
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520, minWidth: 320, minHeight: 360),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.hub_rounded, color: Color(0xFF5EEAD4), size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Master ↔ Hospital bridge',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => setState(() => _panelOpen = false),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'LiveKit · ${LivekitAdminConsoleService.roomNameFixed}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10),
                  ),
                ),
                const SizedBox(height: 8),
                if (connected && room != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: LivekitVoicePartyStrip(avatars: _partyAvatars(room)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () {
                                  if (connected) {
                                    unawaited(_disconnect());
                                  } else {
                                    unawaited(_connect());
                                  }
                                },
                          icon: Icon(connected ? Icons.link_off : Icons.link),
                          label: Text(connected ? 'Leave' : 'Join voice bridge'),
                          style: FilledButton.styleFrom(
                            backgroundColor: connected ? Colors.red.shade800 : const Color(0xFF0D9488),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.mic, color: Colors.white54, size: 18),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch.adaptive(
                              value: _micOn,
                              onChanged: connected ? (v) => unawaited(_toggleMic(v)) : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: m.mine
                                ? const Color(0xFF134E4A).withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.sender,
                                style: TextStyle(
                                  color: Colors.tealAccent.shade100,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.25)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Message…',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.35),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => unawaited(_sendChat()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => unawaited(_sendChat()),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: const Size(44, 44),
                        ),
                        child: const Icon(Icons.send_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
