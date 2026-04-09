import 'package:cloud_firestore/cloud_firestore.dart';

enum BridgeServerType { hospital, master }

class BridgeServer {
  const BridgeServer({
    required this.id,
    required this.name,
    required this.type,
    this.hospitalId,
    this.icon,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String name;
  final BridgeServerType type;
  final String? hospitalId;
  final String? icon;
  final DateTime createdAt;
  final String createdBy;

  String get iconLabel {
    if (icon != null && icon!.isNotEmpty) return icon!;
    return type == BridgeServerType.master ? '⚡' : '🏥';
  }

  factory BridgeServer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return BridgeServer(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Server',
      type: (data['type'] as String?) == 'master'
          ? BridgeServerType.master
          : BridgeServerType.hospital,
      hospitalId: (data['hospitalId'] as String?)?.trim(),
      icon: (data['icon'] as String?)?.trim(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: (data['createdBy'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type == BridgeServerType.master ? 'master' : 'hospital',
    if (hospitalId != null) 'hospitalId': hospitalId,
    if (icon != null) 'icon': icon,
    'createdAt': Timestamp.fromDate(createdAt),
    'createdBy': createdBy,
  };
}
