import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists road polylines for the nearest EMS routes so the map stays useful offline.
/// Also persists the user's last known location for offline map centre restoration.
class OfflineMapPackService {
  static const _routesKey = 'offline_map_pack_routes_v3';
  static const _readyKey = 'offline_map_pack_ready_v3';
  static const _lastLocationKey = 'offline_map_last_location_v1';

  static List<LatLng> _decodePoints(Map<String, dynamic>? m) {
    if (m == null) return [];
    final raw = m['p'];
    if (raw is! List) return [];
    final out = <LatLng>[];
    for (final e in raw) {
      if (e is Map) {
        final lat = (e['lat'] as num?)?.toDouble();
        final lng = (e['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) out.add(LatLng(lat, lng));
      }
    }
    return out;
  }

  static Map<String, dynamic> _encode(List<LatLng> pts) => {
        'p': pts.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
      };

  static Future<void> saveRoutePolylines({
    required List<LatLng> hospital,
    required List<LatLng> crane,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _routesKey,
      json.encode({
        'h': _encode(hospital),
        'c': _encode(crane),
      }),
    );
    await prefs.setBool(_readyKey, true);
  }

  static Future<({List<LatLng> hospital, List<LatLng> crane})> loadRoutePolylines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_routesKey);
    if (raw == null) {
      return (hospital: <LatLng>[], crane: <LatLng>[]);
    }
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      return (
        hospital: _decodePoints(m['h'] as Map<String, dynamic>?),
        crane: _decodePoints(m['c'] as Map<String, dynamic>?),
      );
    } catch (_) {
      return (hospital: <LatLng>[], crane: <LatLng>[]);
    }
  }

  static Future<bool> isReady() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_readyKey) ?? false;
  }

  /// Saves the user's last known location for offline map restoration.
  static Future<void> saveLastLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLocationKey, json.encode({'lat': lat, 'lng': lng}));
  }

  /// Loads the user's last known location, returns null if not saved.
  static Future<LatLng?> loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastLocationKey);
    if (raw == null) return null;
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      final lat = (m['lat'] as num?)?.toDouble();
      final lng = (m['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }
}
