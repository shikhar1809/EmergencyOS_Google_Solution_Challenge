// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

@JS('startEmergencyAlarm')
external void _jsStartEmergencyAlarm();

@JS('stopEmergencyAlarm')
external void _jsStopEmergencyAlarm();

void emergencyAlarmStart() {
  try {
    _jsStartEmergencyAlarm();
  } catch (_) {}
}

void emergencyAlarmStop() {
  try {
    _jsStopEmergencyAlarm();
  } catch (_) {}
}
