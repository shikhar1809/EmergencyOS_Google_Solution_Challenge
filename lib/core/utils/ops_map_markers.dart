import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';
import 'map_marker_generator.dart';

/// Same **minimal** circle markers as the main map grid (`MapScreen._loadCustomMarkers`).
abstract final class OpsMapMarkers {
  static BitmapDescriptor? _scene;
  static BitmapDescriptor? _ambulance;
  static BitmapDescriptor? _hospital;
  static BitmapDescriptor? _volunteerDuty;
  static BitmapDescriptor? _volunteerMale;
  static BitmapDescriptor? _volunteerFemale;
  static BitmapDescriptor? _incidentDefault;
  /// Distinct from default Google red teardrop — amber “beacon” for pending live SOS.
  static BitmapDescriptor? _liveSosPending;

  static bool _ready = false;
  static bool get ready => _ready;

  static Future<void> preload() async {
    if (_scene != null) return;

    const subtleHospital = Color(0xFF26C6DA);

    _scene ??= await MapMarkerGenerator.getMinimalPin(
      Icons.warning_rounded,
      AppColors.primaryDanger,
    );
    _ambulance ??= await MapMarkerGenerator.getMinimalPin(
      Icons.medical_services_rounded,
      AppColors.primaryDanger,
    );
    _hospital ??= await MapMarkerGenerator.getMinimalPin(
      Icons.local_hospital_rounded,
      subtleHospital,
    );
    _volunteerDuty ??= await MapMarkerGenerator.getMinimalPin(
      Icons.groups_rounded,
      AppColors.primarySafe,
    );
    _volunteerMale ??= await MapMarkerGenerator.getMinimalPin(
      Icons.man_rounded,
      AppColors.primarySafe,
    );
    _volunteerFemale ??= await MapMarkerGenerator.getMinimalPin(
      Icons.woman_rounded,
      const Color(0xFFE91E63),
    );
    _incidentDefault ??= await MapMarkerGenerator.getMinimalPin(
      Icons.emergency_rounded,
      AppColors.primaryDanger,
    );
    _liveSosPending ??= await MapMarkerGenerator.getMinimalPin(
      Icons.crisis_alert_rounded,
      const Color(0xFFFF9100),
    );
    _ready = true;
  }

  static BitmapDescriptor sceneOr(BitmapDescriptor fallback) => _scene ?? fallback;

  static BitmapDescriptor ambulanceOr(BitmapDescriptor fallback) =>
      _ambulance ?? fallback;

  static BitmapDescriptor hospitalOr(BitmapDescriptor fallback) => _hospital ?? fallback;

  static BitmapDescriptor volunteerDutyOr(BitmapDescriptor fallback) => _volunteerDuty ?? fallback;

  static BitmapDescriptor volunteerForGender(String g, BitmapDescriptor fallback) {
    final lower = g.toLowerCase();
    if (lower == 'female' || lower == 'f') return _volunteerFemale ?? fallback;
    if (lower == 'male' || lower == 'm') return _volunteerMale ?? fallback;
    return _volunteerDuty ?? fallback;
  }

  static BitmapDescriptor incidentOr(BitmapDescriptor fallback) =>
      _incidentDefault ?? fallback;

  /// Pending live SOS — minimal pin, not the default red marker.
  static BitmapDescriptor liveSosPendingOr(BitmapDescriptor fallback) =>
      _liveSosPending ?? fallback;
}
