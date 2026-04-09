import 'package:cloud_functions/cloud_functions.dart';
import 'package:livekit_client/livekit_client.dart';

/// LiveKit room `operations_bridge_{incidentId}` — hospital dispatch ↔ assigned fleet unit.
///
/// Token: callable `getOperationsLivekitToken` (roles `operations_hospital` | `operations_fleet`).
enum OperationsLiveKitSide {
  hospital,
  fleet,
}

extension OperationsLiveKitSideApi on OperationsLiveKitSide {
  String get apiRole => switch (this) {
        OperationsLiveKitSide.hospital => 'operations_hospital',
        OperationsLiveKitSide.fleet => 'operations_fleet',
      };
}

/// EmergencyOS: LivekitOperationsService in lib/services/livekit_operations_service.dart.
abstract final class LivekitOperationsService {
  static String roomNameForIncident(String incidentId) =>
      'operations_bridge_${incidentId.trim()}';

  static Future<Room> connect({
    required String incidentId,
    required OperationsLiveKitSide side,
    bool canPublishAudio = true,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('getOperationsLivekitToken');
    final res = await callable.call({
      'incidentId': incidentId.trim(),
      'role': side.apiRole,
      'canPublishAudio': canPublishAudio,
    });

    final data = (res.data as Map?) ?? const {};
    final token = (data['token'] ?? '').toString();
    final url = (data['url'] ?? '').toString();
    final roomName = (data['roomName'] ?? '').toString();

    if (token.isEmpty || url.isEmpty || roomName.isEmpty) {
      throw StateError('Operations LiveKit token response missing fields.');
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

    await local.setMicrophoneEnabled(canPublishAudio);

    return room;
  }
}
