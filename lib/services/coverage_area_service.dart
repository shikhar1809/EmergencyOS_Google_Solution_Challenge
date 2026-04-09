import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../features/staff/domain/coverage_area_model.dart';

abstract final class CoverageAreaService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'ops_coverage_areas';

  static Stream<List<CoverageArea>> watchCoverageAreas() {
    return _db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CoverageArea.fromFirestore).toList())
        .handleError((e) {
          debugPrint('[CoverageAreaService] watch: $e');
        });
  }

  static Future<List<CoverageArea>> fetchOnce() async {
    try {
      final snap = await _db
          .collection(_col)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(CoverageArea.fromFirestore).toList();
    } catch (e) {
      debugPrint('[CoverageAreaService] fetchOnce: $e');
      return const <CoverageArea>[];
    }
  }

  static Future<String> saveCoverageArea(CoverageArea area) async {
    final ref = area.id.isEmpty
        ? _db.collection(_col).doc()
        : _db.collection(_col).doc(area.id);
    await ref.set(area.toFirestore(), SetOptions(merge: true));
    return ref.id;
  }

  static Future<void> toggleActive(String id, bool active) async {
    await _db.collection(_col).doc(id).update({'isActive': active});
  }

  static Future<void> deleteCoverageArea(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  static Future<void> updateHexKeys(String id, List<String> hexKeys) async {
    await _db.collection(_col).doc(id).update({'hexKeys': hexKeys});
  }
}
