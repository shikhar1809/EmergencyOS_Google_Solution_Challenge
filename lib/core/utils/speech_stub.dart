// Stub for non-web platforms — all speech functions are no-ops.
// On web, speech_web.dart is used instead via conditional import.

bool speechSupported() => false;

void startListening(String languageCode, void Function(String) onResult, void Function() onEnd, void Function(String) onError, void Function() onSoundDetected) {
  onEnd();
}

void stopListening() {}

void speakText(String text, {String lang = 'en-IN', Function? onDone}) {
  if (onDone != null) onDone();
}

void cancelSpeechText() {}

void primeSpeechAudioContext() {}

bool isMobileWebBrowser() => false;

bool hasLocalVoiceFor(String bcp47) => true;
