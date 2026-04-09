import 'package:shared_preferences/shared_preferences.dart';

/// Arms the main shell to run the home walkthrough after `context.go('/dashboard')`
/// from the login drill buttons only.
///
/// Drill-from-login chrome uses [drillSessionDashboardDemoProvider]; synthetic Home stats
/// only apply on `/drill/dashboard` (see [DashboardScreen.isDrillShell]).
class DrillEntryService {
  static const _key = 'drill_shell_entry_mode';
  /// Legacy SharedPreferences key from older builds (cleared on startup).
  static const legacyDemoDashKey = 'drill_dashboard_demo';

  /// [mode] is `sos` (victim practice) or `volunteer`.
  static Future<void> arm(String mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, mode);
  }

  /// One-time: remove stale pref so older builds never show demo after normal login.
  static Future<void> clearLegacyDashboardDemoPreference() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(legacyDemoDashKey);
  }

  /// Returns armed mode and clears it (one-shot).
  static Future<String?> takeArmedMode() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_key);
    if (v != null && v.isNotEmpty) {
      await p.remove(_key);
      return v;
    }
    return null;
  }

  /// Clears any armed walkthrough without consuming it (e.g. exit drill).
  static Future<void> clearArmedMode() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
