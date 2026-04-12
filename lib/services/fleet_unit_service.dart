import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/demo_gate_password.dart';
import '../core/utils/fleet_unit_availability.dart';

/// Row data from the Fleet Management placeholder doc (`custom_*`) for a call sign.
class FleetPlaceholderRow {
  const FleetPlaceholderRow({
    this.assignedHospitalId,
    required this.lat,
    required this.lng,
  });

  final String? assignedHospitalId;
  final double lat;
  final double lng;
}

/// Live **vehicle** positions for admin fleet map (not hospitals / station buildings).
/// One document per signed-in operator: `ops_fleet_units/{uid}`.
abstract final class FleetUnitService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'ops_fleet_units';

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchFleetUnits() {
    return _db.collection(_col).snapshots().handleError((e) {
      debugPrint('[FleetUnitService] watch: $e');
    });
  }

  /// Placeholder row for [fleetCallSign] (Fleet Management `custom_*` doc), for default coords / hospital id.
  static Future<FleetPlaceholderRow?> fleetPlaceholderRowForCallSign(String fleetCallSign) async {
    final cs = fleetCallSign.trim();
    if (cs.isEmpty) return null;
    final variants = <String>{cs, cs.toUpperCase(), cs.toLowerCase()}.toList();
    try {
      final snap = await _db.collection(_col).where('fleetCallSign', whereIn: variants).limit(10).get();
      for (final d in snap.docs) {
        if (!isFleetUnitPlaceholderDoc(d.id)) continue;
        final m = d.data();
        final lat = (m['lat'] as num?)?.toDouble();
        final lng = (m['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final raw = (m['assignedHospitalId'] as String?)?.trim();
        final ah = (raw != null && raw.isNotEmpty) ? raw : null;
        return FleetPlaceholderRow(assignedHospitalId: ah, lat: lat, lng: lng);
      }
    } catch (e, st) {
      debugPrint('[FleetUnitService] fleetPlaceholderRowForCallSign: $e\n$st');
    }
    return null;
  }

  /// Upsert this user's unit while location sharing is on (driver consoles).
  static Future<void> syncMyUnit({
    required String vehicleType,
    required double lat,
    required double lng,
    required bool available,
    String? assignedIncidentId,
    double? headingDeg,
    String? fleetCallSign,
    String? stationedHospitalId,
    String? assignedHospitalId,
  }) async {
    final uid = (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
    if (uid.isEmpty) return;
    final data = <String, Object?>{
      'operatorUid': uid,
      'vehicleType': vehicleType,
      'lat': lat,
      'lng': lng,
      'available': available,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (assignedIncidentId != null && assignedIncidentId.trim().isNotEmpty) {
      data['assignedIncidentId'] = assignedIncidentId.trim();
    } else {
      data['assignedIncidentId'] = FieldValue.delete();
    }
    if (headingDeg != null) {
      data['headingDeg'] = headingDeg;
    } else {
      data['headingDeg'] = FieldValue.delete();
    }
    final cs = fleetCallSign?.trim();
    if (cs != null && cs.isNotEmpty) {
      data['fleetCallSign'] = cs;
    } else {
      data['fleetCallSign'] = FieldValue.delete();
    }
    final sh = stationedHospitalId?.trim();
    if (sh != null && sh.isNotEmpty) {
      data['stationedHospitalId'] = sh;
    }
    final ah = assignedHospitalId?.trim();
    if (ah != null && ah.isNotEmpty) {
      data['assignedHospitalId'] = ah;
    }
    await _db.collection(_col).doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<void> markAssignedToIncident({
    required String operatorUid,
    required String incidentId,
  }) async {
    final u = operatorUid.trim();
    final id = incidentId.trim();
    if (u.isEmpty || id.isEmpty) return;
    await _db.collection(_col).doc(u).set(
      {
        'assignedIncidentId': id,
        'available': false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> clearMyUnit() async {
    final uid = (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
    if (uid.isEmpty) return;
    try {
      await _db.collection(_col).doc(uid).delete();
    } catch (e) {
      debugPrint('[FleetUnitService] clearMyUnit: $e');
    }
  }

  static double distanceMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  /// Reserved hook: fleet gate accounts are created with each unit in Fleet Management.
  static Future<void> ensureFleetGateAccounts() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('[FleetUnitService] ensureFleetGateAccounts auth: $e');
      return;
    }
    // Fleet gate accounts are created when units are added in Fleet Management (no demo hospital list).
  }

  static Future<void> ensureAdminDemoFleetSeeded() async {
    // Remove legacy demo ambulance rows from the old hospital-catalog seed (`demo_fleet_amb_*`).
    for (var i = 1; i <= 56; i++) {
      final oldId = 'demo_fleet_amb_$i';
      try {
        await _db.collection(_col).doc(oldId).delete();
      } catch (err) {
        debugPrint('[FleetUnitService] purge old demo fleet $oldId: $err');
      }
    }
  }

  /// Doc id prefix for units created from Fleet Management (not demo, not live driver uid).
  static String customFleetDocIdForCallSign(String fleetCallSign) {
    final raw = fleetCallSign.trim();
    final safe = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final body = safe.isEmpty ? 'fleet_${DateTime.now().millisecondsSinceEpoch}' : safe;
    return 'custom_$body';
  }

  /// Create a new fleet row + gateway account (demo password from DemoGatePassword).
  static Future<void> createUnit({
    required String fleetCallSign,
    required String vehicleType,
    required String driverName,
    required String coPassenger,
    String? assignedHospitalId,
  }) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('[FleetUnitService] createUnit auth: $e');
      rethrow;
    }
    final cs = fleetCallSign.trim();
    if (cs.isEmpty) {
      throw ArgumentError('Call sign is required');
    }
    final vt = vehicleType.trim().toLowerCase();
    if (vt != 'medical' && vt != 'ambulance') {
      throw ArgumentError('Vehicle type must be medical / ambulance');
    }
    final docId = customFleetDocIdForCallSign(cs);
    final existing = await _db.collection(_col).doc(docId).get();
    if (existing.exists) {
      throw StateError('A fleet unit with this call sign already exists.');
    }
    final dupSign = await _db.collection(_col).where('fleetCallSign', isEqualTo: cs).limit(1).get();
    if (dupSign.docs.isNotEmpty) {
      throw StateError('A unit with this fleet ID already exists.');
    }
    const defaultLat = 26.8467;
    const defaultLng = 80.9462;
    final row = <String, dynamic>{
      'operatorUid': docId,
      'vehicleType': vt == 'ambulance' ? 'medical' : vt,
      'lat': defaultLat,
      'lng': defaultLng,
      // Placeholder row only — set true when an operator runs syncMyUnit on duty.
      'available': false,
      'fleetCallSign': cs,
      'driverName': driverName.trim(),
      'coPassenger': coPassenger.trim(),
      'assignedIncidentId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final hid = assignedHospitalId?.trim();
    if (hid != null && hid.isNotEmpty) {
      row['assignedHospitalId'] = hid;
      row['stationedHospitalId'] = hid;
    }
    await _db.collection(_col).doc(docId).set(row, SetOptions(merge: true));
    await _db.collection('ops_fleet_accounts').doc(cs).set(
      {
        'password': DemoGatePassword.value,
        'active': true,
        'vehicleType': row['vehicleType'],
      },
      SetOptions(merge: true),
    );
  }
}
