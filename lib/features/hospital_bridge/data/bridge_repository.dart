import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/bridge_server_model.dart';
import '../domain/bridge_channel_model.dart';

class BridgeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<BridgeServer>> watchServers() {
    return _db.collection('bridge_servers').snapshots().map((snap) {
      return snap.docs.map((doc) => BridgeServer.fromFirestore(doc)).toList();
    });
  }

  Stream<List<BridgeChannel>> watchChannels(String serverId) {
    return _db
        .collection('bridge_channels')
        .where('serverId', isEqualTo: serverId)
        .orderBy('position')
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => BridgeChannel.fromFirestore(doc))
              .toList();
        });
  }

  Future<String> createChannel({
    required String serverId,
    required String name,
    required String createdBy,
    int position = 0,
  }) async {
    final docRef = await _db.collection('bridge_channels').add({
      'serverId': serverId,
      'name': name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '-'),
      'position': position,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    });
    return docRef.id;
  }

  Future<void> deleteChannel(String channelId) async {
    await _db.collection('bridge_channels').doc(channelId).delete();
  }

  Future<void> renameChannel(String channelId, String newName) async {
    await _db.collection('bridge_channels').doc(channelId).update({
      'name': newName.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9\-]'),
        '-',
      ),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) async {
    return _db.collection('users').doc(uid).get();
  }
}
