import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalStaffCredentials {
  final String staffId;
  final String tempPassword;
  final String status;
  final DateTime generatedAt;

  const HospitalStaffCredentials({
    required this.staffId,
    required this.tempPassword,
    required this.status,
    required this.generatedAt,
  });

  static String _randomAlphaNumeric(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  static HospitalStaffCredentials generate(String hospitalDocId) {
    final safeHospitalId = hospitalDocId.trim().replaceAll(
      RegExp(r'[^A-Z0-9\-]'),
      '',
    );
    final shortCode = _randomAlphaNumeric(6);
    final staffId = 'STAFF-$safeHospitalId-$shortCode';
    final tempPassword = _randomAlphaNumeric(8);
    return HospitalStaffCredentials(
      staffId: staffId,
      tempPassword: tempPassword,
      status: 'pending',
      generatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'tempPassword': tempPassword,
      'status': status,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }

  factory HospitalStaffCredentials.fromMap(Map<String, dynamic> map) {
    return HospitalStaffCredentials(
      staffId: (map['staffId'] as String?)?.trim() ?? '',
      tempPassword: (map['tempPassword'] as String?)?.trim() ?? '',
      status: (map['status'] as String?)?.trim() ?? 'pending',
      generatedAt: _ts(map['generatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
