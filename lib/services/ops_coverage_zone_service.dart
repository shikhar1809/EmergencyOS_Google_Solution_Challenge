import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Geo marks drawn from the master command grid (hospital / trauma hub / ambulance standby).
abstract final class OpsCoverageZoneService {
  static final _db = FirebaseFirestore.instance;
  static const collection = 'ops_coverage_zones';

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchForZone(String zoneId) {
    return _db
        .collection(collection)
        .where('zoneId', isEqualTo: zoneId)
        .snapshots();
  }

  static Future<void> saveQuad({
    required String zoneId,
    required String hexKey,
    required List<LatLng> corners,
    required String kind,
  }) async {
    if (corners.length != 4) {
      throw ArgumentError('Expected exactly 4 corners');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final doc = _db.collection(collection).doc();
    await doc.set({
      'zoneId': zoneId,
      'hexKey': hexKey,
      'kind': kind,
      'corners': corners
          .map((e) => {'lat': e.latitude, 'lng': e.longitude})
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUid': uid,
    });
  }
}
