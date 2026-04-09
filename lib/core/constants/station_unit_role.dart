/// Which station/driver experience the mobile **Emergency services** panel uses.
enum StationUnitRole {
  medical,
  crane,
}

StationUnitRole? stationUnitRoleFromStorage(String? raw) {
  final s = raw?.trim().toLowerCase() ?? '';
  for (final r in StationUnitRole.values) {
    if (r.name == s) return r;
  }
  return null;
}

extension StationUnitRoleX on StationUnitRole {
  String get label => switch (this) {
        StationUnitRole.medical => 'Medical / ambulance',
        StationUnitRole.crane => 'Crane / recovery',
      };

  String get shortLabel => switch (this) {
        StationUnitRole.medical => 'Medical',
        StationUnitRole.crane => 'Crane',
      };

  /// [FleetUnitService] / Firestore `vehicleType` string.
  String get fleetVehicleType => name;
}
