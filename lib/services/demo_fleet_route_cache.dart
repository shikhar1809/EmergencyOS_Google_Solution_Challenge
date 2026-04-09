import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/india_ops_zones.dart';
import '../core/utils/osrm_route_util.dart';
import 'demo_fleet_endpoints.dart';

/// OSRM driving loops for demo fleet / demo responder markers (session cache, best-effort).
abstract final class DemoFleetRouteCache {
  static final Map<String, List<LatLng>> _loops = {};
  static final Set<String> _inFlight = {};
  static final List<Future<void> Function()> _queue = [];
  static int _activeCount = 0;
  static bool _processingQueue = false;
  static const int _maxConcurrent = 2; // OSRM public API limit

  static List<LatLng>? loopForKey(String key) => _loops[key];

  /// Returns true if the route is a raw fallback straight-line (OSRM unavailable),
  /// i.e. only 2 points with no intermediate road-snapped geometry.
  static bool isFallbackLine(List<LatLng> route) => route.length <= 2;

  /// Removes any cached routes that are still just straight-line fallbacks,
  /// so they will be re-fetched on the next prefetch cycle.
  static void evictFallbacks() {
    _loops.removeWhere((_, v) => v.length <= 2);
  }

  static List<LatLng>? loopResponder(
    String incidentId,
    String role,
    LatLng scene,
    IndiaOpsZone zone,
  ) {
    final k = _responderKey(incidentId, role, scene, zone);
    return _loops[k];
  }

  static String _responderKey(
    String incidentId,
    String role,
    LatLng scene,
    IndiaOpsZone zone,
  ) {
    return 'resp_${incidentId}_${role}_${zone.id}_${scene.latitude.toStringAsFixed(5)}_${scene.longitude.toStringAsFixed(5)}';
  }

  static void _enqueueTask(Future<void> Function() task) {
    _queue.add(task);
    _processQueue();
  }

  static Future<void> _processQueue() async {
    if (_processingQueue || _activeCount >= _maxConcurrent || _queue.isEmpty) return;
    
    _processingQueue = true;
    while (_queue.isNotEmpty && _activeCount < _maxConcurrent) {
      final task = _queue.removeAt(0);
      _activeCount++;
      
      // Fire and forget the task to allow the next one to start if possible.
      // We don't await the task here to maintain concurrency.
      _runTask(task);
      
      // Small staggered delay even for parallel tasks to avoid hitting rate limits simultaneously.
      if (_queue.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
    _processingQueue = false;
  }

  static Future<void> _runTask(Future<void> Function() task) async {
    try {
      await task();
    } finally {
      _activeCount--;
      // After a task completes, wait a mandatory cooling period before starting another in this 'slot'.
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      _processQueue();
    }
  }

  /// Prefetch a fleet loop for a **specific** A↔B pair (staging↔scene or legacy depot↔scene).
  static void prefetchFleetLoop(String cacheKey, LatLng a, LatLng b) {
    if (_loops.containsKey(cacheKey) || _inFlight.contains(cacheKey)) return;
    _inFlight.add(cacheKey);
    _enqueueTask(() async {
      try {
        final loop = await _buildRoundTripLoop(a, b);
        // Only cache real OSRM routes (>2 points). Skip fallback straight lines
        // so they are retried on the next prefetch cycle.
        if (loop.length > 2) {
          _loops[cacheKey] = loop;
        } else {
          debugPrint('[DemoFleetRouteCache] Skipping fallback line for $cacheKey (only ${loop.length} pts)');
        }
      } catch (e, st) {
        debugPrint('[DemoFleetRouteCache] fleet loop $cacheKey: $e\n$st');
      } finally {
        _inFlight.remove(cacheKey);
      }
    });
  }

  static void prefetchResponderRoute(
    String incidentId,
    String role,
    LatLng scene,
    IndiaOpsZone zone,
  ) {
    final k = _responderKey(incidentId, role, scene, zone);
    if (_loops.containsKey(k) || _inFlight.contains(k)) return;
    _inFlight.add(k);
    _enqueueTask(() async {
      try {
        final (far, near) = DemoFleetEndpoints.responderFarNear(incidentId, role, scene);
        final loop = await _buildRoundTripLoop(far, near);
        if (loop.length > 2) {
          _loops[k] = loop;
        } else {
          debugPrint('[DemoFleetRouteCache] Skipping fallback responder line for $incidentId/$role (only ${loop.length} pts)');
        }
      } catch (e, st) {
        debugPrint('[DemoFleetRouteCache] responder $incidentId $role: $e\n$st');
      } finally {
        _inFlight.remove(k);
      }
    });
  }

  static Future<List<LatLng>> _buildRoundTripLoop(LatLng a, LatLng b) async {
    final forward = await OsrmRouteUtil.drivingRoute(a, b);
    if (forward.length <= 2) {
      debugPrint('[DemoFleetRouteCache] Forward leg is a fallback line — OSRM may be rate-limited. Will retry later.');
      // Return the fallback line so caller can detect it via isFallbackLine()
      return forward;
    }
    
    // Add a small delay between the two OSRM queries to be safe
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final back = await OsrmRouteUtil.drivingRoute(b, a);
    if (back.length <= 2) {
      debugPrint('[DemoFleetRouteCache] Return leg is a fallback line — using one-way route as loop.');
      return forward;
    }
    
    return _mergePaths(forward, back);
  }

  static List<LatLng> _mergePaths(List<LatLng> out, List<LatLng> backIn) {
    if (out.length <= 2) return backIn.length > 2 ? _thin(backIn) : out;
    if (backIn.length <= 2) return _thin(out);
    final merged = List<LatLng>.from(out);
    final lastOut = out.last;
    final firstBack = backIn.first;
    final gap = Geolocator.distanceBetween(
      lastOut.latitude,
      lastOut.longitude,
      firstBack.latitude,
      firstBack.longitude,
    );
    if (gap < 85) {
      merged.addAll(backIn.skip(1));
    } else {
      merged.addAll(backIn);
    }
    return _thin(merged);
  }

  /// Keeps routes light for animation while preserving corners.
  static List<LatLng> _thin(List<LatLng> path) {
    if (path.length <= 5000) return path;
    final step = (path.length / 5000).ceil();
    final out = <LatLng>[];
    for (var i = 0; i < path.length; i += step) {
      out.add(path[i]);
    }
    if (out.last != path.last) out.add(path.last);
    return out;
  }
}
