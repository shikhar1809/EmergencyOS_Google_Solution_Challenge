import 'ptt_voice_playback_stub.dart'
    if (dart.library.html) 'ptt_voice_playback_web.dart'
    if (dart.library.io) 'ptt_voice_playback_io.dart' as impl;

/// Plays a PTT voice clip stored as base64 (WebM/Opus or AAC/MP4 from MediaRecorder).
Future<void> playPttVoiceClipBase64(String? base64, {String? mimeType}) =>
    impl.playPttVoiceClipBase64(base64, mimeType: mimeType);
