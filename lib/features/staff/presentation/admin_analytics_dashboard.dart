import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/maps/eos_hybrid_map.dart';
import '../../../core/constants/india_ops_zones.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/ops_analytics_hex_grid.dart';
import '../../../core/utils/ops_map_markers.dart';
import '../../../core/utils/osrm_route_util.dart';
import '../../../core/utils/fleet_map_icons.dart';
import '../../../services/incident_service.dart';
import '../../../services/ops_analytics_derived.dart';
import '../../../services/ops_incident_analytics_digest.dart';
import '../domain/admin_panel_access.dart';
import '../domain/command_center_accent.dart';
import 'liveops_feedback_dashboard.dart';
import 'widgets/command_center_shared_widgets.dart';
import 'widgets/ops_analytics_trend_chart.dart';

enum _AnalyticsCategory { sos, fleet, hospitals, volunteers, feedback }

/// Live incident analytics: real-time metrics from Firestore + Gemini-backed Q&A on the same data.
class AdminAnalyticsDashboard extends StatefulWidget {
  const AdminAnalyticsDashboard({super.key, required this.access});

  final AdminPanelAccess access;

  @override
  State<AdminAnalyticsDashboard> createState() =>
      _AdminAnalyticsDashboardState();
}

bool _excludeTrainingIncident(SosIncident e) {
  final id = e.id;
  return id.startsWith('demo_') || id.startsWith('demo_ops_');
}

class _AdminAnalyticsDashboardState extends State<AdminAnalyticsDashboard> {
  final _aiCtrl = TextEditingController();
  final _scrollAi = ScrollController();
  final List<_AiMsg> _aiMsgs = [];
  bool _aiLoading = false;
  IndiaOpsZone? _zone;
  Timer? _analyticsSimTimer;
  double _analyticsMapZoom = 11.0;
  _AnalyticsCategory _analyticsCategory = _AnalyticsCategory.sos;
  bool _analyticsAiOpen = true;

  Color get _accent => CommandCenterAccent.forRole(widget.access.role).primary;

  @override
  void initState() {
    super.initState();
    _aiMsgs.add(
      const _AiMsg(
        false,
        'This assistant reads the **same live incident feed** as the metrics on the left. '
        'Ask about volumes, EMS phases, volunteers, triage severity, SMS-linked cases, or trends.',
      ),
    );
    _bootstrapZone();
    _analyticsSimTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (context.mounted && _zone != null) setState(() {});
    });
  }

  Future<void> _bootstrapZone() async {
    await OpsMapMarkers.preload();
    await FleetMapIcons.preload();
    if (!context.mounted) return;
    setState(() => _zone = IndiaOpsZones.lucknow);
  }

  @override
  void dispose() {
    _analyticsSimTimer?.cancel();
    _aiCtrl.dispose();
    _scrollAi.dispose();
    super.dispose();
  }

  void _scrollAiToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollAi.hasClients) {
        _scrollAi.animateTo(
          _scrollAi.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendAi() async {
    final text = _aiCtrl.text.trim();
    if (text.isEmpty || _aiLoading) return;
    setState(() {
      _aiLoading = true;
      _aiMsgs.add(_AiMsg(true, text));
      _aiCtrl.clear();
    });
    _scrollAiToEnd();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('sos_incidents')
          .limit(500)
          .get();
      final all = snap.docs
          .map(SosIncident.fromFirestore)
          .where((e) => !_excludeTrainingIncident(e))
          .toList();
      final z = _zone!;
      final nowAi = DateTime.now();
      final inZ = all.where((e) => z.containsLatLng(e.liveVictimPin)).toList();
      final inc48 = inZ
          .where(
            (e) => nowAi.difference(e.timestamp) <= const Duration(hours: 48),
          )
          .toList();
      final inc7d = inZ
          .where(
            (e) => nowAi.difference(e.timestamp) <= const Duration(days: 7),
          )
          .toList();
      final trend7 = OpsAnalyticsDerived.sevenDayCountsInZone(inZ, nowAi);
      final b48 = OpsAnalyticsDerived.hexBinsForIncidents(inc48, z);
      final b7d = OpsAnalyticsDerived.hexBinsForIncidents(inc7d, z);
      final digest = OpsIncidentAnalyticsDigest.build(all, zone: _zone);
      final augment = OpsAnalyticsDerived.augmentForGemini(
        trend7: trend7,
        hotspot48h: OpsAnalyticsDerived.hotspotSummary(b48, z),
        hotspot7d: OpsAnalyticsDerived.hotspotSummary(b7d, z),
      );
      final fullDigest = '$digest\n$augment';

      final hist = <Map<String, String>>[];
      for (var i = 0; i < _aiMsgs.length - 1; i++) {
        final m = _aiMsgs[i];
        hist.add({'role': m.isUser ? 'user' : 'model', 'text': m.text});
      }

      final callable = FirebaseFunctions.instance.httpsCallable('lifelineChat');
      final res = await callable.call({
        'message': text,
        'scenario': 'Emergency operations center — live incident analytics',
        'contextDigest': fullDigest,
        'history': hist,
        'analyticsMode': true,
      });
      final raw = res.data;
      final Map<String, dynamic> data = raw is Map
          ? raw.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};
      final status = (data['status'] as String?)?.trim() ?? 'ok';
      var reply = (data['text'] as String?)?.trim() ?? 'No response.';
      if (status == 'rate_limited') {
        reply = '[Rate limited] $reply';
      } else if (status == 'offline') {
        reply = '[Analytics AI offline] $reply';
      }
      if (context.mounted) setState(() => _aiMsgs.add(_AiMsg(false, reply)));
    } catch (e) {
      if (context.mounted)
        setState(() => _aiMsgs.add(_AiMsg(false, 'AI error: $e')));
    } finally {
      if (context.mounted) setState(() => _aiLoading = false);
      _scrollAiToEnd();
    }
  }

  Future<void> _runAutoSummary() async {
    _aiCtrl.text =
        'Give a concise executive summary (5–7 bullets) of current operations from the live data: workload, EMS, volunteers, and any risks.';
    await _sendAi();
  }

  Future<void> _runGeminiHotspot() async {
    _aiCtrl.text =
        'Using the hex hotspot and 7-day trend in the digest, where should we pre-stage ambulances and volunteers, and what is the main risk story?';
    await _sendAi();
  }

  Future<void> _runGeminiTrend() async {
    _aiCtrl.text =
        'Explain the 7-day incident trend: is load accelerating, stable, or declining? What actions do you recommend?';
    await _sendAi();
  }

  Widget _analyticsChip(_AnalyticsCategory c, String label, IconData icon) {
    final on = _analyticsCategory == c;
    return Material(
      color: on
          ? _accent.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _analyticsCategory = c),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: on ? _accent : Colors.white54),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: on ? _accent : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _analyticsStatusSection(int activeN, int inZoneN) {
    final hint = switch (_analyticsCategory) {
      _AnalyticsCategory.sos =>
        'All SOS incidents, hex density, EMS mix, and triage in the main pane.',
      _AnalyticsCategory.fleet =>
        'Dispatch and EMS workflow emphasis — map still shows live pins.',
      _AnalyticsCategory.hospitals =>
        'Hotspots, triage severity, and SMS-linked cases.',
      _AnalyticsCategory.volunteers =>
        'Volunteer attachment counts and responder lines on the map.',
      _AnalyticsCategory.feedback =>
        'Post-incident ratings and comments from resolved SOS flows.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$activeN active · $inZoneN in zone',
          style: const TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildAiAssistantPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: Text(
            'Gemini sees Firestore digest plus 7-day trend and hex hotspots (48h & 7d). Not a substitute for 112.',
            style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.35),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: _aiLoading ? null : _runGeminiHotspot,
                child: const Text(
                  'Hotspot insight',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: _aiLoading ? null : _runGeminiTrend,
                child: const Text(
                  'Trend insight',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollAi,
            padding: const EdgeInsets.all(12),
            itemCount: _aiMsgs.length,
            itemBuilder: (_, i) {
              final m = _aiMsgs[i];
              return Align(
                alignment: m.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: m.isUser
                        ? AppColors.accentBlue.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_aiLoading) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _aiCtrl,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ask about the live feed…',
                    hintStyle: const TextStyle(
                      color: Colors.white30,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (_) => _sendAi(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _aiLoading ? null : _sendAi,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                ),
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, int> _typeHistogram(List<SosIncident> active) {
    final m = <String, int>{};
    for (final e in active) {
      final t = e.type.trim().isEmpty ? 'Unknown' : e.type.trim();
      m[t] = (m[t] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.access.canUseAnalytics) {
      return const Scaffold(
        primary: false,
        backgroundColor: AppColors.slate900,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Analytics is available to Master and Medical console roles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ),
        ),
      );
    }
    if (_zone == null) {
      return const Scaffold(
        primary: false,
        backgroundColor: AppColors.slate900,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }
    final zone = _zone!;
    final user = FirebaseAuth.instance.currentUser;
    final timeFmt = DateFormat('HH:mm:ss');

    return Scaffold(
      primary: false,
      backgroundColor: AppColors.slate900,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.slate800,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _analyticsCategory == _AnalyticsCategory.feedback &&
                            widget.access.canUseLiveOpsFeedback
                        ? Icons.feedback_outlined
                        : Icons.analytics,
                    color: AppColors.accentBlue,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _analyticsCategory == _AnalyticsCategory.feedback &&
                                  widget.access.canUseLiveOpsFeedback
                              ? 'Community post-incident feedback'
                              : 'Live operations analytics',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          _analyticsCategory == _AnalyticsCategory.feedback &&
                                  widget.access.canUseLiveOpsFeedback
                              ? 'Ratings and comments from resolved SOS cases'
                              : '${zone.label} · map locked to this area',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    user?.email?.trim().isNotEmpty == true
                        ? user!.email!.trim()
                        : (widget.access.boundHospitalDocId != null
                              ? 'Hospital ${widget.access.boundHospitalDocId}'
                              : user?.uid ?? ''),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('sos_incidents')
                  .limit(500)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      '${snap.error}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentBlue,
                    ),
                  );
                }
                final incidents = snap.data!.docs
                    .map(SosIncident.fromFirestore)
                    .where((e) => !_excludeTrainingIncident(e))
                    .toList();
                final inZone = incidents
                    .where((e) => zone.containsLatLng(e.liveVictimPin))
                    .toList();
                final active = inZone
                    .where(OpsIncidentAnalyticsDigest.isActiveOps)
                    .toList();
                final now = DateTime.now();
                final pending = active
                    .where((e) => e.status == IncidentStatus.pending)
                    .length;
                final dispatched = active
                    .where((e) => e.status == IncidentStatus.dispatched)
                    .length;
                final emsAwait = active
                    .where((e) => (e.emsWorkflowPhase ?? '').isEmpty)
                    .length;
                final emsInbound = active
                    .where((e) => e.emsWorkflowPhase == 'inbound')
                    .length;
                final emsScene = active
                    .where((e) => e.emsWorkflowPhase == 'on_scene')
                    .length;
                final withVol = active
                    .where((e) => e.acceptedVolunteerIds.isNotEmpty)
                    .length;
                final h24 = inZone
                    .where(
                      (e) =>
                          now.difference(e.timestamp) <=
                          const Duration(hours: 24),
                    )
                    .length;
                final smsN = active.where((e) => e.smsRelayOrOrigin).length;
                var triHigh = 0;
                var triN = 0;
                for (final e in active) {
                  final t = e.triage;
                  if (t == null || t.isEmpty) continue;
                  triN++;
                  final sc = t['severityScore'];
                  if (sc is num && sc >= 50) triHigh++;
                }
                final types = _typeHistogram(active);
                final topTypes = types.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final center = OpsIncidentAnalyticsDigest.centroid(
                  active.take(80),
                  zone: zone,
                );
                final fbOrange = BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                );
                final fbAzure = BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                );
                final fbGreen = BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                );
                final fbViolet = BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueViolet,
                );
                final markers = <Marker>{};
                for (final e in active.take(72)) {
                  final p = e.liveVictimPin;
                  final zIn = e.emsWorkflowPhase == 'inbound' ? 3 : 1;
                  final icon = switch (e.status) {
                    IncidentStatus.pending => OpsMapMarkers.incidentOr(
                      fbOrange,
                    ),
                    IncidentStatus.dispatched => OpsMapMarkers.ambulanceOr(
                      fbAzure,
                    ),
                    IncidentStatus.blocked => OpsMapMarkers.sceneOr(fbViolet),
                    IncidentStatus.resolved => OpsMapMarkers.incidentOr(
                      fbGreen,
                    ),
                  };
                  markers.add(
                    Marker(
                      markerId: MarkerId('a_${e.id}'),
                      position: p,
                      zIndexInt: zIn,
                      icon: icon,
                    ),
                  );
                }

                final analyticsVolunteerPolylines = <Polyline>{};
                var avIdx = 0;
                for (final e in active.take(40)) {
                  final v = e.volunteerLiveLocation;
                  if (v == null) continue;
                  analyticsVolunteerPolylines.add(
                    Polyline(
                      polylineId: PolylineId('an_vol_${e.id}_$avIdx'),
                      points: OsrmRouteUtil.fallbackPolyline(
                        v,
                        e.liveVictimPin,
                      ),
                      color: AppColors.primarySafe,
                      width: 4,
                      zIndex: 2,
                      patterns: [PatternItem.dash(10), PatternItem.gap(6)],
                    ),
                  );
                  avIdx++;
                }

                final trend7 = OpsAnalyticsDerived.sevenDayCountsInZone(
                  inZone,
                  now,
                );
                final inc48h = inZone
                    .where(
                      (e) =>
                          now.difference(e.timestamp) <=
                          const Duration(hours: 48),
                    )
                    .toList();
                final bins48 = OpsAnalyticsDerived.hexBinsForIncidents(
                  inc48h,
                  zone,
                );
                final hexSize = OpsAnalyticsHexGrid.hexSizeMetersForZone(
                  zone.radiusM,
                );
                var maxHex = 1;
                for (final v in bins48.values) {
                  if (v > maxHex) maxHex = v;
                }
                final hexPolygons = <Polygon>{};
                for (final e in bins48.entries) {
                  final h = OpsAnalyticsHexGrid.parseKey(e.key);
                  final ring = OpsAnalyticsHexGrid.hexRing(
                    h.q,
                    h.r,
                    zone.center,
                    hexSize,
                  );
                  final t = e.value / maxHex;
                  hexPolygons.add(
                    Polygon(
                      polygonId: PolygonId('hx_${e.key.replaceAll(',', '_')}'),
                      points: ring,
                      strokeColor: Colors.white.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      fillColor: Color.lerp(
                        const Color(0xFF1565C0).withValues(alpha: 0.1),
                        const Color(0xFFFF5722).withValues(alpha: 0.5),
                        t,
                      )!,
                    ),
                  );
                }

                final cat = _analyticsCategory;
                final showFeedbackPane =
                    cat == _AnalyticsCategory.feedback &&
                    widget.access.canUseLiveOpsFeedback;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 368,
                      child: ColoredBox(
                        color: AppColors.slate800,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _analyticsChip(
                                          _AnalyticsCategory.sos,
                                          'SOS',
                                          Icons.emergency_outlined,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _analyticsChip(
                                          _AnalyticsCategory.fleet,
                                          'Fleet',
                                          Icons.local_shipping_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _analyticsChip(
                                          _AnalyticsCategory.hospitals,
                                          'Hospitals',
                                          Icons.local_hospital_outlined,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _analyticsChip(
                                          _AnalyticsCategory.volunteers,
                                          'Volunteers',
                                          Icons.groups_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.access.canUseLiveOpsFeedback) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _analyticsChip(
                                            _AnalyticsCategory.feedback,
                                            'Feedback',
                                            Icons.feedback_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _analyticsStatusSection(
                                        active.length,
                                        inZone.length,
                                      ),
                                      if (!showFeedbackPane) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(
                                            10,
                                            12,
                                            10,
                                            14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF151A22),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.insights_rounded,
                                                    size: 16,
                                                    color: AppColors.accentBlue
                                                        .withValues(alpha: 0.9),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Trends & metrics',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              OpsAnalyticsTrendChart(
                                                counts: trend7,
                                                now: now,
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Hex overlay: 48h incident density (blue → orange = more incidents in that cell). Not a dispatch boundary.',
                                                style: TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 10,
                                                  height: 1.3,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              ..._metricsRailTail(
                                                cat: cat,
                                                bins48: bins48,
                                                zone: zone,
                                                inc48h: inc48h,
                                                active: active,
                                                pending: pending,
                                                dispatched: dispatched,
                                                h24: h24,
                                                withVol: withVol,
                                                smsN: smsN,
                                                triN: triN,
                                                triHigh: triHigh,
                                                topTypes: topTypes,
                                                emsAwait: emsAwait,
                                                emsInbound: emsInbound,
                                                emsScene: emsScene,
                                                hexSize: hexSize,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.white12,
                    ),
                    Expanded(
                      child: showFeedbackPane
                          ? LiveOpsFeedbackDashboard(
                              access: widget.access,
                              embedInParent: true,
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          10,
                                          14,
                                          6,
                                        ),
                                        child: Row(
                                          children: [
                                            _livePill(
                                              timeFmt.format(DateTime.now()),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                '${active.length} active · ${inZone.length} in zone · ${incidents.length} in feed',
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: _aiLoading
                                                  ? null
                                                  : _runAutoSummary,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.accentBlue,
                                              ),
                                              icon: const Icon(
                                                Icons.auto_awesome,
                                                size: 18,
                                              ),
                                              label: const Text('AI summary'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            0,
                                            14,
                                            10,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: EosHybridMap(
                                              initialCameraPosition:
                                                  CameraPosition(
                                                    target: center,
                                                    zoom: active.isEmpty
                                                        ? zone.defaultZoom
                                                        : 11,
                                                  ),
                                              onCameraMove: (c) {
                                                final z = c.zoom;
                                                if ((z - _analyticsMapZoom)
                                                        .abs() >
                                                    0.12) {
                                                  _analyticsMapZoom = z;
                                                  setState(() {});
                                                }
                                              },
                                              cameraTargetBounds:
                                                  CameraTargetBounds(
                                                    zone.cameraBounds,
                                                  ),
                                              minMaxZoomPreference:
                                                  const MinMaxZoomPreference(
                                                    5.5,
                                                    17,
                                                  ),
                                              mapType: MapType.normal,
                                              mapId:
                                                  AppConstants
                                                      .googleMapsDarkMapId
                                                      .isNotEmpty
                                                  ? AppConstants
                                                        .googleMapsDarkMapId
                                                  : null,
                                              markers: markers,
                                              polylines:
                                                  analyticsVolunteerPolylines,
                                              polygons: hexPolygons,
                                              zoomControlsEnabled: false,
                                              myLocationButtonEnabled: false,
                                              // AI panel is a [Row] sibling — no extra map inset (avoids right gap).
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OpsCollapsibleDetailPanel(
                                  expanded: _analyticsAiOpen,
                                  onToggleExpanded: () => setState(
                                    () => _analyticsAiOpen = !_analyticsAiOpen,
                                  ),
                                  accent: AppColors.accentBlue,
                                  title: 'Analytics AI',
                                  body: ColoredBox(
                                    color: const Color(0xFF161B22),
                                    child: _buildAiAssistantPanel(),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Hotspot, stat cards, pies, triage — under selection chips in the left analytics column.
  List<Widget> _metricsRailTail({
    required _AnalyticsCategory cat,
    required Map<String, int> bins48,
    required IndiaOpsZone zone,
    required List<SosIncident> inc48h,
    required List<SosIncident> active,
    required int pending,
    required int dispatched,
    required int h24,
    required int withVol,
    required int smsN,
    required int triN,
    required int triHigh,
    required List<MapEntry<String, int>> topTypes,
    required int emsAwait,
    required int emsInbound,
    required int emsScene,
    required double hexSize,
  }) {
    const pieW = 288.0;
    return [
      if (cat == _AnalyticsCategory.sos ||
          cat == _AnalyticsCategory.fleet ||
          cat == _AnalyticsCategory.hospitals ||
          cat == _AnalyticsCategory.volunteers) ...[
        _panel(
          title: 'Hotspot · hex density (48h, same grid as map)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                OpsAnalyticsDerived.hotspotSummary(bins48, zone),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${bins48.length} filled cells · ${inc48h.length} incidents in last 48h · '
                'hex ~${(hexSize / 1000).toStringAsFixed(1)} km (vertex radius)',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (cat == _AnalyticsCategory.sos)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              'Active',
              '${active.length}',
              Icons.emergency,
              Colors.orangeAccent,
            ),
            _statCard(
              'Pending',
              '$pending',
              Icons.pending_actions,
              Colors.amber,
            ),
            _statCard(
              'Dispatched',
              '$dispatched',
              Icons.send,
              AppColors.accentBlue,
            ),
            _statCard('24h (all)', '$h24', Icons.schedule, Colors.cyanAccent),
            _statCard(
              '+Volunteers',
              '$withVol',
              Icons.groups,
              Colors.lightGreenAccent,
            ),
            _statCard('SMS-linked', '$smsN', Icons.sms, Colors.tealAccent),
          ],
        ),
      if (cat == _AnalyticsCategory.fleet)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              'Active',
              '${active.length}',
              Icons.emergency,
              Colors.orangeAccent,
            ),
            _statCard(
              'Pending',
              '$pending',
              Icons.pending_actions,
              Colors.amber,
            ),
            _statCard(
              'Dispatched',
              '$dispatched',
              Icons.send,
              AppColors.accentBlue,
            ),
            _statCard('24h (all)', '$h24', Icons.schedule, Colors.cyanAccent),
            _statCard('SMS-linked', '$smsN', Icons.sms, Colors.tealAccent),
          ],
        ),
      if (cat == _AnalyticsCategory.hospitals)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              'Active',
              '${active.length}',
              Icons.emergency,
              Colors.orangeAccent,
            ),
            _statCard('SMS-linked', '$smsN', Icons.sms, Colors.tealAccent),
            _statCard(
              'Dispatched',
              '$dispatched',
              Icons.local_hospital,
              AppColors.accentBlue,
            ),
          ],
        ),
      if (cat == _AnalyticsCategory.volunteers)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              'Active',
              '${active.length}',
              Icons.emergency,
              Colors.orangeAccent,
            ),
            _statCard(
              '+Volunteers',
              '$withVol',
              Icons.groups,
              Colors.lightGreenAccent,
            ),
            _statCard(
              'Pending',
              '$pending',
              Icons.pending_actions,
              Colors.amber,
            ),
            _statCard(
              'Dispatched',
              '$dispatched',
              Icons.send,
              AppColors.accentBlue,
            ),
          ],
        ),
      if (cat == _AnalyticsCategory.sos || cat == _AnalyticsCategory.fleet) ...[
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPiePanel(
              'EMS Workflow Phase',
              [
                if (emsAwait > 0)
                  PieChartSectionData(
                    color: Colors.orange,
                    value: emsAwait.toDouble(),
                    title: '$emsAwait',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (emsInbound > 0)
                  PieChartSectionData(
                    color: AppColors.accentBlue,
                    value: emsInbound.toDouble(),
                    title: '$emsInbound',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (emsScene > 0)
                  PieChartSectionData(
                    color: Colors.greenAccent,
                    value: emsScene.toDouble(),
                    title: '$emsScene',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
              {
                'Awaiting': Colors.orange,
                'Inbound': AppColors.accentBlue,
                'On Scene': Colors.greenAccent,
              },
              panelWidth: pieW,
            ),
            if (cat == _AnalyticsCategory.sos)
              _buildPiePanel(
                'Incident Types',
                _incidentTypePieSections(topTypes),
                _incidentTypeLegend(topTypes),
                panelWidth: pieW,
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
      if (cat == _AnalyticsCategory.volunteers) ...[
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPiePanel(
              'Incident Types',
              _incidentTypePieSections(topTypes),
              _incidentTypeLegend(topTypes),
              panelWidth: pieW,
            ),
          ],
        ),
      ],
      if (cat == _AnalyticsCategory.sos ||
          cat == _AnalyticsCategory.hospitals) ...[
        const SizedBox(height: 16),
        _panel(
          title: 'Triage (active, where present)',
          child: Row(
            children: [
              _statMini('With triage', '$triN'),
              const SizedBox(width: 24),
              _statMini('Score ≥ 50', '$triHigh', emphasize: triHigh > 0),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _livePill(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE · $t',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color c) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: c, size: 22),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate800.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.accentBlue,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPiePanel(
    String title,
    List<PieChartSectionData> sections,
    Map<String, Color> legend, {
    double panelWidth = 320,
  }) {
    return Container(
      width: panelWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: sections.isEmpty
                          ? [
                              PieChartSectionData(
                                color: Colors.white12,
                                value: 1,
                                title: '',
                                radius: 36,
                              ),
                            ]
                          : sections,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: legend.entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  color: e.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: e.value,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    e.key,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _incidentTypePieSections(
    List<MapEntry<String, int>> types,
  ) {
    if (types.isEmpty) return [];
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
    ];
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < types.length && i < 5; i++) {
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: types[i].value.toDouble(),
          title: '${types[i].value}',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    return sections;
  }

  Map<String, Color> _incidentTypeLegend(List<MapEntry<String, int>> types) {
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
    ];
    final legend = <String, Color>{};
    for (var i = 0; i < types.length && i < 5; i++) {
      legend[types[i].key] = colors[i % colors.length];
    }
    return legend;
  }

  Widget _statMini(String k, String v, {bool emphasize = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          v,
          style: TextStyle(
            color: emphasize ? Colors.orangeAccent : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        Text(k, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _typeBar(String name, int count, int maxV) {
    final frac = maxV == 0 ? 0.0 : count / maxV;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: frac.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white10,
            color: AppColors.accentBlue,
          ),
        ),
      ],
    );
  }
}

class _AiMsg {
  final bool isUser;
  final String text;
  const _AiMsg(this.isUser, this.text);
}
