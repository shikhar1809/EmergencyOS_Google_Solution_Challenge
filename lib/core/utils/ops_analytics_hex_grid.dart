import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pointy-top hex grid in local meters (flat earth near [origin]) for analytics heatmaps.
abstract final class OpsAnalyticsHexGrid {
  static const double _sqrt3 = 1.7320508075688772;

  /// Center-to-vertex distance in meters (outer radius).
  ///
  /// Kept similar to the ops command mesh (~2.4 km) so heatmap cells are readable.
  /// A very large size (old behaviour) made a single bin cover most of the map.
  static double hexSizeMetersForZone(double zoneRadiusM) {
    final s = zoneRadiusM / 28.0;
    return s.clamp(2000.0, 4000.0);
  }

  static LatLng _offsetMeters(LatLng origin, double eastM, double northM) {
    final lat = origin.latitude + northM / 111320.0;
    final cosLat = math.max(0.25, math.cos(origin.latitude * math.pi / 180.0).abs());
    final lng = origin.longitude + eastM / (111320.0 * cosLat);
    return LatLng(lat, lng);
  }

  /// Axial hex (q,r) for world point in meters east/north of [origin].
  static ({int q, int r}) hexKeyFromMeters(double eastM, double northM, double size) {
    final fq = (_sqrt3 / 3.0 * eastM - northM / 3.0) / size;
    final fr = (2.0 / 3.0 * northM) / size;
    return _cubeRound(fq, fr, -fq - fr);
  }

  static ({int q, int r}) hexKeyForLatLng(LatLng p, LatLng origin, double size) {
    final east = _eastMeters(origin, p);
    final north = _northMeters(origin, p);
    return hexKeyFromMeters(east, north, size);
  }

  static double _eastMeters(LatLng origin, LatLng p) {
    final cosLat = math.max(0.25, math.cos(origin.latitude * math.pi / 180.0).abs());
    return (p.longitude - origin.longitude) * 111320.0 * cosLat;
  }

  static double _northMeters(LatLng origin, LatLng p) {
    return (p.latitude - origin.latitude) * 111320.0;
  }

  static LatLng centerForHex(int q, int r, LatLng origin, double size) {
    final x = size * _sqrt3 * (q + r / 2.0);
    final y = size * 1.5 * r;
    return _offsetMeters(origin, x, y);
  }

  static List<LatLng> hexRing(int q, int r, LatLng origin, double size) {
    final c = centerForHex(q, r, origin, size);
    final ce = _eastMeters(origin, c);
    final cn = _northMeters(origin, c);
    final out = <LatLng>[];
    for (var i = 0; i < 6; i++) {
      final ang = math.pi / 180.0 * (60.0 * i - 30.0);
      final ex = ce + size * math.cos(ang);
      final ny = cn + size * math.sin(ang);
      out.add(_offsetMeters(origin, ex, ny));
    }
    return out;
  }

  static ({int q, int r}) _cubeRound(double fq, double fr, double fs) {
    var q = fq.round();
    var r = fr.round();
    var s = fs.round();
    final qd = (q - fq).abs();
    final rd = (r - fr).abs();
    final sd = (s - fs).abs();
    if (qd > rd && qd > sd) {
      q = -r - s;
    } else if (rd > sd) {
      r = -q - s;
    } else {
      s = -q - r;
    }
    return (q: q, r: r);
  }

  /// Count incidents per hex cell; only keys with count > 0 returned.
  static Map<String, int> binIncidents(
    Iterable<LatLng> pins,
    LatLng origin,
    double size,
  ) {
    final map = <String, int>{};
    for (final p in pins) {
      final h = hexKeyForLatLng(p, origin, size);
      final k = '${h.q},${h.r}';
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }

  static ({int q, int r}) parseKey(String k) {
    final parts = k.split(',');
    final q = int.tryParse(parts[0]) ?? 0;
    final r = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return (q: q, r: r);
  }
}
