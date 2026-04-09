import 'package:cloud_firestore/cloud_firestore.dart';

class BridgeChannel {
  const BridgeChannel({
    required this.id,
    required this.serverId,
    required this.name,
    this.position = 0,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String serverId;
  final String name;
  final int position;
  final DateTime createdAt;
  final String createdBy;

  String get roomName => 'bridge_${serverId}_$id';

  factory BridgeChannel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return BridgeChannel(
      id: doc.id,
      serverId: (data['serverId'] as String?)?.trim() ?? '',
      name: (data['name'] as String?)?.trim() ?? 'channel',
      position: (data['position'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: (data['createdBy'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'serverId': serverId,
    'name': name,
    'position': position,
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
  };
}
