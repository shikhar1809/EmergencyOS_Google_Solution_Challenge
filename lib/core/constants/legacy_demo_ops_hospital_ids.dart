/// Firestore document IDs from the removed in-app Lucknow demo hospital catalog.
/// Used only to delete stale rows from production projects that were seeded earlier.
abstract final class LegacyBundledOpsHospitalIds {
  LegacyBundledOpsHospitalIds._();

  static const List<String> docIds = [
    'H-LKO-1',
    'H-LKO-2',
    'H-LKO-3',
    'H-LKO-4',
    'H-LKO-5',
    'H-LKO-6',
    'H-LKO-7',
    'H-LKO-8',
    'H-LKO-9',
    'H-LKO-10',
    'H-LKO-11',
    'H-LKO-12',
    'H-LKO-13',
    'H-LKO-14',
    'H-LKO-15',
  ];

  /// Demo fleet gate docs created as two ambulances per catalog hospital.
  static Iterable<String> legacyEmsFleetGateDocIds() sync* {
    for (final id in docIds) {
      yield 'EMS-$id-A';
      yield 'EMS-$id-S';
    }
  }
}
