import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_service.dart';

/// Lightweight helper for family / emergency-contact tracking links and alerts.
class FamilyAlertService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the existing family tracking token for this incident, or creates one.
  static Future<String> ensureTrackingToken(SosIncident incident) async {
    if (incident.familyTrackingToken != null &&
        incident.familyTrackingToken!.trim().isNotEmpty) {
      return incident.familyTrackingToken!.trim();
    }
    final token = _generateToken();
    await _db.collection('sos_incidents').doc(incident.id).set(
      <String, dynamic>{'familyTrackingToken': token},
      SetOptions(merge: true),
    );
    return token;
  }

  /// Creates a `family_sessions` doc and (optionally) lets the client send SMS with the link.
  static Future<void> inviteContact({
    required SosIncident incident,
    required String name,
    required String phone,
  }) async {
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty) return;
    final token = await ensureTrackingToken(incident);
    final ref = _db
        .collection('sos_incidents')
        .doc(incident.id)
        .collection('family_sessions')
        .doc();
    await ref.set(<String, dynamic>{
      'name': name.trim().isEmpty ? null : name.trim(),
      'phone': trimmedPhone,
      'incidentId': incident.id,
      'token': token,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastNotifiedAt': null,
    });
  }

  /// Minimal status stream for the public family tracker view.
  static Stream<SosIncident> watchIncident(String incidentId) {
    return _db
        .collection('sos_incidents')
        .doc(incidentId)
        .snapshots()
        .map((snap) => SosIncident.fromFirestore(snap));
  }

  static String _generateToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List<String>.generate(
      8,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }
}

