import 'package:cloud_functions/cloud_functions.dart';
import 'package:livekit_client/livekit_client.dart';

import '../core/utils/livekit_url.dart';
import '../features/staff/domain/admin_panel_access.dart';

/// Discord-style ops voice: command net (master) + per-incident Operation / Emergency channels.
abstract final class LivekitCommsBridgeService {
  static Future<void> ensureIncidentRooms({
    required String incidentId,
    String? boundHospitalDocId,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'ensureCommsBridgeRooms',
    );
    await callable.call({
      'incidentId': incidentId,
      if (boundHospitalDocId != null && boundHospitalDocId.trim().isNotEmpty)
        'boundHospitalId': boundHospitalDocId.trim(),
    });
  }

  /// [channel]: `command` (master only), `operation`, `emergency`.
  static Future<Room> connect({
    required AdminPanelAccess access,
    required String channel,
    String? incidentId,
    bool canPublishAudio = true,
  }) async {
    final hid = access.boundHospitalDocId?.trim();
    final callable = FirebaseFunctions.instance.httpsCallable(
      'getCommsBridgeLivekitToken',
    );
    final res = await callable.call({
      'channel': channel,
      'canPublishAudio': canPublishAudio,
      if (incidentId != null && incidentId.trim().isNotEmpty)
        'incidentId': incidentId.trim(),
      if (hid != null && hid.isNotEmpty) 'boundHospitalId': hid,
    });

    final data = (res.data as Map?) ?? const {};
    final token = (data['token'] ?? '').toString();
    final url = LivekitUrl.normalizeForClient((data['url'] ?? '').toString());
    final roomName = (data['roomName'] ?? '').toString();

    if (token.isEmpty || url.isEmpty || roomName.isEmpty) {
      throw StateError('Comms bridge token response missing fields.');
    }

    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    await room.connect(url, token);
    final local = room.localParticipant;
    if (local == null) {
      throw StateError('LiveKit local participant is null after connect.');
    }
    await local.setMicrophoneEnabled(canPublishAudio);
    return room;
  }

  /// Hospital comms bridge for **fleet operators** (allotted unit). Uses `getCommsBridgeLivekitToken`
  /// after backend allows `emsAcceptedBy` / crane on operation channel.
  static Future<Room> connectFleetChannel({
    required String channel,
    required String incidentId,
    String? boundHospitalDocId,
    bool canPublishAudio = true,
  }) async {
    final hid = boundHospitalDocId?.trim();
    final callable = FirebaseFunctions.instance.httpsCallable(
      'getCommsBridgeLivekitToken',
    );
    final res = await callable.call({
      'channel': channel,
      'canPublishAudio': canPublishAudio,
      if (incidentId.trim().isNotEmpty) 'incidentId': incidentId.trim(),
      if (hid != null && hid.isNotEmpty) 'boundHospitalId': hid,
    });

    final data = (res.data as Map?) ?? const {};
    final token = (data['token'] ?? '').toString();
    final url = LivekitUrl.normalizeForClient((data['url'] ?? '').toString());
    final roomName = (data['roomName'] ?? '').toString();

    if (token.isEmpty || url.isEmpty || roomName.isEmpty) {
      throw StateError('Comms bridge token response missing fields.');
    }

    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    await room.connect(url, token);
    final local = room.localParticipant;
    if (local == null) {
      throw StateError('LiveKit local participant is null after connect.');
    }
    await local.setMicrophoneEnabled(canPublishAudio);
    return room;
  }
}
