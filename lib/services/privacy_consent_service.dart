import 'package:shared_preferences/shared_preferences.dart';

/// Tracks opt-in for emergency data handling before first real SOS.
class PrivacyConsentService {
  static const _key = 'emergency_data_consent_v2';

  static Future<bool> hasAccepted() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setAccepted(bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key, v);
    } catch (_) {}
  }
}
