import 'package:shared_preferences/shared_preferences.dart';

/// Fleet call-sign session after gate verification (Lucknow ops demo).
abstract final class FleetOperatorSession {
  static const _kFleetId = 'fleet_operator_fleet_id_v1';
  static const _kVerified = 'fleet_operator_verified_v1';
  static const _kOnDuty = 'fleet_operator_on_duty_v1';
  static const _kVehicleType = 'fleet_operator_vehicle_type_v1';

  static String? _fleetId;
  static bool _verified = false;
  static bool _onDuty = false;
  static String? _vehicleType;

  static String? get fleetId => _fleetId;

  /// Firestore `ops_fleet_accounts` vehicleType after gate verify (`medical`, `crane`, …).
  static String? get vehicleType => _vehicleType;

  static bool get isVerified =>
      _verified && _fleetId != null && _fleetId!.trim().isNotEmpty;

  static bool get isOnDuty => _onDuty;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _fleetId = p.getString(_kFleetId);
    _verified = p.getBool(_kVerified) ?? false;
    _onDuty = p.getBool(_kOnDuty) ?? false;
    _vehicleType = p.getString(_kVehicleType);
  }

  static Future<void> setVerifiedFleet(String fleetId, {String? vehicleType}) async {
    final id = fleetId.trim();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kFleetId, id);
    await p.setBool(_kVerified, true);
    await p.setBool(_kOnDuty, false);
    if (vehicleType != null && vehicleType.trim().isNotEmpty) {
      await p.setString(_kVehicleType, vehicleType.trim().toLowerCase());
      _vehicleType = vehicleType.trim().toLowerCase();
    } else {
      await p.remove(_kVehicleType);
      _vehicleType = null;
    }
    _fleetId = id;
    _verified = true;
    _onDuty = false;
  }

  static Future<void> setOnDuty(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnDuty, v);
    _onDuty = v;
  }

  static Future<void> clearVerified() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kFleetId);
    await p.remove(_kVehicleType);
    await p.setBool(_kVerified, false);
    await p.setBool(_kOnDuty, false);
    _fleetId = null;
    _verified = false;
    _onDuty = false;
    _vehicleType = null;
  }
}
