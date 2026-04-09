import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/india_ops_zones.dart';

/// Fixed depot/scene pairs for demo fleet docs (deterministic, same as legacy straight-line sim).
abstract final class DemoFleetEndpoints {
  static (LatLng depot, LatLng scene) depotScene(String docId, IndiaOpsZone zone) {
    final seed = docId.hashCode.abs();
    final a0 = (seed % 360) * math.pi / 180;
    final depotM = 3200 + (seed % 6200).toDouble();
    final sceneM = 650 + (seed % 2400).toDouble();
    final depot = _offsetMeters(zone.center, depotM, a0);
    var scene = _offsetMeters(zone.center, sceneM, a0 + 2.15);
    if (!zone.containsLatLng(scene)) {
      scene = _offsetMeters(zone.center, sceneM * 0.65, a0 + 1.0);
    }
    if (!zone.containsLatLng(depot)) {
      scene = LatLng(
        zone.center.latitude + (scene.latitude - zone.center.latitude) * 0.55,
        zone.center.longitude + (scene.longitude - zone.center.longitude) * 0.55,
      );
    }
    return (depot, scene);
  }

  /// Staging point “outside” the incident along the city-centre → scene ray (start of response leg).
  static LatLng stagingApproach(String docId, LatLng scene, IndiaOpsZone zone) {
    final c = zone.center;
    var br = Geolocator.bearingBetween(c.latitude, c.longitude, scene.latitude, scene.longitude);
    if (br.isNaN) br = 0;
    final distM = 2100.0 + (docId.hashCode.abs() % 1600).toDouble();
    return _offsetMeters(scene, distM, br * math.pi / 180.0);
  }

  /// Far approach point and near-scene point for demo responders (same geometry as legacy sim).
  static (LatLng far, LatLng near) responderFarNear(
    String incidentId,
    String role,
    LatLng scene,
  ) {
    final seed = '$incidentId|$role'.hashCode.abs();
    final roleTurn = switch (role) {
      'pol' => 1.7,
      'fire' => 3.1,
      _ => 0.4,
    };
    final a0 = (seed % 200) * 0.031 + roleTurn;
    final farM = 1100 + (seed % 1900).toDouble();
    final nearM = 95 + (seed % 140).toDouble();
    final far = _offsetMeters(scene, farM, a0);
    final near = _offsetMeters(scene, nearM, a0 + 0.85);
    return (far, near);
  }

  static LatLng _offsetMeters(LatLng c, double distM, double bearingRad) {
    final cosLat = math.cos(c.latitude * math.pi / 180).abs().clamp(0.2, 1.0);
    final dLat = distM * math.cos(bearingRad) / 111320.0;
    final dLng = distM * math.sin(bearingRad) / (111320.0 * cosLat);
    return LatLng(c.latitude + dLat, c.longitude + dLng);
  }
}
