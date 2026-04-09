import 'package:cloud_firestore/cloud_firestore.dart';

class CoverageArea {
  final String id;
  final List<String> hexKeys;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;

  const CoverageArea({
    required this.id,
    required this.hexKeys,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
  });

  factory CoverageArea.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final hexRaw = d['hexKeys'];
    final hexKeys = hexRaw is List
        ? hexRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const <String>[];
    return CoverageArea(
      id: doc.id,
      hexKeys: hexKeys,
      name: (d['name'] as String?)?.trim() ?? 'Coverage Area',
      isActive: d['isActive'] == true,
      createdAt: _ts(d['createdAt']) ?? DateTime.now(),
      createdBy: (d['createdBy'] as String?)?.trim() ?? 'unknown',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hexKeys': hexKeys,
      'name': name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  CoverageArea copyWith({
    String? id,
    List<String>? hexKeys,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return CoverageArea(
      id: id ?? this.id,
      hexKeys: hexKeys ?? this.hexKeys,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
