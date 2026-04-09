import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// When non-null, the signed-in user has an active victim SOS (pending/dispatched).
final activeVictimIncidentIdProvider = StreamProvider<String?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance
      .collection('sos_incidents')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snap) {
    for (final d in snap.docs) {
      final st = (d.data()['status'] as String?) ?? '';
      if (st == 'pending' || st == 'dispatched') return d.id;
    }
    return null;
  });
});
