import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/staff/domain/admin_panel_access.dart';

/// Persists ops dashboard role + hospital binding (demo codes, client-side).
abstract final class AdminPanelSessionService {
  static const _kRole = 'admin_panel_role_v1';
  static const _kHospital = 'admin_panel_hospital_id_v1';

  static String _roleToStorage(AdminConsoleRole r) => r.name;

  static AdminConsoleRole? _roleFromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final e in AdminConsoleRole.values) {
      if (e.name == raw) return e;
    }
    return null;
  }

  static Future<AdminPanelAccess?> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final role = _roleFromStorage(p.getString(_kRole));
      if (role == null) return null;
      return AdminPanelAccess(
        role: role,
        boundHospitalDocId: p.getString(_kHospital),
      );
    } catch (e) {
      debugPrint('[AdminPanelSession] load: $e');
      return null;
    }
  }

  static Future<void> save(AdminPanelAccess access) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kRole, _roleToStorage(access.role));
      await _setOrRemove(p, _kHospital, access.boundHospitalDocId);
    } catch (e) {
      debugPrint('[AdminPanelSession] save: $e');
    }
  }

  static Future<void> _setOrRemove(SharedPreferences p, String key, String? value) async {
    final v = value?.trim();
    if (v == null || v.isEmpty) {
      await p.remove(key);
    } else {
      await p.setString(key, v);
    }
  }

  static Future<void> clear() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kRole);
      await p.remove(_kHospital);
    } catch (e) {
      debugPrint('[AdminPanelSession] clear: $e');
    }
  }
}
