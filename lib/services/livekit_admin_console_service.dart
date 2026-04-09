import 'package:cloud_functions/cloud_functions.dart';
import 'package:livekit_client/livekit_client.dart';

import '../features/staff/domain/admin_panel_access.dart';

/// LiveKit room shared by master and hospital admin dashboards.
abstract final class LivekitAdminConsoleService {
  static const roomNameFixed = 'admin_console_bridge';
  static const chatTopic = 'admin_console_chat';

  static String apiRoleForAccess(AdminPanelAccess access) =>
      access.role == AdminConsoleRole.master ? 'admin_console_master' : 'admin_console_hospital';

  static Future<Room> connect({
    required AdminPanelAccess access,
    bool canPublishAudio = true,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('getAdminConsoleLivekitToken');
    final res = await callable.call({
      'role': apiRoleForAccess(access),
      'canPublishAudio': canPublishAudio,
    });

    final data = (res.data as Map?) ?? const {};
    final token = (data['token'] ?? '').toString();
    final url = (data['url'] ?? '').toString();
    final roomName = (data['roomName'] ?? '').toString();

    if (token.isEmpty || url.isEmpty || roomName.isEmpty) {
      throw StateError('Admin console LiveKit token response missing fields.');
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
