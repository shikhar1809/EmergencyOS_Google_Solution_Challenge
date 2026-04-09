import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/demo_gate_password.dart';
import '../features/staff/domain/hospital_staff_credentials.dart';

abstract final class HospitalOnboardingService {
  static final _db = FirebaseFirestore.instance;
  static const _hospitalCol = 'ops_hospitals';

  static Future<HospitalStaffCredentials> onboardHospital({
    required String hospitalDocId,
    required String adminEmail,
    double? latitude,
    double? longitude,
    String? displayName,
    String? region,
  }) async {
    final credentials = HospitalStaffCredentials.generate(hospitalDocId);
    final ref = _db.collection(_hospitalCol).doc(hospitalDocId);

    final data = <String, dynamic>{
      'staffCredentials': credentials.toMap(),
      'onboardedAt': FieldValue.serverTimestamp(),
      'onboardedBy': adminEmail,
      'updatedAt': FieldValue.serverTimestamp(),
      'gatePassword': DemoGatePassword.value,
    };

    if (latitude != null && longitude != null) {
      data['lat'] = latitude;
      data['lng'] = longitude;
    }
    if (displayName != null && displayName.trim().isNotEmpty) {
      data['name'] = displayName.trim();
    }
    if (region != null && region.trim().isNotEmpty && region.trim() != '—') {
      data['region'] = region.trim();
    }

    await ref.set(data, SetOptions(merge: true));

    return credentials;
  }

  static Future<HospitalStaffCredentials?> validateStaffLogin({
    required String staffId,
    required String password,
  }) async {
    try {
      final snap = await _db
          .collection(_hospitalCol)
          .where('staffCredentials.staffId', isEqualTo: staffId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final doc = snap.docs.first;
      final data = doc.data();
      final credsRaw = data['staffCredentials'];
      if (credsRaw is! Map) return null;

      final storedPassword =
          (credsRaw['tempPassword'] as String?)?.trim() ?? '';
      final status = (credsRaw['status'] as String?)?.trim() ?? 'pending';

      if (storedPassword != password) return null;
      if (status == 'revoked') return null;

      return HospitalStaffCredentials.fromMap(
        Map<String, dynamic>.from(credsRaw),
      );
    } catch (e) {
      debugPrint('[HospitalOnboardingService] validateStaffLogin: $e');
      return null;
    }
  }

  static Future<String?> getHospitalDocIdByStaffId(String staffId) async {
    try {
      final snap = await _db
          .collection(_hospitalCol)
          .where('staffCredentials.staffId', isEqualTo: staffId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return snap.docs.first.id;
    } catch (e) {
      debugPrint('[HospitalOnboardingService] getHospitalDocIdByStaffId: $e');
      return null;
    }
  }

  static Future<void> activateStaffCredentials(String hospitalDocId) async {
    await _db.collection(_hospitalCol).doc(hospitalDocId).update({
      'staffCredentials.status': 'active',
    });
  }

  static Future<void> revokeStaffCredentials(String hospitalDocId) async {
    await _db.collection(_hospitalCol).doc(hospitalDocId).update({
      'staffCredentials.status': 'revoked',
    });
  }

  /// Current `staffCredentials` on [ops_hospitals] doc, if any.
  static Future<HospitalStaffCredentials?> readStaffCredentials(
    String hospitalDocId,
  ) async {
    final id = hospitalDocId.trim();
    if (id.isEmpty) return null;
    try {
      final snap = await _db.collection(_hospitalCol).doc(id).get();
      if (!snap.exists) return null;
      final raw = snap.data()?['staffCredentials'];
      if (raw is! Map) return null;
      return HospitalStaffCredentials.fromMap(
        Map<String, dynamic>.from(raw),
      );
    } catch (e) {
      debugPrint('[HospitalOnboardingService] readStaffCredentials: $e');
      return null;
    }
  }

  static Future<void> regenerateCredentials(
    String hospitalDocId,
    String adminEmail,
  ) async {
    final newCreds = HospitalStaffCredentials.generate(hospitalDocId);
    await _db.collection(_hospitalCol).doc(hospitalDocId).update({
      'staffCredentials': newCreds.toMap(),
      'onboardedAt': FieldValue.serverTimestamp(),
      'onboardedBy': adminEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
