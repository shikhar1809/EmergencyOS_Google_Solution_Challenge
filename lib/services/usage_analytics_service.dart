import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Lightweight Firestore-backed analytics for impact metrics (Solution Challenge / pilots).
///
/// Events are written to the `analytics_events` collection. Security rules should
/// restrict writes to authenticated users and limit fields.
class UsageAnalyticsService {
  UsageAnalyticsService._();
  static final UsageAnalyticsService instance = UsageAnalyticsService._();

  static const String collectionName = 'analytics_events';

  /// Fire-and-forget event log. Silently no-ops when user is not signed in.
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? params,
    int? valueMs,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;

      await FirebaseFirestore.instance.collection(collectionName).add({
        'name': name,
        'uid': uid,
        'ts': FieldValue.serverTimestamp(),
        if (params != null) 'params': params,
        if (valueMs != null) 'valueMs': valueMs,
        'platform': kIsWeb ? 'web' : 'native',
      });
    } catch (e, st) {
      debugPrint('[UsageAnalytics] $name failed: $e\n$st');
    }
  }

  // ── Canonical event names (align with docs/IMPACT_METRICS.md) ───────────

  Future<void> sosInitiated({String? incidentId}) =>
      logEvent('sos_initiated', params: {if (incidentId != null) 'incidentId': incidentId});

  Future<void> sosCompleted({String? incidentId}) =>
      logEvent('sos_completed', params: {if (incidentId != null) 'incidentId': incidentId});

  Future<void> timeToFirstGuidance({required int elapsedMs}) =>
      logEvent('time_to_first_guidance', valueMs: elapsedMs);

  Future<void> volunteerAcceptedLatency({required int elapsedMs, String? incidentId}) =>
      logEvent(
        'volunteer_accepted_latency',
        valueMs: elapsedMs,
        params: {if (incidentId != null) 'incidentId': incidentId},
      );

  Future<void> triageCameraUsed() => logEvent('triage_camera_used');

  Future<void> lifelineLevelCompleted({required String levelId}) =>
      logEvent('lifeline_level_completed', params: {'levelId': levelId});

  Future<void> goldenHourMilestoneReached({required int minuteMark}) =>
      logEvent('golden_hour_milestone_reached', params: {'minuteMark': minuteMark});

  Future<void> drillCompleted({String? mode}) =>
      logEvent('drill_completed', params: {if (mode != null) 'mode': mode});
}
