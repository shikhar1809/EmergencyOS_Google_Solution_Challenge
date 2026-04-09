import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/india_ops_zones.dart';

/// EmergencyOS: OpsCommandZonePrefs in lib/services/ops_command_zone_prefs.dart.
abstract final class OpsCommandZonePrefs {
  static const _kZoneId = 'ops_command_zone_id_v1';

  static Future<IndiaOpsZone> loadZone() async {
    // Product phase: maps and analytics are locked to Lucknow only.
    return IndiaOpsZones.lucknow;
  }

  static Future<void> saveZoneId([String? _]) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kZoneId, IndiaOpsZones.lucknowZoneId);
  }
}
