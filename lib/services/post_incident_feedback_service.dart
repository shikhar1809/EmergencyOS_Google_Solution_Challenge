import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

/// Optional anonymous feedback after an incident ends (no victim identity in payload).
class PostIncidentFeedbackService {
  static final _db = FirebaseFirestore.instance;

  static String _anonKey(String incidentId) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final raw = '$uid|$incidentId|feedback_v1';
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 24);
  }

  static Future<void> submit({
    required String incidentId,
    required bool helpful,
    int? rating,
    String? comment,
    String? closureHint,
    String? outcomeCategory,
    String? resolvedByRole,
  }) async {
    final id = incidentId.trim();
    if (id.isEmpty) return;
    final c = comment?.trim() ?? '';
    await _db.collection('incident_feedback').add({
      'incidentId': id,
      'helpful': helpful,
      if (rating != null && rating >= 1 && rating <= 5) 'rating': rating,
      if (c.isNotEmpty) 'comment': c.length > 450 ? c.substring(0, 450) : c,
      if (closureHint != null && closureHint.isNotEmpty) 'closureHint': closureHint,
      if (outcomeCategory != null && outcomeCategory.isNotEmpty) 'outcomeCategory': outcomeCategory,
      if (resolvedByRole != null && resolvedByRole.isNotEmpty) 'resolvedByRole': resolvedByRole,
      'anonKey': _anonKey(id),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
