import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Fleet assignment notification flow:
///   Admin writes → ops_fleet_assignments/{fleetId}/pending/{assignmentId}
///   Driver reads and accepts or rejects.
///
/// Demo fleet units (docId starts with `demo_fleet_`) auto-accept after 10 s.
abstract final class FleetAssignmentService {
  static final _db = FirebaseFirestore.instance;

  // Collection paths
  static const _assignmentsCol = 'ops_fleet_assignments';

  // ── Status constants ───────────────────────────────────────────────────────
  static const statusAwaiting = 'awaiting_response';
  static const statusAccepted = 'accepted';
  static const statusRejected = 'rejected';

  // ── Write (admin side) ────────────────────────────────────────────────────

  /// Sends an assignment notification to [fleetId]'s pending queue.
  /// Returns the new assignment document ID.
  static Future<String> sendAssignment({
    required String fleetId,
    required String incidentId,
    required String vehicleType,
    String? callSign,
  }) async {
    final id = fleetId.trim();
    final iid = incidentId.trim();
    if (id.isEmpty || iid.isEmpty) throw ArgumentError('fleetId and incidentId required');

    final ref = _db.collection(_assignmentsCol).doc(id).collection('pending').doc();
    await ref.set({
      'fleetId': id,
      'incidentId': iid,
      'vehicleType': vehicleType,
      'callSign': callSign ?? id,
      'status': statusAwaiting,
      'dispatchedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Watches assignments waiting for [fleetId]'s response.
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingAssignments(String fleetId) {
    final id = fleetId.trim();
    if (id.isEmpty) return const Stream.empty();
    return _db
        .collection(_assignmentsCol)
        .doc(id)
        .collection('pending')
        .where('status', isEqualTo: statusAwaiting)
        .snapshots()
        .handleError((e) {
      debugPrint('[FleetAssignment] watchPending: $e');
    });
  }

  // ── Write (driver side) ───────────────────────────────────────────────────

  /// Driver accepts: updates status on the pending doc.
  static Future<void> acceptAssignment({
    required String fleetId,
    required String assignmentDocId,
  }) async {
    await _db
        .collection(_assignmentsCol)
        .doc(fleetId.trim())
        .collection('pending')
        .doc(assignmentDocId)
        .update({'status': statusAccepted, 'respondedAt': FieldValue.serverTimestamp()});
  }

  /// Driver rejects: updates status to rejected.
  static Future<void> rejectAssignment({
    required String fleetId,
    required String assignmentDocId,
  }) async {
    await _db
        .collection(_assignmentsCol)
        .doc(fleetId.trim())
        .collection('pending')
        .doc(assignmentDocId)
        .update({
      'status': statusRejected,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Demo automation ───────────────────────────────────────────────────────

  /// For demo fleet units: auto-accepts the assignment after [delaySeconds].
  /// Returns a cancelable [Timer].
  static Timer scheduleAutoAccept({
    required String fleetId,
    required String assignmentDocId,
    int delaySeconds = 10,
    VoidCallback? onAccepted,
  }) {
    return Timer(Duration(seconds: delaySeconds), () async {
      try {
        await acceptAssignment(fleetId: fleetId, assignmentDocId: assignmentDocId);
        onAccepted?.call();
        debugPrint('[FleetAssignment] Demo auto-accepted $assignmentDocId for $fleetId');
      } catch (e) {
        debugPrint('[FleetAssignment] Demo auto-accept failed: $e');
      }
    });
  }

  /// Watches a single assignment for status changes.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchAssignment({
    required String fleetId,
    required String assignmentDocId,
  }) {
    return _db
        .collection(_assignmentsCol)
        .doc(fleetId.trim())
        .collection('pending')
        .doc(assignmentDocId)
        .snapshots();
  }

  /// Clean up old (non-awaiting) assignments older than 1 hour for a fleet unit.
  /// Call this occasionally to keep Firestore tidy (best-effort, not critical).
  static Future<void> cleanupOldAssignments(String fleetId) async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      final snap = await _db
          .collection(_assignmentsCol)
          .doc(fleetId.trim())
          .collection('pending')
          .where('status', whereIn: [statusAccepted, statusRejected])
          .where('dispatchedAt', isLessThan: Timestamp.fromDate(cutoff))
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('[FleetAssignment] cleanup: $e');
    }
  }
}
