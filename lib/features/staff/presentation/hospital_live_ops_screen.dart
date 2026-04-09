import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/admin_panel_access.dart';
import '../../../services/ops_hospital_service.dart';

/// Live operational status for a bound hospital (medical role) — beds, staffing, services, blood.
class HospitalLiveOpsScreen extends StatefulWidget {
  const HospitalLiveOpsScreen({super.key, required this.access});

  final AdminPanelAccess access;

  @override
  State<HospitalLiveOpsScreen> createState() => _HospitalLiveOpsScreenState();
}

class _HospitalLiveOpsScreenState extends State<HospitalLiveOpsScreen> {
  @override
  Widget build(BuildContext context) {
    final bound = (widget.access.boundHospitalDocId ?? '').trim();
    final scopeNote = widget.access.role == AdminConsoleRole.medical
        ? (bound.isEmpty
            ? 'LiveOps · Medical console — no hospital ID bound.'
            : 'LiveOps · Medical console (hospital $bound)')
        : 'LiveOps (medical console only)';

    return Scaffold(
      primary: false,
      backgroundColor: AppColors.slate900,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              'Hospital Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              scopeNote,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: OpsHospitalService.watchHospitals(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('${snap.error}', style: const TextStyle(color: Colors.white54)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
                }
                var rows = snap.data!;
                if (widget.access.role == AdminConsoleRole.medical) {
                  if (bound.isEmpty) {
                    rows = [];
                  } else {
                    rows = rows.where((r) => r.id == bound).toList();
                  }
                }
                if (rows.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hospital rows for your scope.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }
                final hospitalIds = rows.map((r) => r.id).toList();
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _IncomingEmergencyAlerts(hospitalIds: hospitalIds),
                    for (final r in rows) _LiveOpsHospitalCard(row: r),
                    _AcceptedConsignmentSection(hospitalIds: hospitalIds),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _kLiveOpsServices = <String>[
  'trauma',
  'trauma_support',
  'cardiology',
  'icu',
  'surgery',
  'orthopedics',
  'burns',
  'burn_unit',
  'ent',
  'pediatrics',
  'child_care',
  'blood_bank',
  'blood_availability',
  'neurology',
  'neurosurgery',
  'ventilator_available',
  'dialysis',
  'maternity',
  'cardiac_cathlab',
];

String _liveOpsServiceLabel(String id) {
  switch (id) {
    case 'icu':
      return 'ICU';
    case 'ent':
      return 'ENT';
    case 'blood_bank':
      return 'Blood bank';
    case 'trauma_support':
      return 'Trauma support';
    case 'child_care':
      return 'Child care';
    case 'blood_availability':
      return 'Blood availability';
    case 'burn_unit':
      return 'Burn unit';
    case 'ventilator_available':
      return 'Ventilators';
    case 'cardiac_cathlab':
      return 'Cardiac cath lab';
    default:
      if (id.isEmpty) return id;
      return id[0].toUpperCase() + id.substring(1);
  }
}

class _LiveOpsHospitalCard extends StatefulWidget {
  const _LiveOpsHospitalCard({required this.row});

  final OpsHospitalRow row;

  @override
  State<_LiveOpsHospitalCard> createState() => _LiveOpsHospitalCardState();
}

class _LiveOpsHospitalCardState extends State<_LiveOpsHospitalCard> {
  late final TextEditingController _avail;
  late final TextEditingController _total;
  late final TextEditingController _note;
  late final TextEditingController _doctors;
  late final TextEditingController _specialists;
  late final TextEditingController _bloodUnits;
  late Set<String> _selectedServices;
  late bool _hasBloodBank;
  bool _saving = false;

  void _resyncAllFromRow(OpsHospitalRow r) {
    _avail.text = '${r.bedsAvailable}';
    _total.text = '${r.bedsTotal}';
    _note.text = r.traumaBedsNote ?? '';
    _doctors.text = '${r.doctorsOnDuty}';
    _specialists.text = '${r.specialistsOnCall}';
    _bloodUnits.text = '${r.bloodUnitsAvailable}';
    _selectedServices = Set<String>.from(r.offeredServices);
    _hasBloodBank = r.hasBloodBank;
  }

  void _applyRemoteFieldPatches(OpsHospitalRow oldR, OpsHospitalRow r) {
    if (oldR.bedsAvailable != r.bedsAvailable) _avail.text = '${r.bedsAvailable}';
    if (oldR.bedsTotal != r.bedsTotal) _total.text = '${r.bedsTotal}';
    if ((oldR.traumaBedsNote ?? '') != (r.traumaBedsNote ?? '')) {
      _note.text = r.traumaBedsNote ?? '';
    }
    if (oldR.doctorsOnDuty != r.doctorsOnDuty) _doctors.text = '${r.doctorsOnDuty}';
    if (oldR.specialistsOnCall != r.specialistsOnCall) {
      _specialists.text = '${r.specialistsOnCall}';
    }
    if (oldR.bloodUnitsAvailable != r.bloodUnitsAvailable) {
      _bloodUnits.text = '${r.bloodUnitsAvailable}';
    }
    if (!listEquals(oldR.offeredServices, r.offeredServices)) {
      _selectedServices = Set<String>.from(r.offeredServices);
    }
    if (oldR.hasBloodBank != r.hasBloodBank) _hasBloodBank = r.hasBloodBank;
  }

  @override
  void didUpdateWidget(covariant _LiveOpsHospitalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.id != widget.row.id) {
      _resyncAllFromRow(widget.row);
      return;
    }
    _applyRemoteFieldPatches(oldWidget.row, widget.row);
  }

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    _avail = TextEditingController(text: '${r.bedsAvailable}');
    _total = TextEditingController(text: '${r.bedsTotal}');
    _note = TextEditingController(text: r.traumaBedsNote ?? '');
    _doctors = TextEditingController(text: '${r.doctorsOnDuty}');
    _specialists = TextEditingController(text: '${r.specialistsOnCall}');
    _bloodUnits = TextEditingController(text: '${r.bloodUnitsAvailable}');
    _selectedServices = Set<String>.from(r.offeredServices);
    _hasBloodBank = r.hasBloodBank;
  }

  @override
  void dispose() {
    _avail.dispose();
    _total.dispose();
    _note.dispose();
    _doctors.dispose();
    _specialists.dispose();
    _bloodUnits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final a = int.tryParse(_avail.text.trim()) ?? 0;
    final t = int.tryParse(_total.text.trim()) ?? 0;
    final doc = int.tryParse(_doctors.text.trim()) ?? 0;
    final spec = int.tryParse(_specialists.text.trim()) ?? 0;
    final blood = int.tryParse(_bloodUnits.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      await OpsHospitalService.updateLiveOpsFull(
        id: widget.row.id,
        bedsAvailable: a,
        bedsTotal: t,
        traumaBedsNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
        offeredServices: _selectedServices.toList(),
        hasBloodBank: _hasBloodBank,
        doctorsOnDuty: doc,
        specialistsOnCall: spec,
        bloodUnitsAvailable: blood,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LiveOps updated')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final df = DateFormat('MMM d, yyyy HH:mm');
    return Card(
      color: AppColors.slate800,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${r.id} · ${r.name}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              '${r.region} · last update ${df.format(r.updatedAt.toLocal())}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bed capacity',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _avail,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Beds available'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _total,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Beds total'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 2,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              decoration: _deco('Trauma / capacity notes'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Doctor availability',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _doctors,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Doctors on duty'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _specialists,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Specialists on call'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Blood bank',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bloodUnits,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _deco('Blood units available (approx.)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Has blood bank on-site', style: TextStyle(color: Colors.white70, fontSize: 14)),
              value: _hasBloodBank,
              onChanged: (v) => setState(() => _hasBloodBank = v),
              activeThumbColor: AppColors.accentBlue,
            ),
            const SizedBox(height: 12),
            const Text(
              'Services & capabilities',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kLiveOpsServices.map((id) {
                final selected = _selectedServices.contains(id);
                return FilterChip(
                  label: Text(_liveOpsServiceLabel(id)),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedServices.add(id);
                      } else {
                        _selectedServices.remove(id);
                      }
                    });
                  },
                  selectedColor: AppColors.accentBlue.withValues(alpha: 0.35),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 11,
                  ),
                  side: BorderSide(color: selected ? AppColors.accentBlue : Colors.white24),
                  backgroundColor: AppColors.slate900,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.accentBlue),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save LiveOps'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: AppColors.slate900,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );
}

/// Flashing incoming emergency alert when this hospital is the currently notified
/// target of a dispatch chain. Shows ACCEPT / REFER buttons with a 2-minute countdown.
class _IncomingEmergencyAlerts extends StatelessWidget {
  const _IncomingEmergencyAlerts({required this.hospitalIds});
  final List<String> hospitalIds;

  @override
  Widget build(BuildContext context) {
    if (hospitalIds.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ops_incident_hospital_assignments')
          .where('notifiedHospitalId', whereIn: hospitalIds.take(10).toList())
          .where('dispatchStatus', isEqualTo: 'pending_acceptance')
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: docs.map((doc) {
            return _FlashingAlertCard(
              assignmentDoc: doc,
              hospitalIds: hospitalIds,
            );
          }).toList(),
        );
      },
    );
  }
}

class _FlashingAlertCard extends StatefulWidget {
  const _FlashingAlertCard({
    required this.assignmentDoc,
    required this.hospitalIds,
  });
  final QueryDocumentSnapshot<Map<String, dynamic>> assignmentDoc;
  final List<String> hospitalIds;

  @override
  State<_FlashingAlertCard> createState() => _FlashingAlertCardState();
}

class _FlashingAlertCardState extends State<_FlashingAlertCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _countdownTimer;
  int _secondsLeft = 120;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _startCountdown();
  }

  void _startCountdown() {
    final d = widget.assignmentDoc.data();
    final nt = d['notifiedAt'];
    final windowMs = (d['escalateAfterMs'] as num?)?.toInt() ?? 120000;
    if (nt is Timestamp) {
      final elapsed = DateTime.now().difference(nt.toDate()).inMilliseconds;
      _secondsLeft = ((windowMs - elapsed) / 1000).ceil().clamp(0, 999);
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _acting = true);
    try {
      final incId = widget.assignmentDoc.id;
      final hospId = widget.hospitalIds.first;
      await FirebaseFunctions.instanceFor(region: 'us-east1')
          .httpsCallable('acceptHospitalDispatch')
          .call({'incidentId': incId, 'hospitalId': hospId});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accept failed: $e'), backgroundColor: AppColors.primaryDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _refer() async {
    setState(() => _acting = true);
    try {
      final incId = widget.assignmentDoc.id;
      final hospId = widget.hospitalIds.first;
      await FirebaseFunctions.instanceFor(region: 'us-east1')
          .httpsCallable('declineHospitalDispatch')
          .call({'incidentId': incId, 'hospitalId': hospId});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refer failed: $e'), backgroundColor: AppColors.primaryDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.assignmentDoc.data();
    final incId = widget.assignmentDoc.id;
    final reqSvc = (d['requiredServices'] as List?)?.map((e) => e.toString()).join(', ') ?? '—';
    final mins = _secondsLeft ~/ 60;
    final secs = _secondsLeft % 60;
    final countdown = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final borderColor = Color.lerp(
          AppColors.primaryDanger,
          Colors.orangeAccent,
          _pulse.value,
        )!;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryDanger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 2.5),
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.primaryDanger, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'INCOMING EMERGENCY',
                  style: TextStyle(
                    color: AppColors.primaryDanger,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _secondsLeft <= 30
                      ? AppColors.primaryDanger.withValues(alpha: 0.3)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  countdown,
                  style: TextStyle(
                    color: _secondsLeft <= 30 ? AppColors.primaryDanger : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Incident: ${incId.length > 20 ? '${incId.substring(0, 18)}...' : incId}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Required services: $reqSvc',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _acting ? null : _accept,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.w900)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _acting ? null : _refer,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('REFER', style: TextStyle(fontWeight: FontWeight.w900)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows only accepted consignment assignments for this hospital.
class _AcceptedConsignmentSection extends StatelessWidget {
  const _AcceptedConsignmentSection({required this.hospitalIds});
  final List<String> hospitalIds;

  @override
  Widget build(BuildContext context) {
    if (hospitalIds.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ops_incident_hospital_assignments')
          .where('acceptedHospitalId', whereIn: hospitalIds.take(10).toList())
          .where('dispatchStatus', isEqualTo: 'accepted')
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'No active consignments for ${hospitalIds.length == 1 ? "this hospital" : "these hospitals"}.',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Active consignments',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...docs.take(8).map((doc) {
              final d = doc.data();
              final incId = doc.id;
              final hospName = (d['acceptedHospitalName'] as String?)?.trim() ?? '—';
              final acceptedAt = d['acceptedAt'];
              String acceptedLabel = '';
              if (acceptedAt is Timestamp) {
                acceptedLabel = DateFormat.MMMd().add_Hm().format(acceptedAt.toDate().toLocal());
              }
              final reqSvc = (d['requiredServices'] as List?)
                      ?.map((e) => e.toString())
                      .join(', ') ??
                  '';
              final ambStatus = (d['ambulanceDispatchStatus'] as String?)?.replaceAll('_', ' ') ?? '';
              return Card(
                color: AppColors.slate800,
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACCEPTED',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Incident: ${incId.length > 16 ? '${incId.substring(0, 14)}...' : incId}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Hospital: $hospName', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      if (reqSvc.isNotEmpty)
                        Text('Services: $reqSvc', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      if (ambStatus.isNotEmpty)
                        Text('Ambulance: $ambStatus', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      if (acceptedLabel.isNotEmpty)
                        Text('Accepted: $acceptedLabel', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
