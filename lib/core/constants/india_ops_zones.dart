import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// India-wide outer bound — ops maps stay within the subcontinent.
abstract final class IndiaGeo {
  static final LatLngBounds mainlandBounds = LatLngBounds(
    southwest: const LatLng(6.2, 67.8),
    northeast: const LatLng(37.2, 97.5),
  );

  /// Clamp [zone] so the camera cannot leave India.
  static LatLngBounds clampToIndia(LatLngBounds zone) {
    final sw = zone.southwest;
    final ne = zone.northeast;
    final osw = mainlandBounds.southwest;
    final one = mainlandBounds.northeast;
    return LatLngBounds(
      southwest: LatLng(
        math.max(sw.latitude, osw.latitude),
        math.max(sw.longitude, osw.longitude),
      ),
      northeast: LatLng(
        math.min(ne.latitude, one.latitude),
        math.min(ne.longitude, one.longitude),
      ),
    );
  }
}

/// Preset command / analytics zones (India). Map is **locked** to [cameraBounds].
class IndiaOpsZone {
  const IndiaOpsZone({
    required this.id,
    required this.label,
    required this.center,
    required this.radiusKm,
    required this.defaultZoom,
  });

  final String id;
  final String label;
  final LatLng center;
  /// Incident / resource inclusion radius from [center].
  final double radiusKm;
  final double defaultZoom;

  double get radiusM => radiusKm * 1000.0;

  /// Tight bounds for [cameraTargetBounds] (approximate flat earth).
  LatLngBounds get cameraBounds {
    final dLat = radiusKm / 111.0;
    final cosLat = math.cos(center.latitude * math.pi / 180).abs().clamp(0.2, 1.0);
    final dLng = radiusKm / (111.0 * cosLat);
    final raw = LatLngBounds(
      southwest: LatLng(center.latitude - dLat, center.longitude - dLng),
      northeast: LatLng(center.latitude + dLat, center.longitude + dLng),
    );
    return IndiaGeo.clampToIndia(raw);
  }

  bool containsLatLng(LatLng p) {
    final dLat = (p.latitude - center.latitude) * 111000;
    final dLng = (p.longitude - center.longitude) * 111000 * math.cos(center.latitude * math.pi / 180).abs().clamp(0.2, 1.0);
    return math.sqrt(dLat * dLat + dLng * dLng) <= radiusM;
  }
}

abstract final class IndiaOpsZones {
  /// Command center is fixed to this zone (Lucknow) for the current product phase.
  static const String lucknowZoneId = 'lucknow';

  /// Primary ops / public map lock (Lucknow & surrounds).
  static IndiaOpsZone get lucknow => byId(lucknowZoneId);

  /// Use with [GoogleMap.cameraTargetBounds] to prevent panning outside Lucknow ops area.
  static CameraTargetBounds get lucknowCameraTargetBounds => CameraTargetBounds(lucknow.cameraBounds);

  static CameraPosition lucknowCameraPosition({double? zoom}) =>
      CameraPosition(target: lucknow.center, zoom: zoom ?? lucknow.defaultZoom);

  /// Centers on [preferred] only if inside the Lucknow zone; otherwise Lucknow center.
  static CameraPosition lucknowSafeCamera(LatLng? preferred, {double preferZoom = 11.5}) {
    final z = lucknow;
    if (preferred != null && z.containsLatLng(preferred)) {
      return CameraPosition(target: preferred, zoom: preferZoom);
    }
    return CameraPosition(target: z.center, zoom: z.defaultZoom);
  }

  static const List<IndiaOpsZone> all = [
    IndiaOpsZone(
      id: 'lucknow',
      label: 'Lucknow & UP heartland',
      center: LatLng(26.8467, 80.9462),
      radiusKm: 120,
      defaultZoom: 11.0,
    ),
    IndiaOpsZone(
      id: 'delhi_ncr',
      label: 'Delhi NCR',
      center: LatLng(28.6139, 77.2090),
      radiusKm: 85,
      defaultZoom: 9.0,
    ),
    IndiaOpsZone(
      id: 'mumbai',
      label: 'Mumbai MMR',
      center: LatLng(19.0760, 72.8777),
      radiusKm: 75,
      defaultZoom: 9.2,
    ),
    IndiaOpsZone(
      id: 'bengaluru',
      label: 'Bengaluru',
      center: LatLng(12.9716, 77.5946),
      radiusKm: 65,
      defaultZoom: 9.5,
    ),
    IndiaOpsZone(
      id: 'hyderabad',
      label: 'Hyderabad',
      center: LatLng(17.3850, 78.4867),
      radiusKm: 70,
      defaultZoom: 9.2,
    ),
    IndiaOpsZone(
      id: 'chennai',
      label: 'Chennai',
      center: LatLng(13.0827, 80.2707),
      radiusKm: 70,
      defaultZoom: 9.2,
    ),
    IndiaOpsZone(
      id: 'kolkata',
      label: 'Kolkata',
      center: LatLng(22.5726, 88.3639),
      radiusKm: 75,
      defaultZoom: 9.0,
    ),
    IndiaOpsZone(
      id: 'north_india_wide',
      label: 'North India (wide)',
      center: LatLng(28.6, 77.5),
      radiusKm: 650,
      defaultZoom: 5.4,
    ),
  ];

  static IndiaOpsZone byId(String? id) {
    final x = id?.trim() ?? '';
    for (final z in all) {
      if (z.id == x) return z;
    }
    return all.first;
  }
}
