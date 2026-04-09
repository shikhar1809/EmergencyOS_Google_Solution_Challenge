import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/incident_service.dart';
import '../domain/admin_panel_access.dart';

class MasterInsightsScreen extends StatelessWidget {
  const MasterInsightsScreen({super.key, required this.access});

  final AdminPanelAccess access;

  bool _excludeTrainingIncident(SosIncident e) {
    final id = e.id;
    return id.startsWith('demo_') || id.startsWith('demo_ops_');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.slate900,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              'Insights',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Operational insights from live SOS signals: volumes, phases, and expected response-time improvements.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('sos_incidents')
                  .orderBy('timestamp', descending: true)
                  .limit(300)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('${snap.error}',
                        style: const TextStyle(color: Colors.white54)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentBlue));
                }
                final incidents = snap.data!.docs
                    .map((d) => SosIncident.fromFirestore(d))
                    .where((e) => !_excludeTrainingIncident(e))
                    .toList();

                final open = incidents
                    .where((e) =>
                        e.status == IncidentStatus.pending ||
                        e.status == IncidentStatus.dispatched ||
                        e.status == IncidentStatus.blocked)
                    .toList();

                final byStatus = <IncidentStatus, int>{
                  IncidentStatus.pending: 0,
                  IncidentStatus.dispatched: 0,
                  IncidentStatus.blocked: 0,
                  IncidentStatus.resolved: 0,
                };
                for (final e in incidents) {
                  byStatus[e.status] = (byStatus[e.status] ?? 0) + 1;
                }

                double avgAckMin = 0;
                var ackN = 0;
                for (final e in incidents) {
                  final ack = e.firstAcknowledgedAt;
                  if (ack == null) continue;
                  final d = ack.difference(e.timestamp).inSeconds;
                  if (d <= 0) continue;
                  avgAckMin += d / 60.0;
                  ackN++;
                }
                if (ackN > 0) avgAckMin /= ackN;

                // Simple "improvement" heuristic: better dispatch + triage clarity reduces median time.
                // This is an estimate panel for operators, not a billing/reporting metric.
                final projectedMin = (avgAckMin * 0.8).clamp(0.0, 9999.0);

                final statusSections = <PieChartSectionData>[
                  _pie(
                      value: byStatus[IncidentStatus.pending]!.toDouble(),
                      color: Colors.orangeAccent,
                      label: 'Open'),
                  _pie(
                      value: byStatus[IncidentStatus.dispatched]!.toDouble(),
                      color: Colors.lightBlueAccent,
                      label: 'Assigned'),
                  _pie(
                      value: byStatus[IncidentStatus.blocked]!.toDouble(),
                      color: Colors.redAccent,
                      label: 'Blocked'),
                  _pie(
                      value: byStatus[IncidentStatus.resolved]!.toDouble(),
                      color: Colors.greenAccent,
                      label: 'Closed'),
                ].where((s) => s.value > 0).toList();

                return ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _statCard(
                          title: 'Open incidents',
                          value: '${open.length}',
                          icon: Icons.sos_rounded,
                          color: Colors.orangeAccent,
                        ),
                        _statCard(
                          title: 'Incidents (sample)',
                          value: '${incidents.length}',
                          icon: Icons.timeline,
                          color: Colors.lightBlueAccent,
                        ),
                        _statCard(
                          title: 'Avg first-ack (min)',
                          value: ackN == 0 ? '—' : avgAckMin.toStringAsFixed(1),
                          icon: Icons.timer_outlined,
                          color: Colors.cyanAccent,
                        ),
                        _statCard(
                          title: 'Projected after improvements (min)',
                          value: ackN == 0 ? '—' : projectedMin.toStringAsFixed(1),
                          icon: Icons.trending_down,
                          color: Colors.greenAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _panel(
                          title: 'Status mix',
                          child: statusSections.isEmpty
                              ? const Center(
                                  child: Text('No data',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 12)))
                              : PieChart(
                                  PieChartData(
                                    sections: statusSections,
                                    centerSpaceRadius: 32,
                                    sectionsSpace: 2,
                                  ),
                                ),
                          footer: const Text(
                            'Mix of open/assigned/blocked/closed from recent incidents.',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                        _panel(
                          title: 'Top incident categories',
                          child: _TopTypesBar(incidents: incidents),
                          footer: const Text(
                            'Most frequent incident types in the recent sample.',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                      ],
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

  static Widget _panel({
    required String title,
    required Widget child,
    required Widget footer,
  }) {
    return Container(
      width: 360,
      height: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
          const SizedBox(height: 10),
          footer,
        ],
      ),
    );
  }

  static Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static PieChartSectionData _pie({
    required double value,
    required Color color,
    required String label,
  }) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: value <= 0 ? '' : label,
      radius: 68,
      titleStyle: const TextStyle(
        color: Colors.black,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TopTypesBar extends StatelessWidget {
  const _TopTypesBar({required this.incidents});

  final List<SosIncident> incidents;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final e in incidents) {
      final t = e.type.trim().isEmpty ? 'Unknown' : e.type.trim();
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final take = top.take(6).toList();
    if (take.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white38)),
      );
    }
    final maxV = take.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= take.length) return const SizedBox.shrink();
                final label = take[i].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 54,
                    child: Text(
                      label.length > 10 ? '${label.substring(0, 10)}…' : label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < take.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: take[i].value.toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.cyanAccent.withValues(alpha: 0.85),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxV.toDouble(),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

