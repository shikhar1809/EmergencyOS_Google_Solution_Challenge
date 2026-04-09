import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/volunteer_xp_rewards.dart';
import '../features/staff/domain/admin_panel_access.dart';

/// Remote XP rewards for SOS + Lifeline (`ops_master_tuning/xp_rewards`).
/// Readable by any signed-in client; writable only by master console (Firestore rules).
class MasterXpTuningService {
  MasterXpTuningService._();
  static const _docPath = 'ops_master_tuning/xp_rewards';

  static final _db = FirebaseFirestore.instance;
  static MasterXpTuningSnapshot? _cache;
  static DateTime? _cacheAt;
  static const _ttl = Duration(seconds: 45);

  static void invalidateCache() {
    _cache = null;
    _cacheAt = null;
  }

  static bool get _isMasterEmail {
    final e = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
    return e == AdminPanelAccess.masterConsoleEmail.toLowerCase();
  }

  static Future<MasterXpTuningSnapshot> load({bool force = false}) async {
    if (!force &&
        _cache != null &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _ttl) {
      return _cache!;
    }
    try {
      final snap = await _db.doc(_docPath).get();
      final d = snap.data();
      if (d == null || d.isEmpty) {
        _cache = MasterXpTuningSnapshot.defaults;
        _cacheAt = DateTime.now();
        return _cache!;
      }
      _cache = MasterXpTuningSnapshot.fromMap(d);
      _cacheAt = DateTime.now();
      return _cache!;
    } catch (e) {
      debugPrint('[MasterXpTuningService] load: $e');
      _cache = MasterXpTuningSnapshot.defaults;
      _cacheAt = DateTime.now();
      return _cache!;
    }
  }

  static Future<int> xpAcceptIncident() async {
    final s = await load();
    return s.xpAcceptIncident;
  }

  static Future<int> xpOnSceneChecklist() async {
    final s = await load();
    return s.xpOnSceneChecklist;
  }

  static Future<int> xpVictimMarkedResolved() async {
    final s = await load();
    return s.xpVictimMarkedResolved;
  }

  static Future<int> xpFalseAlarmClosure() async {
    final s = await load();
    return s.xpFalseAlarmClosure;
  }

  /// Effective Lifeline reward for [levelId] (1-based), using Firestore overrides when set.
  static Future<int> lifelineXpForLevel(int levelId, int codeDefault) async {
    final s = await load();
    return s.lifelineXpForLevel(levelId, codeDefault);
  }

  static Future<void> save(MasterXpTuningSnapshot snap) async {
    if (!_isMasterEmail) {
      throw StateError('Master console email required to save XP tuning.');
    }
    // Replace whole doc so cleared Lifeline overrides remove old map keys.
    await _db.doc(_docPath).set(snap.toMap());
    invalidateCache();
  }
}

class MasterXpTuningSnapshot {
  const MasterXpTuningSnapshot({
    required this.xpAcceptIncident,
    required this.xpOnSceneChecklist,
    required this.xpVictimMarkedResolved,
    required this.xpFalseAlarmClosure,
    required this.lifelineXpByLevel,
  });

  final int xpAcceptIncident;
  final int xpOnSceneChecklist;
  final int xpVictimMarkedResolved;
  final int xpFalseAlarmClosure;
  /// Level id (1-based) → XP override. Absent keys use app defaults per level.
  final Map<int, int> lifelineXpByLevel;

  static MasterXpTuningSnapshot get defaults => MasterXpTuningSnapshot(
        xpAcceptIncident: VolunteerXpRewards.acceptIncident,
        xpOnSceneChecklist: VolunteerXpRewards.onSceneChecklist,
        xpVictimMarkedResolved: VolunteerXpRewards.victimMarkedResolved,
        xpFalseAlarmClosure: VolunteerXpRewards.falseAlarmClosure,
        lifelineXpByLevel: const {},
      );

  int lifelineXpForLevel(int levelId, int codeDefault) {
    final o = lifelineXpByLevel[levelId];
    if (o != null && o >= 0) return o;
    return codeDefault;
  }

  factory MasterXpTuningSnapshot.fromMap(Map<String, dynamic> m) {
    int g(String k, int d) {
      final v = m[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return d;
    }

    final raw = m['lifelineXpByLevel'];
    final map = <int, int>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        final id = int.tryParse(e.key.toString());
        final val = e.value;
        if (id != null && id > 0) {
          if (val is int) map[id] = val;
          if (val is num) map[id] = val.toInt();
        }
      }
    }

    return MasterXpTuningSnapshot(
      xpAcceptIncident: g('xpAcceptIncident', VolunteerXpRewards.acceptIncident),
      xpOnSceneChecklist: g('xpOnSceneChecklist', VolunteerXpRewards.onSceneChecklist),
      xpVictimMarkedResolved: g('xpVictimMarkedResolved', VolunteerXpRewards.victimMarkedResolved),
      xpFalseAlarmClosure: g('xpFalseAlarmClosure', VolunteerXpRewards.falseAlarmClosure),
      lifelineXpByLevel: map,
    );
  }

  Map<String, dynamic> toMap() => {
        'xpAcceptIncident': xpAcceptIncident,
        'xpOnSceneChecklist': xpOnSceneChecklist,
        'xpVictimMarkedResolved': xpVictimMarkedResolved,
        'xpFalseAlarmClosure': xpFalseAlarmClosure,
        'lifelineXpByLevel': {
          for (final e in lifelineXpByLevel.entries) '${e.key}': e.value,
        },
      };
}
