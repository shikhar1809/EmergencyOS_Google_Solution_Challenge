import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/india_ops_zones.dart';
import '../features/map/domain/emergency_zone_classification.dart';
import 'offline_cache_service.dart';
import 'places_service.dart';
import 'volunteer_presence_service.dart';

/// Offline grid directory (hospitals) + on-duty volunteers, filtered to an [IndiaOpsZone].
abstract final class OpsZoneResourceCatalog {
  static List<EmergencyPlace> _loadLayer(String key) {
    return OfflineCacheService.loadOfflinePackPlaces(key)?.map(EmergencyPlace.fromJson).toList() ?? [];
  }

  static List<EmergencyPlace> hospitalsInZone(IndiaOpsZone z) =>
      _inZone(_loadLayer('hospital'), z);

  /// Live-fetch hospitals for an extended coverage area using multi-point
  /// Places API queries, then merge + de-duplicate by placeId and persist
  /// to the offline pack for subsequent use.
  static Future<List<EmergencyPlace>> fetchAndMergeHospitalsForZone(
    IndiaOpsZone z, {
    List<LatLng> extraAnchors = const [],
  }) async {
    final seen = <String>{};
    final merged = <EmergencyPlace>[];

    void addUnique(List<EmergencyPlace> list) {
      for (final p in list) {
        final key = p.placeId.isNotEmpty ? p.placeId : '${p.lat}_${p.lng}';
        if (seen.add(key)) merged.add(p);
      }
    }

    try {
      final primary = await PlacesService.getNearby(
        lat: z.center.latitude,
        lng: z.center.longitude,
        type: 'hospital',
        forceRefresh: true,
      );
      addUnique(primary);
    } catch (e) {
      debugPrint('[OpsZoneResourceCatalog] primary fetch: $e');
    }

    for (final anchor in extraAnchors) {
      try {
        final extra = await PlacesService.getNearby(
          lat: anchor.latitude,
          lng: anchor.longitude,
          type: 'hospital',
          forceRefresh: true,
        );
        addUnique(extra);
      } catch (e) {
        debugPrint('[OpsZoneResourceCatalog] extra anchor fetch: $e');
      }
    }

    if (merged.isNotEmpty) {
      final encoded = merged.map((p) => p.toJson()).toList();
      await OfflineCacheService.savePlaces('hospital', encoded);
      await OfflineCacheService.saveOfflinePackPlaces('hospital', encoded);
    }

    return _inZone(merged, z);
  }

  static List<EmergencyPlace> _inZone(List<EmergencyPlace> all, IndiaOpsZone z) {
    final c = z.center;
    final maxRadiusM = z.radiusM + kMaxCoverageRadiusM;
    return all.where((p) {
      final m = Geolocator.distanceBetween(c.latitude, c.longitude, p.lat, p.lng);
      return m <= maxRadiusM;
    }).toList()
      ..sort((a, b) {
        final da = Geolocator.distanceBetween(c.latitude, c.longitude, a.lat, a.lng);
        final db = Geolocator.distanceBetween(c.latitude, c.longitude, b.lat, b.lng);
        return da.compareTo(db);
      });
  }

  /// Short unique display ID for a Places-based hospital (used on map markers).
  static String hospitalDisplayId(EmergencyPlace p) {
    if (p.placeId.isEmpty) return 'H-${p.lat.toStringAsFixed(2)}';
    final hash = p.placeId.hashCode.toUnsigned(32).toRadixString(36).toUpperCase();
    return 'H-${hash.substring(0, hash.length.clamp(0, 6))}';
  }

  static String dutyNarrative(ActiveVolunteerNearby v) {
    final age = v.dutyUpdatedAt == null
        ? ''
        : ' · last ping ${DateTime.now().difference(v.dutyUpdatedAt!).inMinutes}m ago';
    return 'On duty · reporting location$age';
  }

  static String facilityNarrative(EmergencyPlace p, String layer) {
    return p.specializationForLayer(layer);
  }

  /// Fresh on-duty users inside zone (same rules as map grid).
  static List<ActiveVolunteerNearby> volunteersInZone(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> dutyDocs,
    IndiaOpsZone z,
  ) {
    return VolunteerPresenceService.filterNearby(
      dutyDocs,
      z.center,
      z.radiusM,
    );
  }
}
