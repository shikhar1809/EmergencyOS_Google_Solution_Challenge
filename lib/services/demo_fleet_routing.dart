import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/india_ops_zones.dart';
import 'demo_fleet_endpoints.dart';

/// Chooses **staging ↔ demo SOS pin** endpoints so fleet units follow purposeful response/return loops.
abstract final class DemoFleetRouting {
  static String fleetCacheKey(String docId, IndiaOpsZone zone, LatLng a, LatLng b) =>
      '${zone.id}|F|$docId|${a.latitude.toStringAsFixed(4)}_${a.longitude.toStringAsFixed(4)}|${b.latitude.toStringAsFixed(4)}_${b.longitude.toStringAsFixed(4)}';

  /// [assignedIncidentScene] is the pin for [assignedIncidentId] when known (Firestore may omit reverse lookup).
  static (LatLng a, LatLng b) fleetEndpoints(
    String docId,
    IndiaOpsZone zone,
    String? assignedIncidentId,
    LatLng? assignedIncidentScene,
    Map<String, LatLng>? demoIncidentScenes,
  ) {
    final aid = assignedIncidentId?.trim();
    LatLng? scene;
    if (aid != null && aid.isNotEmpty) {
      scene = assignedIncidentScene ?? demoIncidentScenes?[aid];
    }
    scene ??= _pickRotatingDemoScene(docId, demoIncidentScenes, zone);
    if (scene != null && zone.containsLatLng(scene)) {
      final staging = DemoFleetEndpoints.stagingApproach(docId, scene, zone);
      return (staging, scene);
    }
    return DemoFleetEndpoints.depotScene(docId, zone);
  }

  static LatLng? _pickRotatingDemoScene(
    String docId,
    Map<String, LatLng>? map,
    IndiaOpsZone zone,
  ) {
    if (map == null || map.isEmpty) return null;
    final keys = map.keys.where((k) => k.startsWith('demo_ops_')).toList()..sort();
    if (keys.isEmpty) return null;
    final p = map[keys[docId.hashCode.abs() % keys.length]];
    if (p != null && zone.containsLatLng(p)) return p;
    return null;
  }
}
