import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// OSRM driving routes (same source as volunteer consignment map).
abstract final class OsrmRouteUtil {
  static List<LatLng> fallbackPolyline(LatLng start, LatLng end) => [
        start,
        end,
      ];

  static Future<List<LatLng>> drivingRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?overview=full&geometries=geojson',
    );

    int retries = 3;
    while (retries >= 0) {
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final dynamic data = json.decode(res.body);
          if (data is Map<String, dynamic>) {
            final routes = data['routes'];
            if (routes is List && routes.isNotEmpty) {
              final geometry = routes[0]['geometry'];
              if (geometry is Map<String, dynamic>) {
                final coords = geometry['coordinates'];
                if (coords is List && coords.isNotEmpty) {
                  final out = <LatLng>[];
                  for (final c in coords) {
                    if (c is List && c.length >= 2) {
                      out.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
                    }
                  }
                  if (out.isNotEmpty) return out;
                }
              }
            }
          }
          debugPrint('[OsrmRouteUtil] Unexpected JSON structure for 200 OK');
        } else if (res.statusCode == 429) {
          debugPrint('[OsrmRouteUtil] Rate limited (429). Retries left: $retries');
          await Future<void>.delayed(Duration(milliseconds: 1500 + (3 - retries) * 1000));
        } else {
          debugPrint('[OsrmRouteUtil] HTTP ${res.statusCode} for route request');
        }
      } catch (e) {
        debugPrint('[OsrmRouteUtil] Attempt failed (retries=$retries): $e');
        if (retries == 0) break;
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      }
      retries--;
    }

    return fallbackPolyline(start, end);
  }


  static int? etaMinutesFromRoute(List<LatLng> route) {
    if (route.length < 2) return null;
    double meters = 0.0;
    for (var i = 1; i < route.length; i++) {
      meters += Geolocator.distanceBetween(
        route[i - 1].latitude,
        route[i - 1].longitude,
        route[i].latitude,
        route[i].longitude,
      );
    }
    const double kph = 28.0;
    final minutes = (meters / 1000.0) / kph * 60.0;
    if (!minutes.isFinite) return null;
    return minutes.clamp(1, 180).round();
  }
}
