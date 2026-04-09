import 'dart:js_interop';

@JS('playPttAudio')
external void _jsPlayPttAudio(JSString? b64, JSString? mimeHint);

Future<void> playPttVoiceClipBase64(String? base64, {String? mimeType}) async {
  if (base64 == null || base64.isEmpty) return;
  try {
    _jsPlayPttAudio(base64.toJS, mimeType?.toJS);
  } catch (_) {}
}
