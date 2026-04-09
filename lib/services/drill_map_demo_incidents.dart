import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'incident_service.dart';

/// Demo SOS pins for Grid map during drill shell only (no Firestore).
abstract final class DrillMapDemoIncidents {
  static LatLng _o(LatLng c, double dLat, double dLng) =>
      LatLng(c.latitude + dLat, c.longitude + dLng);

  /// Pulsing “live” style markers (pending / dispatched).
  static List<SosIncident> activeNear(LatLng center, DateTime now) {
    return [
      SosIncident(
        id: 'drill_map_active_1',
        userId: 'drill_demo',
        userDisplayName: 'Practice caller A',
        location: _o(center, 0.007, 0.0035),
        type: 'Cardiac distress (practice)',
        timestamp: now.subtract(const Duration(minutes: 6)),
        goldenHourStart: now.subtract(const Duration(minutes: 6)),
        status: IncidentStatus.dispatched,
        bloodType: 'O+',
        allergies: 'None (demo)',
        medicalConditions: 'Demo only',
        volunteerLat: _o(center, 0.011, -0.002).latitude,
        volunteerLng: _o(center, 0.011, -0.002).longitude,
        volunteerUpdatedAt: now.subtract(const Duration(minutes: 2)),
        acceptedVolunteerIds: const ['drill_volunteer_demo'],
      ),
      SosIncident(
        id: 'drill_map_active_2',
        userId: 'drill_demo',
        userDisplayName: 'Practice caller B',
        location: _o(center, -0.006, 0.005),
        type: 'Road traffic collision (practice)',
        timestamp: now.subtract(const Duration(minutes: 2)),
        goldenHourStart: now.subtract(const Duration(minutes: 2)),
        status: IncidentStatus.pending,
      ),
    ];
  }

  /// “Past / archived” style pins for history layer and Archived SOS chip.
  static List<SosIncident> archivedNear(LatLng center, DateTime now) {
    return [
      SosIncident(
        id: 'drill_map_arch_1',
        userId: 'drill_demo',
        userDisplayName: 'Closed case (demo)',
        location: _o(center, 0.011, -0.004),
        type: 'Resolved — fall injury (practice)',
        timestamp: now.subtract(const Duration(days: 3)),
        goldenHourStart: now.subtract(const Duration(days: 3)),
        status: IncidentStatus.resolved,
      ),
      SosIncident(
        id: 'drill_map_arch_2',
        userId: 'drill_demo',
        userDisplayName: 'Closed case (demo)',
        location: _o(center, -0.009, -0.007),
        type: 'Resolved — fire alarm (practice)',
        timestamp: now.subtract(const Duration(days: 8)),
        goldenHourStart: now.subtract(const Duration(days: 8)),
        status: IncidentStatus.resolved,
      ),
      SosIncident(
        id: 'drill_map_arch_3',
        userId: 'drill_demo',
        userDisplayName: 'Closed case (demo)',
        location: _o(center, 0.004, -0.011),
        type: 'Resolved — breathing difficulty (practice)',
        timestamp: now.subtract(const Duration(days: 21)),
        goldenHourStart: now.subtract(const Duration(days: 21)),
        status: IncidentStatus.resolved,
      ),
    ];
  }
}
