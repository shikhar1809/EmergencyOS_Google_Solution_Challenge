import 'package:cloud_firestore/cloud_firestore.dart';

int fleetDocUpdatedAtMs(QueryDocumentSnapshot<Map<String, dynamic>> d) {
  final v = d.data()['updatedAt'];
  if (v is Timestamp) return v.millisecondsSinceEpoch;
  return 0;
}

/// One Firestore row per call sign (latest [updatedAt] wins). Avoids duplicate cards
/// when multiple docs share the same [fleetCallSign].
List<QueryDocumentSnapshot<Map<String, dynamic>>> dedupeFleetDocsByCallSign(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final byCallSign = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
  for (final d in docs) {
    final cs =
        ((d.data()['fleetCallSign'] as String?)?.trim() ?? d.id).toUpperCase();
    final prev = byCallSign[cs];
    if (prev == null || fleetDocUpdatedAtMs(d) >= fleetDocUpdatedAtMs(prev)) {
      byCallSign[cs] = d;
    }
  }
  final out = byCallSign.values.toList();
  out.sort((a, b) => fleetDocUpdatedAtMs(b).compareTo(fleetDocUpdatedAtMs(a)));
  return out;
}
