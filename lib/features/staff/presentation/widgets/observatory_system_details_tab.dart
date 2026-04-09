import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/admin_panel_access.dart';

class ObservatorySystemDetailsTab extends StatefulWidget {
  const ObservatorySystemDetailsTab({
    super.key,
    required this.accent,
    required this.access,
  });

  final Color accent;
  final AdminPanelAccess access;

  @override
  State<ObservatorySystemDetailsTab> createState() =>
      _ObservatorySystemDetailsTabState();
}

class _ObservatorySystemDetailsTabState
    extends State<ObservatorySystemDetailsTab> {
  PackageInfo? _packageInfo;
  String? _firebaseUserEmail;
  int? _totalUsers;
  int? _totalHospitals;
  int? _totalFleetUnits;
  int? _totalIncidentsToday;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDetails());
  }

  Future<void> _loadDetails() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _firebaseUserEmail = FirebaseAuth.instance.currentUser?.email;

      final todayStart = DateTime.now().toUtc();
      todayStart.subtract(
        Duration(
          hours: todayStart.hour,
          minutes: todayStart.minute,
          seconds: todayStart.second,
        ),
      );
      final todayEnd = todayStart.add(const Duration(days: 1));

      final results = await Future.wait([
        _safeCount(
          () => FirebaseFirestore.instance.collection('users').count().get(),
        ),
        _safeCount(
          () => FirebaseFirestore.instance
              .collection('ops_hospitals')
              .count()
              .get(),
        ),
        _safeCount(
          () => FirebaseFirestore.instance
              .collection('ops_fleet_units')
              .count()
              .get(),
        ),
        _safeCount(
          () => FirebaseFirestore.instance
              .collection('sos_incidents')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
              )
              .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd))
              .count()
              .get(),
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _totalUsers = results[0];
        _totalHospitals = results[1];
        _totalFleetUnits = results[2];
        _totalIncidentsToday = results[3];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<int?> _safeCount(Future<AggregateQuerySnapshot> Function() fn) async {
    try {
      final result = await fn();
      return result.count;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(
                  accent: a,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('App', _packageInfo?.appName ?? 'EmergencyOS'),
                      _row(
                        'Version',
                        '${_packageInfo?.version ?? "?"} (${_packageInfo?.buildNumber ?? "?"})',
                      ),
                      _row('Platform', 'Flutter Web'),
                      _row(
                        'Firebase User',
                        _firebaseUserEmail ?? 'Not signed in',
                      ),
                      _row(
                        'Role',
                        widget.access.role == AdminConsoleRole.master
                            ? 'Master'
                            : 'Medical',
                      ),
                      if (widget.access.boundHospitalDocId != null)
                        _row('Hospital', widget.access.boundHospitalDocId!),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  accent: a,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Totals',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const LinearProgressIndicator(minHeight: 2)
                      else ...[
                        _row('Users', '${_totalUsers ?? "—"}'),
                        _row('Hospitals', '${_totalHospitals ?? "—"}'),
                        _row('Fleet Units', '${_totalFleetUnits ?? "—"}'),
                        _row(
                          'Incidents Today',
                          '${_totalIncidentsToday ?? "—"}',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  accent: a,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firestore',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _row('Project', 'emergancy-os'),
                      _row('Region', 'asia-south1'),
                      _row(
                        'Collections',
                        'sos_incidents, sos_incidents_archive, users, ops_hospitals, ops_fleet_units, leaderboard, incident_feedback, green_zone_requests',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, required Color accent}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
