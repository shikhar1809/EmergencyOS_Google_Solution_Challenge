import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/india_ops_zones.dart';
import '../../../../core/constants/volunteer_xp_rewards.dart';
import '../../../../services/master_xp_tuning_service.dart';
import '../../../../services/observatory_master_reset_service.dart';
import '../../domain/admin_panel_access.dart';
import '../../../ai_assist/domain/lifeline_training_levels.dart';

/// Master-only tab inside Lucknow Observatory: data purge, leaderboard, XP tuning, user overrides.
class ObservatoryMasterControlsTab extends StatefulWidget {
  const ObservatoryMasterControlsTab({super.key, required this.accent});

  final Color accent;

  @override
  State<ObservatoryMasterControlsTab> createState() =>
      _ObservatoryMasterControlsTabState();
}

class _ObservatoryMasterControlsTabState
    extends State<ObservatoryMasterControlsTab> {
  bool _tuningLoading = true;
  String? _tuningErr;

  final _acceptCtrl = TextEditingController();
  final _checklistCtrl = TextEditingController();
  final _resolvedCtrl = TextEditingController();
  final _falseAlarmCtrl = TextEditingController();
  bool _savingTuning = false;

  final _uidCtrl = TextEditingController();
  final _uxpCtrl = TextEditingController();
  final _livesCtrl = TextEditingController();
  final _levelsCtrl = TextEditingController();
  bool _applyingUser = false;

  final Map<int, TextEditingController> _lifelineCtrls = {};

  @override
  void initState() {
    super.initState();
    for (final lv in kLifelineTrainingLevels) {
      _lifelineCtrls[lv.id] = TextEditingController();
    }
    unawaited(_reloadTuning());
  }

  @override
  void dispose() {
    _acceptCtrl.dispose();
    _checklistCtrl.dispose();
    _resolvedCtrl.dispose();
    _falseAlarmCtrl.dispose();
    _uidCtrl.dispose();
    _uxpCtrl.dispose();
    _livesCtrl.dispose();
    _levelsCtrl.dispose();
    for (final c in _lifelineCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _reloadTuning() async {
    setState(() {
      _tuningLoading = true;
      _tuningErr = null;
    });
    try {
      final s = await MasterXpTuningService.load(force: true);
      if (!mounted) return;
      setState(() {
        _acceptCtrl.text = '${s.xpAcceptIncident}';
        _checklistCtrl.text = '${s.xpOnSceneChecklist}';
        _resolvedCtrl.text = '${s.xpVictimMarkedResolved}';
        _falseAlarmCtrl.text = '${s.xpFalseAlarmClosure}';
        for (final lv in kLifelineTrainingLevels) {
          final o = s.lifelineXpByLevel[lv.id];
          _lifelineCtrls[lv.id]!.text = o != null ? '$o' : '';
        }
        _tuningLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tuningErr = '$e';
        _tuningLoading = false;
      });
    }
  }

  Future<bool> _confirmPhrase(
    String title,
    String body,
    String exactPhrase,
  ) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Type exactly: $exactPhrase',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: exactPhrase,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () =>
                Navigator.pop(ctx, ctrl.text.trim() == exactPhrase),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return ok == true;
  }

  Future<void> _runDanger(Future<void> Function() op) async {
    if (!ObservatoryMasterResetService.isMasterConsoleSignedIn) {
      _toast(
        'Sign in as ${AdminPanelAccess.masterConsoleEmail} in Firebase Auth.',
      );
      return;
    }
    try {
      await op();
    } catch (e) {
      if (mounted) _toast('Error: $e');
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _saveTuning() async {
    if (!ObservatoryMasterResetService.isMasterConsoleSignedIn) {
      _toast('Master email sign-in required.');
      return;
    }
    int p(TextEditingController c, int fallback) {
      final v = int.tryParse(c.text.trim());
      return v != null && v >= 0 ? v : fallback;
    }

    final lifeline = <int, int>{};
    for (final lv in kLifelineTrainingLevels) {
      final t = _lifelineCtrls[lv.id]!.text.trim();
      if (t.isEmpty) continue;
      final n = int.tryParse(t);
      if (n != null && n >= 0) lifeline[lv.id] = n;
    }

    setState(() => _savingTuning = true);
    try {
      final snap = MasterXpTuningSnapshot(
        xpAcceptIncident: p(_acceptCtrl, VolunteerXpRewards.acceptIncident),
        xpOnSceneChecklist: p(
          _checklistCtrl,
          VolunteerXpRewards.onSceneChecklist,
        ),
        xpVictimMarkedResolved: p(
          _resolvedCtrl,
          VolunteerXpRewards.victimMarkedResolved,
        ),
        xpFalseAlarmClosure: p(
          _falseAlarmCtrl,
          VolunteerXpRewards.falseAlarmClosure,
        ),
        lifelineXpByLevel: lifeline,
      );
      await MasterXpTuningService.save(snap);
      if (!mounted) return;
      setState(() => _savingTuning = false);
      _toast('XP tuning saved to Firestore.');
    } catch (e) {
      if (mounted) setState(() => _savingTuning = false);
      _toast('Save failed: $e');
    }
  }

  Future<void> _resetTuningDefaults() async {
    if (!ObservatoryMasterResetService.isMasterConsoleSignedIn) return;
    setState(() => _savingTuning = true);
    try {
      await MasterXpTuningService.save(MasterXpTuningSnapshot.defaults);
      MasterXpTuningService.invalidateCache();
      await _reloadTuning();
      if (mounted) setState(() => _savingTuning = false);
      _toast('Reset to code defaults (empty Lifeline overrides).');
    } catch (e) {
      if (mounted) setState(() => _savingTuning = false);
      _toast('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = ObservatoryMasterResetService.isMasterConsoleSignedIn;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Master access',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ok
                            ? 'Signed in as ${AdminPanelAccess.masterConsoleEmail}. Firestore rules gate destructive actions to this email.'
                            : 'You need Firebase Auth with email ${AdminPanelAccess.masterConsoleEmail} to run resets or save tuning.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent.shade200,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Danger zone — Lucknow mesh',
                              style: TextStyle(
                                color: a,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Deletes active + archived incidents whose victim pin lies inside the Lucknow ops radius '
                        '(same filter as the observatory overview). Also removes matching hospital assignment docs.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: !ok
                            ? null
                            : () async {
                                if (!await _confirmPhrase(
                                  'Purge Lucknow-zone incidents',
                                  'This removes scoped SOS rows from sos_incidents and sos_incidents_archive. '
                                      'Subcollections under active incidents are deleted first.',
                                  'RESET LUCKNOW',
                                )) {
                                  return;
                                }
                                await _runDanger(() async {
                                  final r =
                                      await ObservatoryMasterResetService.purgeIncidentsForZone(
                                        IndiaOpsZones.lucknow,
                                      );
                                  if (mounted) {
                                    _toast(
                                      'Removed ${r.activeDeleted} active, ${r.archiveDeleted} archive (zone).',
                                    );
                                  }
                                });
                              },
                        icon: const Icon(
                          Icons.delete_forever_rounded,
                          size: 18,
                        ),
                        label: const Text('Delete Lucknow-zone live + archive'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global collections',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No geo filter — every document in the collection.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: !ok
                                ? null
                                : () async {
                                    if (!await _confirmPhrase(
                                      'Delete ALL active SOS',
                                      'Iterates the entire sos_incidents collection and removes each doc '
                                          '(including audit_log and victim_activity).',
                                      'DELETE ALL ACTIVE SOS',
                                    )) {
                                      return;
                                    }
                                    await _runDanger(() async {
                                      final n =
                                          await ObservatoryMasterResetService.purgeEntireCollection(
                                            'sos_incidents',
                                          );
                                      if (mounted)
                                        _toast(
                                          'Deleted $n active incident documents.',
                                        );
                                    });
                                  },
                            child: const Text('All active SOS'),
                          ),
                          OutlinedButton(
                            onPressed: !ok
                                ? null
                                : () async {
                                    if (!await _confirmPhrase(
                                      'Delete ALL archive',
                                      'Iterates sos_incidents_archive and deletes every archived incident.',
                                      'DELETE ALL ARCHIVE',
                                    )) {
                                      return;
                                    }
                                    await _runDanger(() async {
                                      final n =
                                          await ObservatoryMasterResetService.purgeEntireCollection(
                                            'sos_incidents_archive',
                                          );
                                      if (mounted)
                                        _toast('Deleted $n archive documents.');
                                    });
                                  },
                            child: const Text('All archive'),
                          ),
                          OutlinedButton(
                            onPressed: !ok
                                ? null
                                : () async {
                                    if (!await _confirmPhrase(
                                      'Clear leaderboard',
                                      'Deletes every document in leaderboard/. Does not change users/.',
                                      'CLEAR LEADERBOARD',
                                    )) {
                                      return;
                                    }
                                    await _runDanger(() async {
                                      final n =
                                          await ObservatoryMasterResetService.clearLeaderboard();
                                      if (mounted)
                                        _toast('Removed $n leaderboard rows.');
                                    });
                                  },
                            child: const Text('Clear leaderboard'),
                          ),
                          OutlinedButton(
                            onPressed: !ok
                                ? null
                                : () async {
                                    if (!await _confirmPhrase(
                                      'Clear auxiliary ops data',
                                      'Deletes incident_feedback and green_zone_requests collections.',
                                      'CLEAR AUX OPS',
                                    )) {
                                      return;
                                    }
                                    await _runDanger(() async {
                                      final r =
                                          await ObservatoryMasterResetService.purgeAuxiliaryOpsData();
                                      if (mounted) {
                                        _toast(
                                          'Feedback ${r.feedbackDeleted}, green-zone ${r.greenZoneRequestsDeleted}.',
                                        );
                                      }
                                    });
                                  },
                            child: const Text('Clear feedback + green-zone'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOS XP rewards',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stored at ops_master_tuning/xp_rewards. Clients read before awarding XP.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10,
                        ),
                      ),
                      if (_tuningLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      else if (_tuningErr != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _tuningErr!,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 12),
                        _numRow('Accept incident', _acceptCtrl),
                        _numRow('On-scene checklist', _checklistCtrl),
                        _numRow('Victim resolved closure', _resolvedCtrl),
                        _numRow('False alarm / cancelled', _falseAlarmCtrl),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: !ok || _savingTuning
                                  ? null
                                  : _saveTuning,
                              icon: _savingTuning
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: const Text('Save SOS XP'),
                              style: FilledButton.styleFrom(
                                backgroundColor: a.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: !ok || _savingTuning
                                  ? null
                                  : _resetTuningDefaults,
                              child: const Text('Reset defaults'),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Reload from Firestore',
                              onPressed: _tuningLoading
                                  ? null
                                  : () => unawaited(_reloadTuning()),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lifeline level XP overrides',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Leave blank to use the built-in value from each level. Non-empty values are saved to Firestore.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...kLifelineTrainingLevels.map((lv) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '#${lv.id}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  lv.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 72,
                                child: Text(
                                  'def ${lv.xpReward}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _lifelineCtrls[lv.id],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'override',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white.withValues(
                                      alpha: 0.06,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User gamification (by UID)',
                        style: TextStyle(
                          color: a,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sets volunteerXp, volunteerLivesSaved, lifelineLevelsCleared on users/{uid}. '
                        'If a leaderboard row exists for that uid, it is updated to match XP/lives.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _uidCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDeco('User UID'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _uxpCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDeco('Volunteer XP'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _livesCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDeco('Lives saved'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _levelsCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDeco('Lifeline levels cleared'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: !ok || _applyingUser
                            ? null
                            : () async {
                                final uid = _uidCtrl.text.trim();
                                if (uid.isEmpty) {
                                  _toast('Enter a UID.');
                                  return;
                                }
                                final xp =
                                    int.tryParse(_uxpCtrl.text.trim()) ?? 0;
                                final lives =
                                    int.tryParse(_livesCtrl.text.trim()) ?? 0;
                                final lv =
                                    int.tryParse(_levelsCtrl.text.trim()) ?? 0;
                                setState(() => _applyingUser = true);
                                try {
                                  await ObservatoryMasterResetService.applyUserGamification(
                                    uid: uid,
                                    volunteerXp: xp < 0 ? 0 : xp,
                                    volunteerLivesSaved: lives < 0 ? 0 : lives,
                                    lifelineLevelsCleared: lv.clamp(
                                      0,
                                      kLifelineTrainingLevels.length,
                                    ),
                                  );
                                  if (mounted) _toast('Updated user $uid');
                                } catch (e) {
                                  if (mounted) _toast('$e');
                                } finally {
                                  if (mounted)
                                    setState(() => _applyingUser = false);
                                }
                              },
                        icon: _applyingUser
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.person_pin_rounded, size: 18),
                        label: const Text('Apply to Firestore'),
                        style: FilledButton.styleFrom(
                          backgroundColor: a.withValues(alpha: 0.75),
                        ),
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

  InputDecoration _fieldDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    isDense: true,
  );

  Widget _numRow(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: c,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
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
}
