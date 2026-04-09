import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/india_ops_zones.dart';
import '../features/staff/domain/admin_panel_access.dart';

/// Lucknow Observatory — destructive master-console operations (Firestore).
class ObservatoryMasterResetService {
  ObservatoryMasterResetService._();

  static final _db = FirebaseFirestore.instance;

  static bool get isMasterConsoleSignedIn {
    final e = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
    return e == AdminPanelAccess.masterConsoleEmail.toLowerCase();
  }

  static LatLng? _pinFromIncidentMap(Map<String, dynamic> data) {
    final lkLat = data['lastKnownLat'];
    final lkLng = data['lastKnownLng'];
    if (lkLat is num && lkLng is num) {
      return LatLng(lkLat.toDouble(), lkLng.toDouble());
    }
    final lat = data['lat'];
    final lng = data['lng'];
    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  static bool _inZone(Map<String, dynamic> data, IndiaOpsZone zone) {
    final p = _pinFromIncidentMap(data);
    if (p == null) return false;
    return zone.containsLatLng(p);
  }

  static Future<void> _deleteSubcollectionInChunks(
    DocumentReference<Map<String, dynamic>> parent,
    String subName, {
    int chunk = 400,
  }) async {
    while (true) {
      final snap = await parent.collection(subName).limit(chunk).get();
      if (snap.docs.isEmpty) break;
      var batch = _db.batch();
      var n = 0;
      for (final d in snap.docs) {
        batch.delete(d.reference);
        n++;
        if (n >= 450) {
          await batch.commit();
          batch = _db.batch();
          n = 0;
        }
      }
      if (n > 0) await batch.commit();
      if (snap.docs.length < chunk) break;
    }
  }

  static Future<void> _deleteActiveIncidentTree(String id) async {
    final ref = _db.collection('sos_incidents').doc(id);
    await _deleteSubcollectionInChunks(ref, 'audit_log');
    await _deleteSubcollectionInChunks(ref, 'victim_activity');
    await ref.delete();
  }

  static Future<void> _deleteArchiveDoc(String id) async {
    await _db.collection('sos_incidents_archive').doc(id).delete();
  }

  static Future<void> _deleteHospitalAssignment(String incidentId) async {
    if (incidentId.isEmpty) return;
    try {
      await _db.collection('ops_incident_hospital_assignments').doc(incidentId).delete();
    } catch (e) {
      debugPrint('[ObservatoryMasterReset] assignment delete $incidentId: $e');
    }
  }

  /// Deletes every doc in [collectionName] in pages (no zone filter).
  /// Active SOS rows remove `audit_log` + `victim_activity` first so subcollections are not orphaned.
  static Future<int> purgeEntireCollection(String collectionName) async {
    if (!isMasterConsoleSignedIn) throw StateError('Master console sign-in required.');
    var total = 0;
    DocumentSnapshot? cursor;
    const page = 200;
    while (true) {
      Query<Map<String, dynamic>> q = _db.collection(collectionName).limit(page);
      if (cursor != null) q = q.startAfterDocument(cursor);
      final snap = await q.get();
      if (snap.docs.isEmpty) break;
      for (final d in snap.docs) {
        if (collectionName == 'sos_incidents') {
          await _deleteActiveIncidentTree(d.id);
        } else {
          await d.reference.delete();
        }
        if (collectionName == 'sos_incidents' || collectionName == 'sos_incidents_archive') {
          await _deleteHospitalAssignment(d.id);
        }
        total++;
      }
      cursor = snap.docs.last;
      if (snap.docs.length < page) break;
    }
    return total;
  }

  /// Active + archive rows whose victim pin falls inside [zone].
  static Future<ObservatoryZonePurgeReport> purgeIncidentsForZone(IndiaOpsZone zone) async {
    if (!isMasterConsoleSignedIn) throw StateError('Master console sign-in required.');
    var active = 0, archive = 0;

    DocumentSnapshot? c1;
    while (true) {
      Query<Map<String, dynamic>> q = _db.collection('sos_incidents').limit(200);
      if (c1 != null) q = q.startAfterDocument(c1);
      final snap = await q.get();
      if (snap.docs.isEmpty) break;
      for (final d in snap.docs) {
        final data = d.data();
        if (_inZone(data, zone)) {
          await _deleteActiveIncidentTree(d.id);
          await _deleteHospitalAssignment(d.id);
          active++;
        }
      }
      c1 = snap.docs.last;
      if (snap.docs.length < 200) break;
    }

    DocumentSnapshot? c2;
    while (true) {
      Query<Map<String, dynamic>> q = _db.collection('sos_incidents_archive').limit(200);
      if (c2 != null) q = q.startAfterDocument(c2);
      final snap = await q.get();
      if (snap.docs.isEmpty) break;
      for (final d in snap.docs) {
        final data = d.data();
        if (_inZone(data, zone)) {
          await _deleteArchiveDoc(d.id);
          await _deleteHospitalAssignment(d.id);
          archive++;
        }
      }
      c2 = snap.docs.last;
      if (snap.docs.length < 200) break;
    }

    return ObservatoryZonePurgeReport(activeDeleted: active, archiveDeleted: archive);
  }

  static Future<int> clearLeaderboard() async {
    if (!isMasterConsoleSignedIn) throw StateError('Master console sign-in required.');
    var n = 0;
    DocumentSnapshot? cursor;
    while (true) {
      Query<Map<String, dynamic>> q = _db.collection('leaderboard').limit(400);
      if (cursor != null) q = q.startAfterDocument(cursor);
      final snap = await q.get();
      if (snap.docs.isEmpty) break;
      var batch = _db.batch();
      var b = 0;
      for (final d in snap.docs) {
        batch.delete(d.reference);
        b++;
        n++;
        if (b >= 450) {
          await batch.commit();
          batch = _db.batch();
          b = 0;
        }
      }
      if (b > 0) await batch.commit();
      cursor = snap.docs.last;
      if (snap.docs.length < 400) break;
    }
    return n;
  }

  /// Post-incident feedback + green zone staging (auxiliary ops data).
  static Future<AuxiliaryPurgeReport> purgeAuxiliaryOpsData() async {
    if (!isMasterConsoleSignedIn) throw StateError('Master console sign-in required.');
    var feedback = 0, greenZone = 0;

    DocumentSnapshot? c;
    while (true) {
      Query<Map<String, dynamic>> q = _db.collection('incident_feedback').limit(400);
      if (c != null) q = q.startAfterDocument(c);
      final snap = await q.get();
      if (snap.docs.isEmpty) break;
      var batch = _db.batch();
      var b = 0;
      for (final d in snap.docs) {
        batch.delete(d.reference);
        feedback++;
        b++;
        if (b >= 450) {
          await batch.commit();
          batch = _db.batch();
          b = 0;
        }
      }
      if (b > 0) await batch.commit();
      c = snap.docs.last;
      if (snap.docs.length < 400) break;
    }

    c = null;
    while (true) {
      Query<Map<String, dynamic>> q = _db.collection('green_zone_requests').limit(400);
      if (c != null) q = q.startAfterDocument(c);
      final snap = await q.get();
      if (snap.docs.isEmpty) break;
      var batch = _db.batch();
      var b = 0;
      for (final d in snap.docs) {
        batch.delete(d.reference);
        greenZone++;
        b++;
        if (b >= 450) {
          await batch.commit();
          batch = _db.batch();
          b = 0;
        }
      }
      if (b > 0) await batch.commit();
      c = snap.docs.last;
      if (snap.docs.length < 400) break;
    }

    return AuxiliaryPurgeReport(feedbackDeleted: feedback, greenZoneRequestsDeleted: greenZone);
  }

  static Future<void> applyUserGamification({
    required String uid,
    required int volunteerXp,
    required int volunteerLivesSaved,
    required int lifelineLevelsCleared,
  }) async {
    if (!isMasterConsoleSignedIn) throw StateError('Master console sign-in required.');
    final t = uid.trim();
    if (t.isEmpty) throw ArgumentError('uid empty');
    await _db.collection('users').doc(t).set(
      {
        'volunteerXp': volunteerXp,
        'volunteerLivesSaved': volunteerLivesSaved,
        'lifelineLevelsCleared': lifelineLevelsCleared,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final lb = _db.collection('leaderboard').doc(t);
    final snap = await lb.get();
    if (snap.exists) {
      await lb.set(
        {
          'volunteerXp': volunteerXp,
          'volunteerLivesSaved': volunteerLivesSaved,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }
}

class ObservatoryZonePurgeReport {
  const ObservatoryZonePurgeReport({
    required this.activeDeleted,
    required this.archiveDeleted,
  });

  final int activeDeleted;
  final int archiveDeleted;
}

class AuxiliaryPurgeReport {
  const AuxiliaryPurgeReport({
    required this.feedbackDeleted,
    required this.greenZoneRequestsDeleted,
  });

  final int feedbackDeleted;
  final int greenZoneRequestsDeleted;
}
