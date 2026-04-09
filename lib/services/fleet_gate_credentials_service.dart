import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/demo_gate_password.dart';

/// Read / create / rotate `ops_fleet_accounts/{callSign}` for fleet operator sign-in.
abstract final class FleetGateCredentialsService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'ops_fleet_accounts';

  static String _normCallSign(String s) => s.trim().toUpperCase();

  static String _randomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static Future<void> _ensureAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseAuth.instance.signInAnonymously();
  }

  static Future<bool> gateAccountExists(String fleetCallSign) async {
    final id = _normCallSign(fleetCallSign);
    if (id.isEmpty) return false;
    try {
      await _ensureAuth();
      final snap = await _db.collection(_col).doc(id).get();
      return snap.exists;
    } catch (e) {
      debugPrint('[FleetGateCredentials] gateAccountExists: $e');
      return false;
    }
  }

  /// Current gate password, or null if doc missing / empty.
  static Future<String?> readPassword(String fleetCallSign) async {
    final id = _normCallSign(fleetCallSign);
    if (id.isEmpty) return null;
    try {
      await _ensureAuth();
      final snap = await _db.collection(_col).doc(id).get();
      if (!snap.exists) return null;
      final pw = (snap.data()?['password'] ?? '').toString().trim();
      return pw.isEmpty ? null : pw;
    } catch (e) {
      debugPrint('[FleetGateCredentials] readPassword: $e');
      return null;
    }
  }

  /// Creates gate doc with demo password when missing; returns stored password.
  static Future<String> ensureGateAccount({
    required String fleetCallSign,
    required String vehicleType,
  }) async {
    final id = _normCallSign(fleetCallSign);
    if (id.isEmpty) {
      throw ArgumentError('Call sign is required');
    }
    await _ensureAuth();
    final vt = vehicleType.trim().toLowerCase();
    final resolvedVt = (vt.isEmpty || vt == '—') ? 'medical' : vt;
    final ref = _db.collection(_col).doc(id);
    final snap = await ref.get();
    if (snap.exists) {
      final pw = (snap.data()?['password'] ?? '').toString().trim();
      if (pw.isNotEmpty) return pw;
    }
    final initial = DemoGatePassword.value;
    await ref.set(
      {
        'password': initial,
        'active': true,
        'vehicleType': resolvedVt,
      },
      SetOptions(merge: true),
    );
    return initial;
  }

  /// New random password; preserves vehicle type when present.
  static Future<String> rotatePassword({
    required String fleetCallSign,
    required String vehicleType,
  }) async {
    final id = _normCallSign(fleetCallSign);
    if (id.isEmpty) {
      throw ArgumentError('Call sign is required');
    }
    await _ensureAuth();
    final vt = vehicleType.trim().toLowerCase();
    final resolvedVt = (vt.isEmpty || vt == '—') ? 'medical' : vt;
    final next = _randomPassword();
    await _db.collection(_col).doc(id).set(
      {
        'password': next,
        'active': true,
        'vehicleType': resolvedVt,
      },
      SetOptions(merge: true),
    );
    return next;
  }
}
