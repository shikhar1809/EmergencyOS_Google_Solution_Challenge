import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last SOS created while offline / flaky so UI can explain sync state.
class OfflineSosStatusService {
  static const _idKey = 'offline_sos_pending_id_v1';
  static const _atKey = 'offline_sos_pending_at_v1';

  static Future<void> markPendingIfOffline({
    required String incidentId,
    required bool likelyOffline,
  }) async {
    if (!likelyOffline || incidentId.trim().isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_idKey, incidentId.trim());
      await p.setString(_atKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('[OfflineSosStatus] mark: $e');
    }
  }

  static Future<void> clearPending() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_idKey);
      await p.remove(_atKey);
    } catch (_) {}
  }

  static Future<(String? id, DateTime? at)> peekPending() async {
    try {
      final p = await SharedPreferences.getInstance();
      final id = p.getString(_idKey)?.trim();
      final raw = p.getString(_atKey);
      if (id == null || id.isEmpty) return (null, null);
      final at = DateTime.tryParse(raw ?? '');
      return (id, at);
    } catch (_) {
      return (null, null);
    }
  }
}
