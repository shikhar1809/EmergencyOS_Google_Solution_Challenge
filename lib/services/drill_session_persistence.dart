import 'package:shared_preferences/shared_preferences.dart';

/// Persists an explicit drill-from-login session so cold start and shell logic
/// do not resume live SOS/volunteer flows or show real incoming alerts.
class DrillSessionPersistence {
  static const prefKeyActive = 'drill_session_active';
  static const prefKeyVictimPractice = 'drill_session_victim_practice';

  static Future<void> activate({required bool victimPractice}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(prefKeyActive, true);
    await p.setBool(prefKeyVictimPractice, victimPractice);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(prefKeyActive);
    await p.remove(prefKeyVictimPractice);
  }

  static Future<bool> isActive() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(prefKeyActive) ?? false;
  }

  static Future<bool> loadVictimPractice() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(prefKeyVictimPractice) ?? false;
  }
}
