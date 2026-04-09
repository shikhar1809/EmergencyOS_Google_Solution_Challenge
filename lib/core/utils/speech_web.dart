import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

extension WindowExtension on web.Window {
  @JS('_speechOnResult')
  external set speechOnResult(JSFunction? value);

  @JS('_speechOnEnd')
  external set speechOnEnd(JSFunction? value);

  @JS('_speechOnError')
  external set speechOnError(JSFunction? value);

  @JS('_speechOnSound')
  external set speechOnSound(JSFunction? value);

  @JS('startSpeech')
  external void startSpeech(JSString lang);

  @JS('stopSpeech')
  external void stopSpeech();

  // ── New robust audio engine API (v2) ──────────────────────────────────────

  /// Speak [text] in [lang]; call [doneCb] when done (or on watchdog timeout).
  @JS('eosSpeak')
  external void eosSpeak(JSString text, JSString lang, JSFunction? doneCb);

  /// Cancel any in-flight TTS; fires pending doneCb immediately.
  @JS('eosCancelSpeak')
  external void eosCancelSpeak();

  /// Resume AudioContext + unlock speechSynthesis (call from user gesture).
  @JS('eosPrimeAudio')
  external void eosPrimeAudio();

  /// Bank a user-gesture token so async TTS calls can still play.
  @JS('bankUserGesture')
  external void bankUserGesture();

  // ── Legacy shims still referenced by old call-sites ────────────────────

  @JS('speakTextImpl')
  external void jsSpeakTextImpl(JSString text, JSString lang);

  @JS('cancelSpeechText')
  external void jsCancelSpeechText();

  @JS('resumeAudioForSpeech')
  external void resumeAudioForSpeech(JSFunction run);

  @JS('unlockWebSpeechSynthesis')
  external void unlockWebSpeechSynthesis();
}

bool speechSupported() => true;

void startListening(
  String languageCode,
  void Function(String) onResult,
  void Function() onEnd,
  void Function(String) onError,
  void Function() onSoundDetected,
) {
  unawaited(_startWebListeningAsync(
    languageCode,
    onResult,
    onEnd,
    onError,
    onSoundDetected,
  ));
}

Future<void> _startWebListeningAsync(
  String languageCode,
  void Function(String) onResult,
  void Function() onEnd,
  void Function(String) onError,
  void Function() onSoundDetected,
) async {
  cancelSpeechText();
  await Future<void>.delayed(const Duration(milliseconds: 140));
  try {
    web.window.speechOnResult = onResult.toJS;
    web.window.speechOnEnd = onEnd.toJS;
    web.window.speechOnError = onError.toJS;
    web.window.speechOnSound = onSoundDetected.toJS;
    web.window.startSpeech((languageCode.isEmpty ? 'en-IN' : languageCode).toJS);
  } catch (e) {
    // ignore: avoid_print
    debugPrint('startListening FAILED: $e');
    onError(e.toString());
    onEnd();
  }
}

void stopListening() {
  try {
    web.window.stopSpeech();
  } catch (e) {
    // ignore: avoid_print
    debugPrint('stopListening FAILED: $e');
  }
}

/// Core TTS: uses robust [eosSpeak] which handles AudioContext resume,
/// voice selection, and the self-healing watchdog timer internally.
void speakText(String text, {String lang = 'en-IN', void Function()? onDone}) {
  try {
    web.window.eosSpeak(
      text.toJS,
      lang.toJS,
      onDone != null ? onDone.toJS : null,
    );
  } catch (_) {
    // Fallback to legacy path if new JS API isn't available yet
    try {
      web.window.resumeAudioForSpeech((() {
        try {
          web.window.jsSpeakTextImpl(text.toJS, lang.toJS);
        } catch (_) {
          if (onDone != null) onDone();
        }
      }).toJS);
    } catch (_) {
      if (onDone != null) onDone();
    }
  }
}

void cancelSpeechText() {
  try {
    web.window.eosCancelSpeak();
  } catch (_) {
    try {
      web.window.jsCancelSpeechText();
    } catch (e) {
      // ignore: avoid_print
      debugPrint('cancelSpeechText FAILED: $e');
    }
  }
}

/// Web autoplay policy: call from a user gesture before the first TTS.
/// [eosPrimeAudio] handles both AudioContext resume and speechSynthesis
/// unlock in a single synchronous call — critical for Safari/Chrome.
void primeSpeechAudioContext() {
  try {
    web.window.eosPrimeAudio();
  } catch (_) {
    try {
      web.window.resumeAudioForSpeech((() {}).toJS);
      web.window.unlockWebSpeechSynthesis();
    } catch (_) {}
  }
}
