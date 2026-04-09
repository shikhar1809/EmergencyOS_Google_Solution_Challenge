import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens **Google Maps** (app or web) with driving directions to [destLat]/[destLng].
///
/// Uses your **current GPS fix** as `origin` when available so turn-by-turn starts from
/// the operator’s real position. Falls back to [Geolocator.getLastKnownPosition] (often
/// still available with poor mobile data), then a **24h local cache** of the last good
/// fix — helpful when the network is spotty but the device still knows where it was.
///
/// This is the standard **Maps URLs** navigation flow (same as “Navigate” in many apps).
/// Google’s native **Navigation SDK** (in-embed turn-by-turn) is Android/iOS-only and not
/// bundled here; this launches the Google Maps navigation experience externally.
class GoogleMapsNavigation {
  static const _prefLat = 'eos_nav_origin_lat';
  static const _prefLng = 'eos_nav_origin_lng';
  static const _prefMs = 'eos_nav_origin_ms';

  static Future<void> openDrivingDirectionsTo({
    required double destLat,
    required double destLng,
    String? destinationPlaceId,
  }) async {
    final origin = await resolveOriginForDirections();
    final dest = '${destLat.toStringAsFixed(6)},${destLng.toStringAsFixed(6)}';
    final destEnc = Uri.encodeComponent(dest);
    final buf = StringBuffer(
      'https://www.google.com/maps/dir/?api=1&destination=$destEnc&travelmode=driving',
    );
    if (destinationPlaceId != null && destinationPlaceId.trim().isNotEmpty) {
      buf.write('&destination_place_id=${Uri.encodeComponent(destinationPlaceId.trim())}');
    }
    if (origin != null) {
      final o = '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}';
      buf.write('&origin=${Uri.encodeComponent(o)}');
    }
    final uri = Uri.parse(buf.toString());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Best-effort origin for Maps URLs; updates local cache when a fresh fix is obtained.
  static Future<LatLng?> resolveOriginForDirections() async {
    LatLng? fromPos(Position p) => LatLng(p.latitude, p.longitude);

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        return await _lastKnownOrCached();
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 10));
        await _persistCachedOrigin(pos.latitude, pos.longitude);
        return fromPos(pos);
      } on TimeoutException {
        // fall through
      } catch (_) {
        // fall through
      }

      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        await _persistCachedOrigin(last.latitude, last.longitude);
        return fromPos(last);
      }
    } catch (_) {}

    return _readCachedOriginOnly();
  }

  static Future<LatLng?> _lastKnownOrCached() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LatLng(last.latitude, last.longitude);
    } catch (_) {}
    return _readCachedOriginOnly();
  }

  static Future<void> _persistCachedOrigin(double lat, double lng) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_prefLat, lat);
      await p.setDouble(_prefLng, lng);
      await p.setInt(_prefMs, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<LatLng?> _readCachedOriginOnly() async {
    try {
      final p = await SharedPreferences.getInstance();
      final lat = p.getDouble(_prefLat);
      final lng = p.getDouble(_prefLng);
      final ms = p.getInt(_prefMs) ?? 0;
      if (lat == null || lng == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - ms;
      if (age > const Duration(hours: 24).inMilliseconds) return null;
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }
}
