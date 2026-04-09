// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

@JS('startPttRecording')
external void _jsStartPttRecording();

@JS('stopPttRecording')
external void _jsStopPttRecording();

@JS('_pttLastAudioB64')
external set _jsPttLastAudioB64(JSString? value);

@JS('_pttLastAudioB64')
external JSString? get _jsPttLastAudioB64;

@JS('_pttLastMime')
external JSString? get _jsPttLastMime;

void pttRecordingStart() {
  try {
    _jsStartPttRecording();
  } catch (_) {}
}

void pttRecordingStop() {
  try {
    _jsStopPttRecording();
  } catch (_) {}
}

void pttRecordingClearB64() {
  try {
    _jsPttLastAudioB64 = null;
  } catch (_) {}
}

String? pttRecordingReadB64() {
  try {
    return _jsPttLastAudioB64?.toDart;
  } catch (_) {
    return null;
  }
}

String? pttRecordingReadMime() {
  try {
    return _jsPttLastMime?.toDart;
  } catch (_) {
    return null;
  }
}
