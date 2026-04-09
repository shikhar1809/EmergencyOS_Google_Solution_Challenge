import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/bridge_repository.dart';
import '../data/hospital_bridge_service.dart';
import '../domain/bridge_server_model.dart';
import '../domain/bridge_channel_model.dart';

final bridgeRepositoryProvider = Provider<BridgeRepository>((ref) {
  return BridgeRepository();
});

final bridgeServersProvider = StreamProvider<List<BridgeServer>>((ref) {
  return ref.watch(bridgeRepositoryProvider).watchServers();
});

final bridgeChannelsProvider =
    StreamProvider.family<List<BridgeChannel>, String>((ref, serverId) {
      return ref.watch(bridgeRepositoryProvider).watchChannels(serverId);
    });

final selectedServerProvider = StateProvider<BridgeServer?>((ref) => null);

final selectedChannelProvider = StateProvider<BridgeChannel?>((ref) => null);

final bridgeServiceProvider = ChangeNotifierProvider<HospitalBridgeService>((
  ref,
) {
  final svc = HospitalBridgeService();
  ref.onDispose(svc.dispose);
  return svc;
});

final bridgeVoiceStatesProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(bridgeServiceProvider).getVoiceStates();
});

final bridgeChatMessagesProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(bridgeServiceProvider).messages;
});

final bridgeMicOnProvider = Provider<bool>((ref) {
  return ref.watch(bridgeServiceProvider).micOn;
});

final bridgeDeafenedProvider = Provider<bool>((ref) {
  return ref.watch(bridgeServiceProvider).deafened;
});

final bridgeIsConnectedProvider = Provider<bool>((ref) {
  return ref.watch(bridgeServiceProvider).isConnected;
});

final bridgeUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

final bridgeDisplayNameProvider = Provider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user?.displayName != null && user!.displayName!.isNotEmpty) {
    return user.displayName!;
  }
  if (user?.email != null && user!.email!.isNotEmpty) {
    return user.email!.split('@').first;
  }
  return 'Admin';
});
