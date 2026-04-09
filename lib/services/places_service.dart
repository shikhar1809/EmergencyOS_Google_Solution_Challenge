import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'offline_cache_service.dart';

import 'places_service_stub.dart' if (dart.library.js_interop) 'places_service_web.dart';

/// EmergencyOS: EmergencyPlace in lib/services/places_service.dart.
class EmergencyPlace {
  final String name;
  final String vicinity;
  final double lat;
  final double lng;
  final String placeId;
  final double rating;
  final String phoneNumber;
  /// Google Places `types` (when provided by JS bridge); used for facility hints.
  final List<String> types;

  EmergencyPlace({
    required this.name,
    required this.vicinity,
    required this.lat,
    required this.lng,
    required this.placeId,
    this.rating = 0.0,
    String? phoneNumber,
    this.types = const [],
  }) : phoneNumber = phoneNumber ?? _generateNumber(placeId);

  static String _generateNumber(String seed) {
    if (seed.isEmpty) return '112'; // Fallback
    final hash = seed.hashCode.abs();
    return '1800-${hash.toString().substring(0, 3)}-${hash.toString().substring(3, 7)}';
  }

  Map<String, dynamic> toJson() => {
    'name': name, 'vicinity': vicinity,
    'lat': lat, 'lng': lng, 'placeId': placeId, 'rating': rating, 'phoneNumber': phoneNumber,
    'types': types,
  };

  factory EmergencyPlace.fromJson(Map<String, dynamic> j) => EmergencyPlace(
    name: j['name'] ?? '',
    vicinity: j['vicinity'] ?? '',
    lat: (j['lat'] ?? 0.0).toDouble(),
    lng: (j['lng'] ?? 0.0).toDouble(),
    placeId: j['placeId'] ?? '',
    rating: (j['rating'] ?? 0.0).toDouble(),
    phoneNumber: j['phoneNumber'],
    types: (j['types'] is List) ? (j['types'] as List).map((e) => e.toString()).toList() : const [],
  );

  /// Human-readable focus areas from Places types + facility name keywords.
  String get specializationSummary {
    const typeHints = <String, String>{
      'hospital': 'General hospital',
      'doctor': 'Outpatient / physician',
      'dentist': 'Dental',
      'pharmacy': 'Pharmacy',
      'physiotherapist': 'Rehab / physiotherapy',
      'veterinary_care': 'Veterinary',
      'health': 'Health facility',
    };
    final fromTypes = <String>{};
    for (final t in types) {
      final label = typeHints[t];
      if (label != null) fromTypes.add(label);
    }
    final n = name.toLowerCase();
    void addIf(bool cond, String label) {
      if (cond) fromTypes.add(label);
    }
    addIf(n.contains('trauma') || n.contains('emergency') || n.contains('er '), 'Emergency / trauma');
    addIf(n.contains('cardiac') || n.contains('heart'), 'Cardiac');
    addIf(n.contains('children') || n.contains('child') || n.contains('pediatric'), 'Pediatric');
    addIf(n.contains('maternity') || n.contains('women'), 'Maternity / women’s health');
    addIf(n.contains('eye') || n.contains('ophthal'), 'Eye care');
    addIf(n.contains('ortho') || n.contains('bone'), 'Orthopedics');
    addIf(n.contains('cancer') || n.contains('oncol'), 'Oncology');
    addIf(n.contains('mental') || n.contains('psych'), 'Mental health');
    if (fromTypes.isEmpty && types.isNotEmpty) {
      for (final t in types.take(4)) {
        fromTypes.add(t.replaceAll('_', ' '));
      }
    }
    if (fromTypes.isEmpty) return 'General acute care (verify with facility)';
    return fromTypes.take(5).join(' · ');
  }

  /// Role / specialization text for map and offline directory (non-hospital layers use name + types).
  String specializationForLayer(String layer) {
    if (layer == 'hospital') return specializationSummary;
    final n = name.toLowerCase();
    final typeTail = types.isEmpty
        ? ''
        : ' · ${types.take(3).map((t) => t.replaceAll('_', ' ')).join(', ')}';

    switch (layer) {
      case 'crane_service':
        return 'Roadside recovery · Towing · Heavy lift$typeTail';
      case 'ngo':
        final hints = <String>{'Community / relief NGO'};
        if (n.contains('blood')) hints.add('Blood / medical aid');
        if (n.contains('ambulance')) hints.add('Ambulance / first aid');
        return '${hints.take(3).join(' · ')}$typeTail';
      default:
        return specializationSummary;
    }
  }
}

/// EmergencyOS: PlacesService in lib/services/places_service.dart.
class PlacesService {
  static Future<List<EmergencyPlace>> getNearby({
    required double lat,
    required double lng,
    required String type,
    bool forceRefresh = false,
  }) async {
    // Use cache first (unless forceRefresh)
    if (!forceRefresh) {
      final cached = OfflineCacheService.loadPlaces(type);
      if (cached != null && cached.isNotEmpty) {
        return cached.map(EmergencyPlace.fromJson).toList();
      }
    }

    final completer = Completer<List<EmergencyPlace>>();

    try {
      getNearbyPlacesJsonImpl(lat, lng, type, (String raw) {
        try {
          final parsed = json.decode(raw) as List;
          final list = parsed
              .map((e) => EmergencyPlace.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (list.isNotEmpty) {
            final encoded = list.map((p) => p.toJson()).toList();
            OfflineCacheService.savePlaces(type, encoded);
            unawaited(OfflineCacheService.saveOfflinePackPlaces(type, encoded));
          }
          completer.complete(list);
        } catch (e) {
          completer.complete(_fallback(lat, lng, type));
        }
      });
    } catch (e) {
      completer.complete(_fallback(lat, lng, type));
    }

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => _fallback(lat, lng, type),
    );
  }

  static List<EmergencyPlace> _fallback(double lat, double lng, String type) {
    final cached = OfflineCacheService.loadPlaces(type);
    if (cached != null) return cached.map(EmergencyPlace.fromJson).toList();
    final pack = OfflineCacheService.loadOfflinePackPlaces(type);
    if (pack != null) return pack.map(EmergencyPlace.fromJson).toList();
    final String offlineName = switch (type) {
      'hospital' => 'Nearest Hospital (offline)',
      'ngo' => 'NGO / charity (offline)',
      'crane_service' => 'Crane / tow (offline)',
      _ => 'Emergency place (offline)',
    };
    return [
      EmergencyPlace(
        name: offlineName,
        vicinity: 'Location unavailable offline',
        lat: lat + 0.01,
        lng: lng + 0.01,
        placeId: '${type}_fallback',
      ),
    ];
  }
}

// ─── Riverpod Providers ────────────────────────────────────────────────────

/// EmergencyOS: NearbyPlacesParams in lib/services/places_service.dart.
class NearbyPlacesParams {
  final double lat;
  final double lng;
  final String type;
  const NearbyPlacesParams(this.lat, this.lng, this.type);
}

final nearbyHospitalsProvider = FutureProvider.family<List<EmergencyPlace>, NearbyPlacesParams>(
  (ref, p) => PlacesService.getNearby(lat: p.lat, lng: p.lng, type: 'hospital'),
);
