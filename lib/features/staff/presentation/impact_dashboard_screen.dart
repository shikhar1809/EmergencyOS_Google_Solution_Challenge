import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/india_ops_zones.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/map/domain/emergency_zone_classification.dart';
import '../../../services/incident_service.dart';
import '../../../services/places_service.dart';
import '../domain/admin_panel_access.dart';
import 'widgets/command_center_map.dart';

/// Impact dashboard with KPIs, charts, and a mini zone map driven by sos_incidents.
class ImpactDashboardScreen extends StatelessWidget {
  const ImpactDashboardScreen({super.key, required this.access});

  final AdminPanelAccess access;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.slate900,
      appBar: AppBar(
        backgroundColor: AppColors.slate800,
        title: const Text('Impact dashboard'),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('sos_incidents').limit(200).snapshots(),
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
            return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
          }
          final docs = snap.data!.docs;
          final incidents = docs.map(SosIncident.fromFirestore).toList();

          if (incidents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No impact data yet.\nSOS activity in your zone will populate these charts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            );
          }

          final now = DateTime.now();
          final handled = incidents.where((e) => e.status == IncidentStatus.resolved).length;
          final active = incidents.where((e) => e.status == IncidentStatus.pending || e.status == IncidentStatus.dispatched).length;
          final meanResp = _meanAcceptanceMinutes(incidents);
          final lifelineCompletion = _lifelineCompletionPercent(incidents);
          final activeZones = _activeZoneCount(incidents);

          final typeBuckets = _typeHistogram(incidents);
          final timeBuckets = _timeSeriesCounts(incidents, now);
          final responseBuckets = _responseTimeBuckets(incidents);
          final statusBuckets = _statusBuckets(incidents);

          final hexCenter = _centroidOrFallback(incidents);
          final hexModel = buildEmergencyHexZones(
            center: hexCenter,
            hospitals: const <EmergencyPlace>[],
            volunteerPositions: const <LatLng>[],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impact overview (${access.role.name})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _KpiCard(
                      title: 'Incidents handled',
                      value: '$handled',
                      subtitle: 'Resolved sos_incidents (all time)',
                    ),
                    _KpiCard(
                      title: 'Mean response time',
                      value: meanResp,
                      subtitle: 'First acknowledgement from SOS',
                    ),
                    _KpiCard(
                      title: 'Lifeline completion',
                      value: lifelineCompletion,
                      subtitle: 'Completion from triage / training fields',
                    ),
                    _KpiCard(
                      title: 'Active zones',
                      value: '$activeZones',
                      subtitle: 'Hex areas with recent load',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;
                    return Column(
                      children: [
                        Flex(
                          direction: isNarrow ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment:
                              isNarrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ChartCard(
                                title: 'Incident type breakdown',
                                child: _PieFromMap(data: typeBuckets),
                              ),
                            ),
                            const SizedBox(width: 16, height: 16),
                            Expanded(
                              child: _ChartCard(
                                title: 'Incidents over time',
                                child: _LineFromSeries(series: timeBuckets),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Flex(
                          direction: isNarrow ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment:
                              isNarrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ChartCard(
                                title: 'Response time distribution',
                                child: _BarFromBuckets(buckets: responseBuckets),
                              ),
                            ),
                            const SizedBox(width: 16, height: 16),
                            Expanded(
                              child: _ChartCard(
                                title: 'Status breakdown',
                                child: _StackedStatusBar(buckets: statusBuckets),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ChartCard(
                          title: 'Zone health map',
                          child: SizedBox(
                            height: 260,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CommandCenterMap(
                                zone: IndiaOpsZones.lucknow,
                                markers: const <Marker>{},
                                polylines: const <Polyline>{},
                                polygons: hexModel.polygons,
                                showHexGrid: true,
                                hexCoverRadiusM: hexModel.coverRadiusM,
                                overlayCircles: const <Circle>{},
                                initialPosition: hexCenter,
                                initialZoom: 11,
                                onCameraMove: (_) {},
                                onMapCreated: (_) {},
                                onTap: (_) {},
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _meanAcceptanceMinutes(List<SosIncident> list) {
    var total = 0.0;
    var n = 0;
    for (final e in list) {
      final ack = e.firstAcknowledgedAt;
      if (ack == null) continue;
      final dt = ack.difference(e.timestamp).inSeconds / 60.0;
      if (dt.isNaN || dt.isInfinite || dt < 0) continue;
      total += dt;
      n++;
    }
    if (n == 0) return '—';
    final mean = total / n;
    return '${mean.toStringAsFixed(1)} min';
  }

  static String _lifelineCompletionPercent(List<SosIncident> list) {
    var withTriage = 0;
    for (final e in list) {
      if (e.triage != null && e.triage!.isNotEmpty) {
        withTriage++;
      }
    }
    if (list.isEmpty) return '—';
    final pct = (withTriage / list.length) * 100.0;
    return '${pct.toStringAsFixed(0)}%';
  }

  static int _activeZoneCount(List<SosIncident> list) {
    final buckets = <String>{};
    for (final e in list) {
      final p = e.liveVictimPin;
      final latKey = (p.latitude * 100).round(); // ~1 km bucket
      final lngKey = (p.longitude * 100).round();
      buckets.add('$latKey:$lngKey');
    }
    return buckets.length;
  }

  static Map<String, int> _typeHistogram(List<SosIncident> list) {
    final m = <String, int>{};
    for (final e in list) {
      final t = e.type.trim().isEmpty ? 'Unknown' : e.type.trim();
      m[t] = (m[t] ?? 0) + 1;
    }
    return m;
  }

  static List<_TimeBucket> _timeSeriesCounts(List<SosIncident> list, DateTime now) {
    const hoursBack = 24;
    final buckets = List.generate(
      hoursBack,
      (i) => _TimeBucket(
        label: '${hoursBack - i}h',
        start: now.subtract(Duration(hours: hoursBack - i)),
        end: now.subtract(Duration(hours: hoursBack - i - 1)),
      ),
    );
    for (final e in list) {
      for (final b in buckets) {
        if (!e.timestamp.isBefore(b.start) && e.timestamp.isBefore(b.end)) {
          b.count++;
          break;
        }
      }
    }
    return buckets;
  }

  static Map<String, int> _responseTimeBuckets(List<SosIncident> list) {
    final m = <String, int>{
      '<2 min': 0,
      '2–5 min': 0,
      '5–10 min': 0,
      '10+ min': 0,
    };
    for (final e in list) {
      final ack = e.firstAcknowledgedAt;
      if (ack == null) continue;
      final mins = ack.difference(e.timestamp).inSeconds / 60.0;
      if (mins < 0) continue;
      if (mins < 2) {
        m['<2 min'] = m['<2 min']! + 1;
      } else if (mins < 5) {
        m['2–5 min'] = m['2–5 min']! + 1;
      } else if (mins < 10) {
        m['5–10 min'] = m['5–10 min']! + 1;
      } else {
        m['10+ min'] = m['10+ min']! + 1;
      }
    }
    return m;
  }

  static Map<IncidentStatus, int> _statusBuckets(List<SosIncident> list) {
    final m = <IncidentStatus, int>{
      IncidentStatus.pending: 0,
      IncidentStatus.dispatched: 0,
      IncidentStatus.resolved: 0,
      IncidentStatus.blocked: 0,
    };
    for (final e in list) {
      m[e.status] = (m[e.status] ?? 0) + 1;
    }
    return m;
  }

  static LatLng _centroidOrFallback(List<SosIncident> list) {
    if (list.isEmpty) {
      return const LatLng(26.8467, 80.9462);
    }
    var lat = 0.0;
    var lng = 0.0;
    for (final e in list) {
      lat += e.liveVictimPin.latitude;
      lng += e.liveVictimPin.longitude;
    }
    return LatLng(lat / list.length, lng / list.length);
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        color: AppColors.slate800,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 10, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.slate800,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: child),
          ],
        ),
      ),
    );
  }
}

class _PieFromMap extends StatelessWidget {
  const _PieFromMap({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.white54, fontSize: 12)));
    }
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.white54, fontSize: 12)));
    }
    final entries = data.entries.toList();
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 32,
        sections: [
          for (var i = 0; i < entries.length; i++)
            PieChartSectionData(
              value: entries[i].value.toDouble(),
              title: '${((entries[i].value / total) * 100).toStringAsFixed(0)}%',
              radius: 60,
              color: Colors.primaries[i % Colors.primaries.length],
              titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

class _LineFromSeries extends StatelessWidget {
  const _LineFromSeries({required this.series});

  final List<_TimeBucket> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.white54, fontSize: 12)));
    }
    final maxY = series.fold<double>(0, (m, b) => b.count > m ? b.count.toDouble() : m);
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 4,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= series.length) {
                  return const SizedBox.shrink();
                }
                return Text(series[idx].label, style: const TextStyle(color: Colors.white54, fontSize: 9));
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (series.length - 1).toDouble(),
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppColors.accentBlue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: [
              for (var i = 0; i < series.length; i++)
                FlSpot(i.toDouble(), series[i].count.toDouble()),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarFromBuckets extends StatelessWidget {
  const _BarFromBuckets({required this.buckets});

  final Map<String, int> buckets;

  @override
  Widget build(BuildContext context) {
    if (buckets.values.every((c) => c == 0)) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.white54, fontSize: 12)));
    }
    final labels = buckets.keys.toList();
    final maxY = buckets.values.fold<int>(0, (m, v) => v > m ? v : m).toDouble();
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[idx],
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < labels.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[labels[i]]!.toDouble(),
                  color: AppColors.accentBlue,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
        maxY: maxY == 0 ? 1 : maxY * 1.2,
      ),
    );
  }
}

class _StackedStatusBar extends StatelessWidget {
  const _StackedStatusBar({required this.buckets});

  final Map<IncidentStatus, int> buckets;

  @override
  Widget build(BuildContext context) {
    final total = buckets.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.white54, fontSize: 12)));
    }
    final colors = {
      IncidentStatus.resolved: Colors.greenAccent,
      IncidentStatus.dispatched: Colors.lightBlueAccent,
      IncidentStatus.pending: Colors.orangeAccent,
      IncidentStatus.blocked: Colors.redAccent,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: AppColors.slate900,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              for (final status in IncidentStatus.values)
                if (buckets[status] != null && buckets[status]! > 0)
                  Expanded(
                    flex: buckets[status]!,
                    child: Container(color: colors[status]),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final status in IncidentStatus.values)
              if (buckets[status] != null && buckets[status]! > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, color: colors[status]),
                    const SizedBox(width: 4),
                    Text(
                      '${status.name} · ${((buckets[status]! / total) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}

class _TimeBucket {
  _TimeBucket({
    required this.label,
    required this.start,
    required this.end,
  });

  final String label;
  final DateTime start;
  final DateTime end;
  int count = 0;
}
