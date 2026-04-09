import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import 'ops_incident_hospital_assignment_service.dart';

/// Lightweight wrapper around `ops_incident_hospital_assignments/{incidentId}` for UI widgets.
@immutable
class DispatchChainState {
  final OpsIncidentHospitalAssignment? assignment;

  const DispatchChainState(this.assignment);

  String get status => assignment?.dispatchStatus ?? 'none';

  /// High-level phase for victim/volunteer UIs.
  String get phaseLabel {
    final s = status;
    switch (s) {
      case 'pending_acceptance':
        return 'awaiting_hospital';
      case 'accepted':
        return 'hospital_accepted';
      case 'exhausted':
        return 'exhausted';
      default:
        return s.isEmpty ? 'none' : s;
    }
  }

  String get currentHospitalName =>
      assignment?.notifiedHospitalName ??
      assignment?.acceptedHospitalName ??
      assignment?.primaryHospitalName ??
      '—';

  /// 1-indexed dispatch tier (1 = same hex, 2 = nearby 5 rings, 3 = all specialists).
  int get currentTier => assignment?.currentTier ?? 1;

  String get currentTierLabel => assignment?.currentTierLabel ?? 'Tier 1 · Same hex';

  /// Position of the hospital currently being notified (for map markers).
  LatLng? get notifiedHospitalPosition {
    final lat = assignment?.notifiedHospitalLat;
    final lng = assignment?.notifiedHospitalLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  /// Position of the hospital that accepted (for map markers).
  LatLng? get acceptedHospitalPosition {
    final lat = assignment?.acceptedHospitalLat;
    final lng = assignment?.acceptedHospitalLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  /// Seconds remaining in the current 2-minute notification window.
  /// Returns null if no notifiedAt or already accepted/exhausted.
  int? get countdownSecondsRemaining {
    final notAt = assignment?.notifiedAt;
    if (notAt == null) return null;
    if (status == 'accepted' || status == 'exhausted') return null;
    final windowMs = assignment?.escalateAfterMs ?? 120000;
    final elapsed = DateTime.now().difference(notAt).inMilliseconds;
    final remaining = ((windowMs - elapsed) / 1000).ceil();
    return remaining > 0 ? remaining : 0;
  }

  bool get isAccepted => status == 'accepted';
  bool get isExhausted => status == 'exhausted';
  bool get isPendingAcceptance => status == 'pending_acceptance';
}

/// Streams dispatch-chain state for a given SOS incident.
abstract final class DispatchChainService {
  static Stream<DispatchChainState> watchForIncident(String incidentId) {
    final id = incidentId.trim();
    if (id.isEmpty) return const Stream<DispatchChainState>.empty();
    return OpsIncidentHospitalAssignmentService.watchForIncident(id).map(
      (a) => DispatchChainState(a),
    );
  }

  /// Underlying raw snapshots, for admin tooling that needs the full document.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> rawAssignmentDoc(
    String incidentId,
  ) {
    final id = incidentId.trim();
    if (id.isEmpty) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('ops_incident_hospital_assignments')
        .doc(id)
        .snapshots();
  }
}
