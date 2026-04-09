import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Removes legacy demo-prefixed documents from Firestore (no seeding).
abstract final class DemoDataService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> purgeAll() async {
    await Future.wait([
      _purgeCollection('sos_incidents', prefix: 'demo_'),
      _purgeCollection('ops_fleet_units', prefix: 'demo_'),
      _purgeCollection('volunteer_presence', prefix: 'vol_demo_'),
    ]);
    debugPrint('[DemoDataService] purge complete');
  }

  static Future<void> _purgeCollection(String col, {required String prefix}) async {
    try {
      const sentinel = '\uf8ff';
      final snap = await _db
          .collection(col)
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
          .where(FieldPath.documentId, isLessThan: '$prefix$sentinel')
          .get();

      if (snap.docs.isEmpty) return;

      const batchSize = 500;
      for (var i = 0; i < snap.docs.length; i += batchSize) {
        final chunk = snap.docs.sublist(i, (i + batchSize).clamp(0, snap.docs.length));
        final batch = _db.batch();
        for (final d in chunk) {
          batch.delete(d.reference);
        }
        await batch.commit();
        debugPrint('[DemoDataService] deleted ${chunk.length} docs from $col');
      }
    } catch (e) {
      debugPrint('[DemoDataService] purge $col error: $e');
    }
  }
}
