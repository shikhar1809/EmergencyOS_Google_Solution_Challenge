import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// EmergencyOS: HazardType in lib/features/hazards/domain/hazard_model.dart.
enum HazardType {
  cardiacArrest(Icons.monitor_heart_rounded, Colors.red, 'Cardiac Arrest'),
  accident(Icons.car_crash_rounded, Colors.orange, 'Accident / Crash'),
  fire(Icons.local_fire_department_rounded, Colors.deepOrange, 'Fire / Burn'),
  choking(Icons.personal_injury_rounded, Colors.purpleAccent, 'Choking'),
  bleeding(Icons.bloodtype_rounded, Colors.redAccent, 'Severe Bleeding');

  final IconData icon;
  final Color color;
  final String label;
  const HazardType(this.icon, this.color, this.label);
}

/// EmergencyOS: HazardModel in lib/features/hazards/domain/hazard_model.dart.
class HazardModel {
  final String id;
  final HazardType type;
  final LatLng location;
  final DateTime reportedAt;
  final String reportedBy;

  HazardModel({
    required this.id,
    required this.type,
    required this.location,
    required this.reportedAt,
    required this.reportedBy,
  });
}
