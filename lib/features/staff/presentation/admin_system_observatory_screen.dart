import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/india_ops_zones.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/incident_service.dart';
import '../../../services/observatory_audit_service.dart';
import '../../../services/ops_system_health_service.dart';
import '../domain/admin_panel_access.dart';
import '../domain/command_center_accent.dart';
import 'widgets/observatory_system_details_tab.dart';
import 'widgets/observatory_system_logs_tab.dart';
import 'widgets/observatory_controls_tab.dart';

/// Full-pane observatory: integration health, proxy load, archive preview, merged audit (logo entry).
class AdminSystemObservatoryScreen extends StatefulWidget {
  const AdminSystemObservatoryScreen({
    super.key,
    required this.access,
    required this.onClose,
  });

  final AdminPanelAccess access;
  final VoidCallback onClose;

  @override
  State<AdminSystemObservatoryScreen> createState() =>
      _AdminSystemObservatoryScreenState();
}

class _HealthProbeEntry {
  _HealthProbeEntry({
    required this.at,
    required this.summary,
    required this.allOk,
  });

  final DateTime at;
  final String summary;
  final bool allOk;
}

class _AdminSystemObservatoryScreenState
    extends State<AdminSystemObservatoryScreen>
    with SingleTickerProviderStateMixin {
  static final _zone = IndiaOpsZones.lucknow;

  late TabController _tabs;

  List<SosIncident> _activeRaw = [];
  List<SosIncident> _archiveRaw = [];

  StreamSubscription<List<SosIncident>>? _subActive;
  StreamSubscription<List<SosIncident>>? _subArchive;

  OpsSystemHealthReport? _masterHealth;
  OpsDataPlaneHealthReport? _hospitalHealth;
  Object? _healthErr;
  bool _healthLoading = false;

  final List<_HealthProbeEntry> _probeHistory = [];
  Timer? _healthTimer;

  int? _hospitalArchiveTotal;
  int _fleetVisible = 0;

  List<MergedAuditRow> _auditRows = [];
  bool _auditLoading = false;
  String _auditFilter = '';

  @override
  void initState() {
    super.initState();
    final tabCount = widget.access.role == AdminConsoleRole.master ? 5 : 4;
    _tabs = TabController(length: tabCount, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 &&
          _tabs.indexIsChanging == false &&
          _auditRows.isEmpty &&
          !_auditLoading) {
        unawaited(_refreshAudit());
      }
    });

    _subActive = IncidentService.watchActiveIncidentsForOps(limit: 160).listen((
      list,
    ) {
      if (mounted) setState(() => _activeRaw = list);
    });
    if (widget.access.role == AdminConsoleRole.medical) {
      final hid = (widget.access.boundHospitalDocId ?? '').trim();
      if (hid.isNotEmpty) {
        _subArchive =
            IncidentService.watchArchivedForHospital(
              hospitalDocId: hid,
              limit: 100,
            ).listen((list) {
              if (mounted) setState(() => _archiveRaw = list);
            });
        unawaited(_loadHospitalArchiveCount(hid));
      }
    } else {
      _subArchive = IncidentService.watchRecentArchivedForOps(limit: 120)
          .listen((list) {
            if (mounted) setState(() => _archiveRaw = list);
          });
    }

    unawaited(_refreshHealth());
    unawaited(_loadFleetCount());
    _healthTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => unawaited(_refreshHealth()),
    );
  }

  Future<void> _loadHospitalArchiveCount(String hid) async {
    try {
      final agg = await FirebaseFirestore.instance
          .collection('sos_incidents_archive')
          .where('handledByHospitalId', isEqualTo: hid)
          .count()
          .get();
      if (!mounted) return;
      setState(() => _hospitalArchiveTotal = agg.count ?? 0);
    } catch (_) {
      if (mounted) setState(() => _hospitalArchiveTotal = null);
    }
  }

  Future<void> _loadFleetCount() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('ops_fleet_units')
          .limit(250)
          .get();
      var n = 0;
      for (final d in snap.docs) {
        if (widget.access.isFleetDocVisible(d.data(), d.id)) n++;
      }
      if (mounted) setState(() => _fleetVisible = n);
    } catch (_) {
      if (mounted) setState(() => _fleetVisible = 0);
    }
  }

  List<SosIncident> get _scopedActive {
    if (widget.access.role == AdminConsoleRole.master) {
      return _activeRaw
          .where((e) => _zone.containsLatLng(e.liveVictimPin))
          .toList();
    }
    final hid = (widget.access.boundHospitalDocId ?? '').trim();
    if (hid.isEmpty) return [];
    return _activeRaw
        .where((e) => (e.respondingHospitalDocId ?? '').trim() == hid)
        .toList();
  }

  List<SosIncident> get _scopedArchive {
    if (widget.access.role == AdminConsoleRole.master) {
      return _archiveRaw
          .where((e) => _zone.containsLatLng(e.liveVictimPin))
          .toList();
    }
    return _archiveRaw;
  }

  Future<void> _refreshHealth() async {
    if (!mounted) return;
    setState(() {
      _healthLoading = true;
      _healthErr = null;
    });
    try {
      if (widget.access.role == AdminConsoleRole.master) {
        final r = await OpsSystemHealthService.fetch();
        if (!mounted) return;
        setState(() {
          _masterHealth = r;
          _hospitalHealth = null;
          _healthLoading = false;
          _pushProbe(r.summary, r.ok);
        });
      } else {
        final r = await OpsDataPlaneHealthService.fetch();
        if (!mounted) return;
        setState(() {
          _hospitalHealth = r;
          _masterHealth = null;
          _healthLoading = false;
          _pushProbe(r.summary, r.ok);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _healthErr = e;
        _healthLoading = false;
        _pushProbe('Probe failed: $e', false);
      });
    }
  }

  void _pushProbe(String summary, bool allOk) {
    final now = DateTime.now();
    _probeHistory.insert(
      0,
      _HealthProbeEntry(at: now, summary: summary, allOk: allOk),
    );
    if (_probeHistory.length > 12) _probeHistory.removeLast();
  }

  List<String> _incidentIdsForAudit() {
    final a = _scopedActive.take(14).map((e) => e.id).toList();
    final b = _scopedArchive.take(14).map((e) => e.id).toList();
    final set = <String>{...a, ...b};
    return set.toList();
  }

  Future<void> _refreshAudit() async {
    final ids = _incidentIdsForAudit();
    if (ids.isEmpty) {
      if (mounted) setState(() => _auditRows = []);
      return;
    }
    setState(() => _auditLoading = true);
    try {
      final rows = await ObservatoryAuditService.fetchMerged(incidentIds: ids);
      if (!mounted) return;
      setState(() {
        _auditRows = rows;
        _auditLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _auditLoading = false);
    }
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    _subActive?.cancel();
    _subArchive?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = CommandCenterAccent.forRole(widget.access.role).primary;
    final isMaster = widget.access.role == AdminConsoleRole.master;

    return Material(
      color: const Color(0xFF0B1120),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF0B1120), accent, 0.12)!,
              const Color(0xFF0B1120),
              const Color(0xFF020617),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, accent, isMaster),
            Material(
              color: Colors.black.withValues(alpha: 0.22),
              child: TabBar(
                controller: _tabs,
                indicatorColor: accent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                tabs: [
                  const Tab(
                    text: 'Overview',
                    icon: Icon(Icons.hub_outlined, size: 18),
                  ),
                  const Tab(
                    text: 'Activity log',
                    icon: Icon(Icons.timeline_outlined, size: 18),
                  ),
                  Tab(
                    text: 'System',
                    icon: const Icon(Icons.computer_outlined, size: 18),
                  ),
                  Tab(
                    text: 'Logs',
                    icon: const Icon(Icons.article_outlined, size: 18),
                  ),
                  if (widget.access.role == AdminConsoleRole.master)
                    Tab(
                      text: 'Controls',
                      icon: const Icon(Icons.settings_outlined, size: 18),
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _overviewTab(context, accent, isMaster),
                  _activityTab(context, accent),
                  ObservatorySystemDetailsTab(
                    accent: accent,
                    access: widget.access,
                  ),
                  ObservatorySystemLogsTab(
                    accent: accent,
                    access: widget.access,
                  ),
                  if (isMaster)
                    ObservatoryControlsTab(
                      accent: accent,
                      access: widget.access,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Color accent, bool isMaster) {
    final title = isMaster ? 'Lucknow observatory' : 'Facility observatory';
    final subtitle = isMaster
        ? '${_zone.label} · ${_zone.radiusKm.round()} km command mesh'
        : 'Hospital-scoped telemetry & records';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withValues(alpha: 0.15),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(Icons.radar_rounded, color: accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                if (!isMaster &&
                    (widget.access.boundHospitalDocId ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child:
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('ops_hospitals')
                              .doc(widget.access.boundHospitalDocId!.trim())
                              .snapshots(),
                          builder: (context, snap) {
                            final name =
                                (snap.data?.data()?['name'] ??
                                        widget.access.boundHospitalDocId)
                                    .toString();
                            return Text(
                              name,
                              style: TextStyle(
                                color: accent.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _overviewTab(BuildContext context, Color accent, bool isMaster) {
    final active = _scopedActive;
    final archive = _scopedArchive;

    final statusCounts = <String, int>{};
    for (final s in IncidentStatus.values) {
      statusCounts[s.name] = active.where((e) => e.status == s).length;
    }
    var emsAwait = 0, emsInbound = 0, emsScene = 0, emsTransport = 0;
    for (final e in active) {
      final p = e.emsWorkflowPhase ?? '';
      if (p.isEmpty) {
        emsAwait++;
      } else if (p == 'inbound') {
        emsInbound++;
      } else if (p == 'on_scene') {
        emsScene++;
      } else if (p == 'transport_complete') {
        emsTransport++;
      }
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isMaster
                      ? 'Figures below are filtered to the Lucknow ops zone (same boundary as Overview). '
                            'Geo totals are feed-based, not global Firestore counts.'
                      : 'Figures reflect incidents tied to this facility (responding hospital on active rows; '
                            'handled-by on archive).',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final cols = w > 1100 ? 3 : (w > 720 ? 2 : 1);
                    final children = <Widget>[
                      _bentoStat(
                        accent,
                        'Active in scope',
                        '${active.length}',
                        Icons.bolt_rounded,
                        'Non-resolved rows in 48h ops feed, scoped',
                      ),
                      _bentoStat(
                        accent,
                        'Archive (preview)',
                        '${archive.length}',
                        Icons.inventory_2_outlined,
                        'Recent archived rows in this view',
                      ),
                      _bentoStat(
                        accent,
                        'Fleet markers',
                        '$_fleetVisible',
                        Icons.local_shipping_outlined,
                        'Visible units for your role',
                      ),
                    ];
                    if (!isMaster && _hospitalArchiveTotal != null) {
                      children.add(
                        _bentoStat(
                          accent,
                          'Archived (total)',
                          '$_hospitalArchiveTotal',
                          Icons.done_all_outlined,
                          'Firestore count · handledByHospitalId',
                        ),
                      );
                    }
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: cols >= 2 ? 1.55 : 1.35,
                      children: children,
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'EMS workflow (active in scope)',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chipMetric('Awaiting unit', emsAwait, Colors.white24),
                    _chipMetric(
                      'Inbound',
                      emsInbound,
                      Colors.orangeAccent.shade200,
                    ),
                    _chipMetric(
                      'On scene',
                      emsScene,
                      Colors.tealAccent.shade200,
                    ),
                    _chipMetric(
                      'Transport done',
                      emsTransport,
                      Colors.lightBlueAccent.shade200,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Status mix (active in scope)',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statusCounts.entries
                      .where((e) => e.value > 0)
                      .map((e) => _chipMetric(e.key, e.value, Colors.white24))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Integration probes',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isMaster
                      ? 'Health checks run from Cloud Functions (not live CPU / QPS). History shows recent probes only.'
                      : 'Facility view excludes SMS provider internals. Use master console for full stack status.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                if (_healthLoading &&
                    _masterHealth == null &&
                    _hospitalHealth == null)
                  const LinearProgressIndicator(minHeight: 2)
                else if (_healthErr != null &&
                    _masterHealth == null &&
                    _hospitalHealth == null)
                  _glassCard(
                    child: Text(
                      '$_healthErr',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (_masterHealth != null)
                  _masterServiceCards(_masterHealth!, accent)
                else if (_hospitalHealth != null)
                  _hospitalServiceCards(_hospitalHealth!, accent),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _healthLoading
                          ? null
                          : () => unawaited(_refreshHealth()),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh probes'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_healthLoading)
                      const Text(
                        'Checking…',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Probe history',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                if (_probeHistory.isEmpty)
                  Text(
                    'No probes yet.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
                    ),
                  )
                else
                  ..._probeHistory.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _glassCard(
                        child: Row(
                          children: [
                            Icon(
                              e.allOk
                                  ? Icons.verified_rounded
                                  : Icons.warning_amber_rounded,
                              size: 18,
                              color: e.allOk
                                  ? const Color(0xFF66BB6A)
                                  : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.summary,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat.Hms().format(e.at.toLocal()),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Recent archive (scoped)',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        _tabs.animateTo(1);
                        unawaited(_refreshAudit());
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open activity log'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (archive.isEmpty)
                  _glassCard(
                    child: Text(
                      'No archived rows in this scoped feed yet.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ...archive.take(8).map((e) => _archiveRow(e)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _masterServiceCards(OpsSystemHealthReport r, Color accent) {
    return Column(
      children: [
        _serviceTile(r.gcp, accent),
        const SizedBox(height: 8),
        _serviceTile(r.livekit, accent),
        const SizedBox(height: 8),
        _serviceTile(r.sms, accent),
        const SizedBox(height: 6),
        Text(
          'Last check: ${DateFormat.yMMMd().add_Hms().format(DateTime.fromMillisecondsSinceEpoch(r.checkedAtMs))}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _hospitalServiceCards(OpsDataPlaneHealthReport r, Color accent) {
    return Column(
      children: [
        _serviceTile(r.firestore, accent),
        const SizedBox(height: 8),
        _serviceTile(r.livekit, accent),
        const SizedBox(height: 6),
        Text(
          'Last check: ${DateFormat.yMMMd().add_Hms().format(DateTime.fromMillisecondsSinceEpoch(r.checkedAtMs))}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _serviceTile(OpsServiceHealth s, Color accent) {
    return _glassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            s.ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: s.ok ? const Color(0xFF66BB6A) : Colors.orangeAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.label,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _archiveRow(SosIncident e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  e.status.name,
                  style: TextStyle(
                    color: AppColors.accentBlue.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${e.id} · ${DateFormat.MMMd().add_Hm().format(e.timestamp.toLocal())}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityTab(BuildContext context, Color accent) {
    final filter = _auditFilter.trim().toLowerCase();
    final rows = filter.isEmpty
        ? _auditRows
        : _auditRows
              .where(
                (r) =>
                    r.incidentId.toLowerCase().contains(filter) ||
                    r.action.toLowerCase().contains(filter) ||
                    r.note.toLowerCase().contains(filter),
              )
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Filter by incident id, action, note…',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) => setState(() => _auditFilter = v),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _auditLoading
                    ? null
                    : () => unawaited(_refreshAudit()),
                icon: _auditLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: rows.isEmpty
                    ? null
                    : () async {
                        final csv = ObservatoryAuditService.toCsv(rows);
                        await Clipboard.setData(ClipboardData(text: csv));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied ${rows.length} rows (CSV)'),
                            ),
                          );
                        }
                      },
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
                label: const Text('Copy CSV'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Merged from up to ~14 active + ~14 archived incident IDs in scope (${_incidentIdsForAudit().length} ids). '
            'Audit subcollections live under `sos_incidents/{id}/audit_log`.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rows.isEmpty && !_auditLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _auditRows.isEmpty && _incidentIdsForAudit().isEmpty
                          ? 'No scoped incidents yet — nothing to merge.'
                          : 'No rows match the filter. Tap Refresh to load audit timelines.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.incidentId,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMMMd().add_Hms().format(
                                  r.at.toLocal(),
                                ),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r.action,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              if (r.fromStatus.isNotEmpty ||
                                  r.toStatus.isNotEmpty)
                                Text(
                                  '${r.fromStatus} → ${r.toStatus}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 11,
                                  ),
                                ),
                              if (r.note.isNotEmpty)
                                Text(
                                  r.note,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _bentoStat(
    Color accent,
    String label,
    String value,
    IconData icon,
    String foot,
  ) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            foot,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipMetric(String label, int n, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        '$label · $n',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
