// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

@JS('startVictimRecording')
external void _jsStartVictimRecording();

@JS('stopVictimRecording')
external void _jsStopVictimRecording();

@JS('_victimLastAudioB64')
external set _jsVictimLastAudioB64(JSString? value);

@JS('_victimLastAudioB64')
external JSString? get _jsVictimLastAudioB64;

void victimRecordingStart() {
  try {
    _jsStartVictimRecording();
  } catch (_) {}
}

void victimRecordingStop() {
  try {
    _jsStopVictimRecording();
  } catch (_) {}
}

void victimRecordingClearB64() {
  try {
    _jsVictimLastAudioB64 = null;
  } catch (_) {}
}

String? victimRecordingReadB64() {
  try {
    return _jsVictimLastAudioB64?.toDart;
  } catch (_) {
    return null;
  }
}
