import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/india_ops_zones.dart';
import 'incident_service.dart';

/// Compact, text-only digest of [SosIncident] lists for Gemini / ops AI (token-aware).
abstract final class OpsIncidentAnalyticsDigest {
  static const int _maxRecentLines = 22;
  static const int _maxTypes = 10;

  /// True if incident counts as "active" in ops views (not closed).
  static bool isActiveOps(SosIncident e) =>
      e.status != IncidentStatus.resolved && e.status != IncidentStatus.blocked;

  static LatLng centroid(Iterable<SosIncident> incidents, {IndiaOpsZone? zone}) {
    final list = incidents.toList();
    if (list.isEmpty) {
      return zone?.center ?? const LatLng(20.5937, 78.9629);
    }
    var lat = 0.0;
    var lng = 0.0;
    for (final e in list) {
      final p = e.liveVictimPin;
      lat += p.latitude;
      lng += p.longitude;
    }
    final n = list.length.toDouble();
    return LatLng(lat / n, lng / n);
  }

  /// Rich digest for analytics AI + dashboards (keep roughly bounded).
  static String build(List<SosIncident> incidents, {IndiaOpsZone? zone}) {
    var scoped = incidents;
    if (zone != null) {
      scoped = incidents.where((e) => zone.containsLatLng(e.liveVictimPin)).toList();
    }
    final now = DateTime.now();
    final buf = StringBuffer();
    buf.writeln('=== LIVE INCIDENT ANALYTICS (read-only snapshot) ===');
    if (zone != null) {
      buf.writeln('OPS ZONE (India): ${zone.label} · radius ~${zone.radiusKm} km from ${zone.center.latitude.toStringAsFixed(4)}, ${zone.center.longitude.toStringAsFixed(4)}');
    }
    buf.writeln('Generated (client local): ${now.toIso8601String()}');
    buf.writeln('Total records in feed (after zone filter): ${scoped.length}');

    final active = scoped.where(isActiveOps).toList();
    buf.writeln('Active (non-resolved, non-blocked): ${active.length}');

    for (final s in IncidentStatus.values) {
      final n = scoped.where((e) => e.status == s).length;
      if (n > 0) buf.writeln('Status ${s.name}: $n');
    }

    final h1 = scoped.where((e) => now.difference(e.timestamp) <= const Duration(hours: 1)).length;
    final h24 = scoped.where((e) => now.difference(e.timestamp) <= const Duration(hours: 24)).length;
    final d7 = scoped.where((e) => now.difference(e.timestamp) <= const Duration(days: 7)).length;
    buf.writeln('New in last 1h / 24h / 7d (by SOS timestamp): $h1 / $h24 / $d7');

    var emsNone = 0;
    var emsInbound = 0;
    var emsScene = 0;
    for (final e in active) {
      final p = e.emsWorkflowPhase ?? '';
      if (p.isEmpty) {
        emsNone++;
      } else if (p == 'inbound') {
        emsInbound++;
      } else if (p == 'on_scene') {
        emsScene++;
      }
    }
    buf.writeln('EMS workflow (active only): awaiting_unit=$emsNone inbound=$emsInbound on_scene=$emsScene');

    final withVol = active.where((e) => e.acceptedVolunteerIds.isNotEmpty).length;
    final volSlots = active.fold<int>(0, (a, e) => a + e.acceptedVolunteerIds.length);
    final onSceneVol = active.fold<int>(0, (a, e) => a + e.onSceneVolunteerIds.length);
    buf.writeln('Volunteers: incidents_with_any=$withVol total_accept_slots=$volSlots on_scene_volunteer_slots=$onSceneVol');

    final sms = active.where((e) => e.smsRelayOrOrigin).length;
    buf.writeln('SMS-linked active incidents: $sms');

    final typeCounts = <String, int>{};
    for (final e in active) {
      final t = e.type.trim().isEmpty ? 'Unknown' : e.type.trim();
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    final types = typeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    buf.writeln('Top incident types (active):');
    for (var i = 0; i < types.length && i < _maxTypes; i++) {
      buf.writeln('  - ${types[i].key}: ${types[i].value}');
    }

    var triageN = 0;
    var triageHigh = 0;
    var sumScore = 0;
    for (final e in active) {
      final t = e.triage;
      if (t == null || t.isEmpty) continue;
      triageN++;
      final sc = t['severityScore'];
      if (sc is num) {
        final v = sc.toInt();
        sumScore += v;
        if (v >= 50) triageHigh++;
      }
    }
    if (triageN > 0) {
      buf.writeln('Triage snapshots present: $triageN (active), high_severity_score>=50: $triageHigh, avg_score=${(sumScore / triageN).toStringAsFixed(1)}');
    } else {
      buf.writeln('Triage snapshots present: 0 (active)');
    }

    final withAmbPing = active.where((e) => e.ambulanceLiveLocation != null).length;
    buf.writeln('Active with live ambulance GPS ping: $withAmbPing');

    buf.writeln('--- Recent active incidents (newest first, max $_maxRecentLines) ---');
    final sorted = List<SosIncident>.from(active)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    for (var i = 0; i < sorted.length && i < _maxRecentLines; i++) {
      final e = sorted[i];
      final tri = e.triage;
      final triBrief = tri == null || tri.isEmpty
          ? 'no_triage'
          : 'cat=${tri['category'] ?? "?"} score=${tri['severityScore'] ?? "?"}';
      buf.writeln(
        '${e.id} | ${e.type} | status=${e.status.name} | ems=${e.emsWorkflowPhase ?? "none"} | V=${e.acceptedVolunteerIds.length} O=${e.onSceneVolunteerIds.length} | $triBrief | ${e.timestamp.toIso8601String()}',
      );
    }

    buf.writeln('=== END ANALYTICS DIGEST ===');
    return buf.toString();
  }
}
