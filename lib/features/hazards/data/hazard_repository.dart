import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../domain/hazard_model.dart';
import 'package:uuid/uuid.dart';

class HazardNotifier extends Notifier<List<HazardModel>> {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'hazards';

  @override
  List<HazardModel> build() {
    // Real-time Firestore listener
    final sub = _db.collection(_col)
        .orderBy('reportedAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      final models = snap.docs.map((doc) {
        final d = doc.data();
        return HazardModel(
          id: doc.id,
          type: HazardType.values.firstWhere(
            (t) => t.name == (d['type'] ?? ''),
            orElse: () => HazardType.accident,
          ),
          location: LatLng(
            (d['lat'] ?? 0.0).toDouble(),
            (d['lng'] ?? 0.0).toDouble(),
          ),
          reportedAt: DateTime.tryParse(d['reportedAt'] ?? '') ?? DateTime.now(),
          reportedBy: d['reportedBy'] ?? 'Anonymous',
        );
      }).toList();
      state = models;
    });
    ref.onDispose(sub.cancel);
    return [];
  }

  void addHazard(HazardType type, double lat, double lng) {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    final reporter = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.trim()
        : (user?.email?.trim().isNotEmpty == true)
            ? user!.email!.trim()
            : 'Anonymous';
    final hazard = HazardModel(
      id: id,
      type: type,
      location: LatLng(lat, lng),
      reportedAt: now,
      reportedBy: reporter,
    );
    // Optimistic local update
    state = [...state, hazard];

    // Firestore write (non-blocking)
    _db.collection(_col).doc(id).set({
      'id': id,
      'type': type.name,
      'lat': lat,
      'lng': lng,
      'reportedAt': now.toIso8601String(),
      'reportedBy': reporter,
      'reporterUid': user?.uid,
      'status': 'active',
    }).catchError((e) {
      debugPrint('[HazardRepo] Firestore write failed (offline?): $e');
    });
  }
}

final activeHazardsProvider = NotifierProvider<HazardNotifier, List<HazardModel>>(() {
  return HazardNotifier();
});

