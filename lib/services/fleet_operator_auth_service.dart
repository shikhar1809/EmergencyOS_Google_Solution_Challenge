import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'fleet_unit_service.dart';

/// Validates **fleet call sign + password** against Firestore `ops_fleet_accounts/{fleetId}`.
///
/// Demo model: doc fields `password` (string), optional `active` (bool, default true).
/// Rules allow **get** only (no list) so IDs are not enumerable from clients.
abstract final class FleetOperatorAuthService {
  static final _db = FirebaseFirestore.instance;

  /// Returns `vehicleType` from Firestore (e.g. `medical`, `crane`) when credentials
  /// match and account is active; otherwise `null`.
  /// [fleetId] is normalised to UPPER-CASE before the Firestore lookup so that
  /// users can type e.g. "ems-lko-1" and still match "EMS-LKO-1".
  static Future<String?> verifyCredentials({
    required String fleetId,
    required String password,
  }) async {
    final id = fleetId.trim().toUpperCase();
    final pw = password.trim();
    if (id.isEmpty || pw.isEmpty) {
      debugPrint('[FleetOperatorAuth] empty id or password');
      return null;
    }

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('[FleetOperatorAuth] anonymous sign-in: $e');
      return null;
    }

    try {
      await FleetUnitService.ensureFleetGateAccounts();
    } catch (e) {
      debugPrint('[FleetOperatorAuth] ensureFleetGateAccounts: $e');
    }

    try {
      debugPrint('[FleetOperatorAuth] looking up ops_fleet_accounts/$id');
      final snap = await _db.collection('ops_fleet_accounts').doc(id).get();
      debugPrint('[FleetOperatorAuth] exists=${snap.exists}');
      if (!snap.exists) return null;
      final d = snap.data();
      if (d == null) return null;
      // Treat missing `active` field as active=true.
      if (d['active'] == false) {
        debugPrint('[FleetOperatorAuth] account $id is inactive');
        return null;
      }
      final storedPw = (d['password'] ?? '').toString().trim();
      final match = storedPw == pw;
      debugPrint('[FleetOperatorAuth] pw match=$match');
      if (!match) return null;
      final vt = (d['vehicleType'] as String?)?.trim().toLowerCase();
      if (vt == null || vt.isEmpty) {
        // Infer from call-sign prefix when legacy docs lack vehicleType.
        return 'medical';
      }
      return vt;
    } catch (e) {
      debugPrint('[FleetOperatorAuth] verify error: $e');
      return null;
    }
  }
}
