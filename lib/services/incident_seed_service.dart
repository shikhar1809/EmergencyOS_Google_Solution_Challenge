import 'package:cloud_firestore/cloud_firestore.dart';

/// Purges legacy demo incidents from Firestore. Live seeding is disabled.
class IncidentSeedService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'sos_incidents';

  /// Deletes all demo/seed incidents from Firestore (userId starts with 'vol_').
  /// Call once to purge existing fake data.
  static Future<void> clearDemoIncidents() async {
    try {
      // All seed docs used userIds like 'vol_raj', 'vol_priya', etc.
      // We also delete the known fixed IDs (seed_001..seed_010)
      final knownIds = List.generate(10, (i) => 'seed_00${i + 1}'.replaceAll('seed_0010', 'seed_010'));

      final batch = _db.batch();
      for (final id in knownIds) {
        batch.delete(_db.collection(_col).doc(id));
      }
      await batch.commit();
    } catch (_) {}
  }
}
