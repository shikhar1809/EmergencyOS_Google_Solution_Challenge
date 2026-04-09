import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/india_ops_zones.dart';
import 'demo_fleet_endpoints.dart';
import 'demo_fleet_route_cache.dart';
import 'demo_fleet_routing.dart';

/// Deterministic “responding” motion for `demo_fleet_*` Firestore docs (no writes).
class DemoFleetPose {
  const DemoFleetPose(this.latLng, this.headingDeg);

  final LatLng latLng;
  final double headingDeg;
}

/// EmergencyOS: DemoFleetSimulation in lib/services/demo_fleet_simulation.dart.
abstract final class DemoFleetSimulation {
  static bool isDemoDoc(String docId) => docId.startsWith('demo_fleet_');

  /// Pull [pos] to just inside [zone] when simulation endpoints sit outside a small (e.g. 10 km) ops disk.
  static LatLng clampToZone(LatLng pos, IndiaOpsZone zone) {
    if (zone.containsLatLng(pos)) return pos;
    final dLat = (pos.latitude - zone.center.latitude) * 111000;
    final cosLat = math.cos(zone.center.latitude * math.pi / 180).abs().clamp(0.2, 1.0);
    final dLng = (pos.longitude - zone.center.longitude) * 111000 * cosLat;
    final dist = math.sqrt(dLat * dLat + dLng * dLng);
    if (dist < 1) return zone.center;
    final scale = (zone.radiusM * 0.95) / dist;
    return LatLng(
      zone.center.latitude + (pos.latitude - zone.center.latitude) * scale,
      zone.center.longitude + (pos.longitude - zone.center.longitude) * scale,
    );
  }

  static DemoFleetPose clampPoseToZone(DemoFleetPose pose, IndiaOpsZone zone) {
    return DemoFleetPose(clampToZone(pose.latLng, zone), pose.headingDeg);
  }

  /// One-way period (seconds) for a full depot→scene→depot loop — intentionally slow for production demos.
  static double _fleetLoopPeriodSec(String docId) {
    final seed = docId.hashCode.abs();
    return 520.0 + (seed % 380).toDouble();
  }

  static double _responderLoopPeriodSec(String incidentId, String role) {
    final seed = '$incidentId|$role'.hashCode.abs();
    return 360.0 + (seed % 240).toDouble();
  }

  /// Staging ↔ demo SOS pin (or legacy depot↔scene when no pins); OSRM loop when cached.
  static DemoFleetPose poseFor(
    String docId,
    DateTime now,
    IndiaOpsZone zone, {
    String? assignedIncidentId,
    LatLng? assignedIncidentScene,
    Map<String, LatLng>? demoIncidentScenes,
  }) {
    final (a, b) = DemoFleetRouting.fleetEndpoints(
      docId,
      zone,
      assignedIncidentId,
      assignedIncidentScene,
      demoIncidentScenes,
    );
    final key = DemoFleetRouting.fleetCacheKey(docId, zone, a, b);
    final loop = DemoFleetRouteCache.loopForKey(key);
    if (loop != null && loop.length >= 2) {
      return _poseOnLoop(loop, now, _fleetLoopPeriodSec(docId));
    }
    return _poseStraightAlongEnds(docId, now, zone, a, b);
  }

  static DemoFleetPose _poseStraightAlongEnds(
    String docId,
    DateTime now,
    IndiaOpsZone zone,
    LatLng a,
    LatLng b,
  ) {
    final periodSec = _fleetLoopPeriodSec(docId);
    final elapsed = now.millisecondsSinceEpoch / 1000.0;
    final t = (elapsed % periodSec) / periodSec;
    final wave = t < 0.5 ? (t * 2) : (2 - t * 2);

    // Simple grid-snapping logic for fallback: move along axis-aligned segments
    // instead of a diagonal straight line to look more "city-bound".
    final double midLat = a.latitude;
    final double midLng = b.longitude;
    
    double lat, lng;
    if (wave < 0.5) {
      // First half of the A->B journey: A to Midpoint
      final st = wave * 2;
      lat = a.latitude + (midLat - a.latitude) * st;
      lng = a.longitude + (midLng - a.longitude) * st;
    } else {
      // Second half: Midpoint to B
      final st = (wave - 0.5) * 2;
      lat = midLat + (b.latitude - midLat) * st;
      lng = midLng + (b.longitude - midLng) * st;
    }

    const step = 0.008;
    final waveN = (wave + step).clamp(0.0, 1.0);
    double latN, lngN;
    if (waveN < 0.5) {
      final st = waveN * 2;
      latN = a.latitude + (midLat - a.latitude) * st;
      lngN = a.longitude + (midLng - a.longitude) * st;
    } else {
      final st = (waveN - 0.5) * 2;
      latN = midLat + (b.latitude - midLat) * st;
      lngN = midLng + (b.longitude - midLng) * st;
    }

    var br = Geolocator.bearingBetween(lat, lng, latN, lngN);
    if (br.isNaN || br.abs() < 0.01) {
      br = Geolocator.bearingBetween(a.latitude, a.longitude, b.latitude, b.longitude);
    }
    if (wave > 0.5 && t > 0.5) {
       // Returning leg logic usually handled by wave > 0.5 in periodSec logic
    }

    var pos = LatLng(lat, lng);
    if (!zone.containsLatLng(pos)) {
      pos = LatLng(
        zone.center.latitude + (pos.latitude - zone.center.latitude) * 0.85,
        zone.center.longitude + (pos.longitude - zone.center.longitude) * 0.85,
      );
    }
    return DemoFleetPose(pos, br);
  }

  static bool isDemoIncident(String incidentId) => incidentId.startsWith('demo_ops_');

  static DemoFleetPose respondingUnitNearScene(
    String incidentId,
    String role,
    LatLng scene,
    DateTime now,
  ) {
    final zone = IndiaOpsZones.lucknow;
    final loop = DemoFleetRouteCache.loopResponder(incidentId, role, scene, zone);
    if (loop != null && loop.length >= 2) {
      return _poseOnLoop(loop, now, _responderLoopPeriodSec(incidentId, role));
    }
    return _poseStraightResponder(incidentId, role, scene, now);
  }

  static DemoFleetPose _poseStraightResponder(
    String incidentId,
    String role,
    LatLng scene,
    DateTime now,
  ) {
    final (far, near) = DemoFleetEndpoints.responderFarNear(incidentId, role, scene);
    final periodSec = _responderLoopPeriodSec(incidentId, role);
    final elapsed = now.millisecondsSinceEpoch / 1000.0;
    final t = (elapsed % periodSec) / periodSec;
    final wave = t < 0.5 ? (t * 2) : (2 - t * 2);

    final lat = far.latitude + (near.latitude - far.latitude) * wave;
    final lng = far.longitude + (near.longitude - far.longitude) * wave;

    const step = 0.012;
    final waveN = math.min(1.0, wave + step);
    final latN = far.latitude + (near.latitude - far.latitude) * waveN;
    final lngN = far.longitude + (near.longitude - far.longitude) * waveN;

    var br = Geolocator.bearingBetween(lat, lng, latN, lngN);
    if (br.isNaN) {
      br = Geolocator.bearingBetween(far.latitude, far.longitude, near.latitude, near.longitude);
    }
    if (wave > 0.5) br = (br + 180) % 360;

    return DemoFleetPose(LatLng(lat, lng), br);
  }

  /// Distance-along-loop from [elapsedSec] modulo [periodSec] (full loop each period).
  static DemoFleetPose _poseOnLoop(List<LatLng> path, DateTime now, double periodSec) {
    if (path.length < 2) {
      return DemoFleetPose(path.first, 0);
    }
    final segLens = <double>[];
    var total = 0.0;
    for (var i = 0; i < path.length - 1; i++) {
      final d = Geolocator.distanceBetween(
        path[i].latitude,
        path[i].longitude,
        path[i + 1].latitude,
        path[i + 1].longitude,
      );
      segLens.add(d);
      total += d;
    }
    if (total < 2) {
      return DemoFleetPose(path.first, 0);
    }
    
    final elapsedSec = now.millisecondsSinceEpoch / 1000.0;
    var distAlong = (elapsedSec % periodSec) / periodSec * total;
    if (distAlong < 0 || !distAlong.isFinite) distAlong = 0;

    double d = distAlong;
    LatLng currentPos = path.last;
    double currentBr = 0;
    bool found = false;

    for (var i = 0; i < segLens.length; i++) {
      final seg = segLens[i];
      if (d <= seg || (i == segLens.length - 1)) {
        final t = seg < 1e-6 ? 0.0 : (d / seg).clamp(0.0, 1.0);
        final a = path[i];
        final b = path[i + 1];
        currentPos = LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
        currentBr = Geolocator.bearingBetween(a.latitude, a.longitude, b.latitude, b.longitude);
        
        // Smooth rotation when nearing corners (within 20 meters)
        final distToCorner = seg - d;
        if (distToCorner < 20.0 && i + 1 < segLens.length) {
          final nextSeg = segLens[i + 1];
          if (nextSeg > 0.5) {
            final nextA = path[i + 1];
            final nextB = path[i + 2];
            final nextBr = Geolocator.bearingBetween(
              nextA.latitude, nextA.longitude, 
              nextB.latitude, nextB.longitude,
            );
            
            // Interpolate smoothly into the corner
            final factor = (20.0 - distToCorner) / 20.0; // 0 (start turning) to 1 (at corner)
            var diff = nextBr - currentBr;
            while (diff < -180) diff += 360;
            while (diff > 180) diff -= 360;
            
            currentBr = currentBr + diff * factor;
          }
        }
        
        found = true;
        break;
      }
      d -= seg;
    }

    if (!found && segLens.isNotEmpty) {
       final a = path[path.length - 2];
       final b = path[path.length - 1];
       currentBr = Geolocator.bearingBetween(a.latitude, a.longitude, b.latitude, b.longitude);
    }
    
    // Normalize bearing
    while (currentBr < 0) currentBr += 360;
    while (currentBr >= 360) currentBr -= 360;

    return DemoFleetPose(currentPos, currentBr);
  }


}

/// Alias for call sites that describe incident-bound motion (same math as [DemoFleetSimulation]).
abstract final class DemoResponderSimulation {
  static bool isDemoIncident(String incidentId) => DemoFleetSimulation.isDemoIncident(incidentId);

  static DemoFleetPose respondingUnitNearScene(
    String incidentId,
    String role,
    LatLng scene,
    DateTime now,
  ) =>
      DemoFleetSimulation.respondingUnitNearScene(incidentId, role, scene, now);
}
