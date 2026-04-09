import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:livekit_client/livekit_client.dart';

import '../core/utils/livekit_url.dart';

/// WebRTC emergency voice bridge (victim, dispatch, contact, Lifeline agent in one room).
///
/// Uses:
/// - `getLivekitToken` — join token for `emergency_bridge_{incidentId}`
/// - `ensureEmergencyBridge` — victim-only; dispatches the Lifeline voice agent (no phone/SIP)
enum LiveKitBridgeRole {
  victim,
  emergencyDesk,
  emergencyContact,
  /// Any volunteer who has accepted this SOS (`acceptedVolunteerIds`).
  acceptedVolunteer,
  /// Trained volunteer — server requires arena level 10 or (5 lives helped & 1000 XP).
  volunteerElite,
}

extension LiveKitBridgeRoleApi on LiveKitBridgeRole {
  String get apiValue => switch (this) {
        LiveKitBridgeRole.victim => 'victim',
        LiveKitBridgeRole.emergencyDesk => 'emergency_desk',
        LiveKitBridgeRole.emergencyContact => 'emergency_contact',
        LiveKitBridgeRole.acceptedVolunteer => 'accepted_volunteer',
        LiveKitBridgeRole.volunteerElite => 'volunteer_elite',
      };
}

/// EmergencyOS: LivekitEmergencyBridgeService in lib/services/livekit_emergency_bridge_service.dart.
class LivekitEmergencyBridgeService {
  static String roomNameForIncident(String incidentId) => 'emergency_bridge_$incidentId';

  static String victimIdentity(String uid, {String variant = ''}) {
    final v = variant.trim();
    return v.isEmpty ? 'victim_$uid' : 'victim_${uid}_$v';
  }

  static Future<void> ensureEmergencyBridge({required String incidentId}) async {
    final callable = FirebaseFunctions.instance.httpsCallable('ensureEmergencyBridge');
    await callable.call({'incidentId': incidentId});
  }

  /// Dispatches a Lifeline agent job so the agent reads the provided text.
  static Future<void> dispatchLifelineComms({
    required String incidentId,
    required String text,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('dispatchLifelineComms');
    await callable.call({
      'incidentId': incidentId,
      'text': text,
    });
  }

  /// Connects the caller to the LiveKit emergency bridge room.
  ///
  /// [role] — `victim` (default), `emergency_desk`, `emergency_contact` (phone / contact link),
  /// `accepted_volunteer` (must be in incident `acceptedVolunteerIds`), or `volunteer_elite`.
  static Future<Room> connectToEmergencyBridge({
    required String incidentId,
    required String uid,
    required String variant,
    required bool canPublishAudio,
    LiveKitBridgeRole role = LiveKitBridgeRole.victim,
    /// When true, joins with microphone muted (victim SOS: PTT only). Volunteers should use false.
    bool muteOnConnect = false,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('getLivekitToken');
    final res = await callable.call({
      'incidentId': incidentId,
      'canPublishAudio': canPublishAudio,
      'variant': variant,
      'role': role.apiValue,
    });

    final data = (res.data as Map?) ?? const {};
    final token = (data['token'] ?? '').toString();
    final url = LivekitUrl.normalizeForClient((data['url'] ?? '').toString());
    final roomName = (data['roomName'] ?? '').toString();

    if (token.isEmpty || url.isEmpty || roomName.isEmpty) {
      throw StateError('LiveKit token response missing fields.');
    }

    final room = Room();
    final roomOptions = RoomOptions(
      adaptiveStream: true,
      dynacast: true,
    );

    await room.connect(url, token, roomOptions: roomOptions);
    final local = room.localParticipant;
    if (local == null) {
      throw StateError('LiveKit local participant is null after connect.');
    }

    final micOn = !muteOnConnect && canPublishAudio;
    await local.setMicrophoneEnabled(micOn);

    return room;
  }

  /// Sends a compact important comms payload to the room.
  ///
  /// The Lifeline voice agent should read and speak this content.
  static Future<void> sendImportantComms({
    required Room room,
    required String incidentId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final payload = jsonEncode(<String, dynamic>{
      'type': 'important_comms',
      'incidentId': incidentId,
      'text': text.trim(),
    });

    final local = room.localParticipant;
    if (local == null) return;

    await local.publishData(
      utf8.encode(payload),
      reliable: true,
      topic: 'lifeline_comms',
    );
  }
}
