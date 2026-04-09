import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'incident_service.dart';
import 'ops_hospital_service.dart';

/// EmergencyOS: OpsIncidentHospitalAssignment in lib/services/ops_incident_hospital_assignment_service.dart.
class OpsIncidentHospitalAssignment {
  final String incidentId;
  final String? zoneId;
  final int? hexQ;
  final int? hexR;
  final List<String> requiredServices;
  final List<String> candidateHospitalIds;
  final List<String> orderedHospitalIds;
  final List<String> notifiedHospitalIds;
  final String? dispatchStatus;
  final String? notifiedHospitalId;
  final String? notifiedHospitalName;
  final double? notifiedHospitalLat;
  final double? notifiedHospitalLng;
  final DateTime? notifiedAt;
  final int? notifyIndex;
  final int? escalateAfterMs;
  final int? tier1EndIndex;
  final int? tier2EndIndex;
  final String? primaryHospitalId;
  final String? primaryHospitalName;
  final num? primaryDistanceKm;
  final String? acceptedHospitalId;
  final String? acceptedHospitalName;
  final double? acceptedHospitalLat;
  final double? acceptedHospitalLng;
  final DateTime? acceptedAt;
  final String? reason;
  final DateTime? assignedAt;
  final String? ambulanceDispatchStatus;
  final String? assignedFleetCallSign;
  final String? assignedFleetOperatorUid;
  final DateTime? ambulanceDispatchedAt;
  final DateTime? ambulanceAcceptedAt;
  final String? dispatchingHospitalName;

  const OpsIncidentHospitalAssignment({
    required this.incidentId,
    required this.zoneId,
    required this.hexQ,
    required this.hexR,
    required this.requiredServices,
    required this.candidateHospitalIds,
    required this.orderedHospitalIds,
    required this.notifiedHospitalIds,
    required this.dispatchStatus,
    required this.notifiedHospitalId,
    required this.notifiedHospitalName,
    this.notifiedHospitalLat,
    this.notifiedHospitalLng,
    required this.notifiedAt,
    required this.notifyIndex,
    required this.escalateAfterMs,
    this.tier1EndIndex,
    this.tier2EndIndex,
    required this.primaryHospitalId,
    required this.primaryHospitalName,
    required this.primaryDistanceKm,
    required this.acceptedHospitalId,
    required this.acceptedHospitalName,
    this.acceptedHospitalLat,
    this.acceptedHospitalLng,
    required this.acceptedAt,
    required this.reason,
    required this.assignedAt,
    required this.ambulanceDispatchStatus,
    required this.assignedFleetCallSign,
    required this.assignedFleetOperatorUid,
    required this.ambulanceDispatchedAt,
    required this.ambulanceAcceptedAt,
    required this.dispatchingHospitalName,
  });

  /// Current dispatch tier (1-indexed) based on notifyIndex and tier boundaries.
  int get currentTier {
    final idx = notifyIndex ?? 0;
    if (tier1EndIndex != null && idx < tier1EndIndex!) return 1;
    if (tier2EndIndex != null && idx < tier2EndIndex!) return 2;
    return 3;
  }

  String get currentTierLabel {
    switch (currentTier) {
      case 1:
        return 'Tier 1 · Same hex';
      case 2:
        return 'Tier 2 · Nearby hospitals';
      default:
        return 'Tier 3 · All specialists';
    }
  }

  factory OpsIncidentHospitalAssignment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final hex = d['incidentHex'] as Map<String, dynamic>?;
    final req = (d['requiredServices'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final chain = (d['candidateHospitalIds'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final ordered = (d['orderedHospitalIds'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final notifiedList = (d['notifiedHospitalIds'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final at = d['assignedAt'];
    final nt = d['notifiedAt'];
    final ac = d['acceptedAt'];
    final ad = d['ambulanceDispatchedAt'];
    final aa = d['ambulanceAcceptedAt'];
    return OpsIncidentHospitalAssignment(
      incidentId: (d['incidentId'] as String?)?.trim().isNotEmpty == true ? (d['incidentId'] as String) : doc.id,
      zoneId: (d['zoneId'] as String?)?.trim(),
      hexQ: (hex?['q'] as num?)?.toInt(),
      hexR: (hex?['r'] as num?)?.toInt(),
      requiredServices: req,
      candidateHospitalIds: chain,
      orderedHospitalIds: ordered,
      notifiedHospitalIds: notifiedList,
      dispatchStatus: (d['dispatchStatus'] as String?)?.trim(),
      notifiedHospitalId: (d['notifiedHospitalId'] as String?)?.trim(),
      notifiedHospitalName: (d['notifiedHospitalName'] as String?)?.trim(),
      notifiedHospitalLat: (d['notifiedHospitalLat'] as num?)?.toDouble(),
      notifiedHospitalLng: (d['notifiedHospitalLng'] as num?)?.toDouble(),
      notifiedAt: nt is Timestamp ? nt.toDate() : null,
      notifyIndex: (d['notifyIndex'] as num?)?.toInt(),
      escalateAfterMs: (d['escalateAfterMs'] as num?)?.toInt(),
      tier1EndIndex: (d['tier1EndIndex'] as num?)?.toInt(),
      tier2EndIndex: (d['tier2EndIndex'] as num?)?.toInt(),
      primaryHospitalId: (d['primaryHospitalId'] as String?)?.trim(),
      primaryHospitalName: (d['primaryHospitalName'] as String?)?.trim(),
      primaryDistanceKm: d['primaryDistanceKm'] as num?,
      acceptedHospitalId: (d['acceptedHospitalId'] as String?)?.trim(),
      acceptedHospitalName: (d['acceptedHospitalName'] as String?)?.trim(),
      acceptedHospitalLat: (d['acceptedHospitalLat'] as num?)?.toDouble(),
      acceptedHospitalLng: (d['acceptedHospitalLng'] as num?)?.toDouble(),
      acceptedAt: ac is Timestamp ? ac.toDate() : null,
      reason: (d['reason'] as String?)?.trim(),
      assignedAt: at is Timestamp ? at.toDate() : null,
      ambulanceDispatchStatus: (d['ambulanceDispatchStatus'] as String?)?.trim(),
      assignedFleetCallSign: (d['assignedFleetCallSign'] as String?)?.trim(),
      assignedFleetOperatorUid: (d['assignedFleetOperatorUid'] as String?)?.trim(),
      ambulanceDispatchedAt: ad is Timestamp ? ad.toDate() : null,
      ambulanceAcceptedAt: aa is Timestamp ? aa.toDate() : null,
      dispatchingHospitalName: (d['dispatchingHospitalName'] as String?)?.trim(),
    );
  }
}

/// EmergencyOS: OpsIncidentHospitalAssignmentService in lib/services/ops_incident_hospital_assignment_service.dart.
class OpsIncidentHospitalAssignmentService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'ops_incident_hospital_assignments';

  static Stream<OpsIncidentHospitalAssignment?> watchForIncident(String incidentId) {
    final id = incidentId.trim();
    if (id.isEmpty) return Stream.value(null);
    return _db.collection(_col).doc(id).snapshots().map((s) {
      if (!s.exists) return null;
      return OpsIncidentHospitalAssignment.fromFirestore(s);
    }).handleError((e) {
      debugPrint('[OpsIncidentHospitalAssignmentService] watch: $e');
    });
  }

  /// Sorts hospitals by straight-line distance from the incident (nearest first)
  /// and persists the chain to `ops_incident_hospital_assignments/{incidentId}`.
  static Future<OpsIncidentHospitalAssignment?> upsertAssignmentForIncident(
    SosIncident incident, {
    List<OpsHospitalRow>? hospitalsSnapshot,
  }) async {
    final id = incident.id.trim();
    if (id.isEmpty) return null;

    final hospitals = hospitalsSnapshot ?? await OpsHospitalService.fetchHospitalsOnce();
    if (hospitals.isEmpty) return null;

    final pin = incident.liveVictimPin;
    final withCoords = hospitals.where((h) => h.lat != null && h.lng != null).toList();
    if (withCoords.isEmpty) return null;

    final scored = <({OpsHospitalRow h, double distKm})>[];
    for (final h in withCoords) {
      final m = Geolocator.distanceBetween(
        pin.latitude,
        pin.longitude,
        h.lat!,
        h.lng!,
      );
      scored.add((h: h, distKm: m / 1000.0));
    }
    scored.sort((a, b) => a.distKm.compareTo(b.distKm));

    if (scored.isEmpty) {
      debugPrint('[OpsIncidentHospitalAssignmentService] no hospitals with coordinates');
      return null;
    }

    final orderedIds = scored.map((e) => e.h.id).toList();
    final primary = scored.first;

    try {
      await _db.collection(_col).doc(id).set(
        {
          'incidentId': id,
          'requiredServices': incident.type.isNotEmpty ? [incident.type.toLowerCase()] : <String>[],
          'candidateHospitalIds': hospitals.map((h) => h.id).toList(),
          'orderedHospitalIds': orderedIds,
          'notifiedHospitalIds': const <String>[],
          'dispatchStatus': 'pending_notify',
          'primaryHospitalId': primary.h.id,
          'primaryHospitalName': primary.h.name,
          'primaryDistanceKm': primary.distKm,
          'assignedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[OpsIncidentHospitalAssignmentService] upsertAssignmentForIncident: $e');
    }

    return OpsIncidentHospitalAssignment(
      incidentId: id,
      zoneId: null,
      hexQ: null,
      hexR: null,
      requiredServices: incident.type.isNotEmpty ? [incident.type.toLowerCase()] : const <String>[],
      candidateHospitalIds: hospitals.map((h) => h.id).toList(),
      orderedHospitalIds: orderedIds,
      notifiedHospitalIds: const <String>[],
      dispatchStatus: 'pending_notify',
      notifiedHospitalId: null,
      notifiedHospitalName: null,
      notifiedAt: null,
      notifyIndex: null,
      escalateAfterMs: null,
      primaryHospitalId: primary.h.id,
      primaryHospitalName: primary.h.name,
      primaryDistanceKm: primary.distKm,
      acceptedHospitalId: null,
      acceptedHospitalName: null,
      acceptedAt: null,
      reason: null,
      assignedAt: DateTime.now(),
      ambulanceDispatchStatus: null,
      assignedFleetCallSign: null,
      assignedFleetOperatorUid: null,
      ambulanceDispatchedAt: null,
      ambulanceAcceptedAt: null,
      dispatchingHospitalName: null,
    );
  }
}

