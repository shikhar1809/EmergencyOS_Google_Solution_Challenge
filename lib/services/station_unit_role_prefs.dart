import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/station_unit_role.dart';

/// EmergencyOS: StationUnitRolePrefs in lib/services/station_unit_role_prefs.dart.
abstract final class StationUnitRolePrefs {
  static const _key = 'station_unit_role_v1';

  static Future<StationUnitRole?> load() async {
    final p = await SharedPreferences.getInstance();
    return stationUnitRoleFromStorage(p.getString(_key));
  }

  static Future<void> save(StationUnitRole role) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, role.name);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
