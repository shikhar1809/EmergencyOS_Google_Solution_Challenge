// iOS / Android / desktop (IO) — speech recognition + TTS for SOS voice QA and comms.
// Web uses speech_web.dart via conditional import.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

final SpeechToText _stt = SpeechToText();
final FlutterTts _tts = FlutterTts();

bool _sttInited = false;
bool _ttsInited = false;
bool _listenSession = false;
VoidCallback? _pendingListenEnd;

bool speechSupported() => true;

Future<bool> _ensureStt() async {
  if (_sttInited) return _stt.isAvailable;
  _sttInited = true;
  final ok = await _stt.initialize(
    onError: (e) => debugPrint('[speech_io] stt ${e.errorMsg}'),
    onStatus: (status) {
      if (!_listenSession || _pendingListenEnd == null) return;
      if (status == SpeechToText.doneStatus ||
          status == SpeechToText.notListeningStatus) {
        final done = _pendingListenEnd!;
        _pendingListenEnd = null;
        _listenSession = false;
        done();
      }
    },
  );
  return ok;
}

Future<void> _ensureTts() async {
  if (_ttsInited) return;
  _ttsInited = true;
  try {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playAndRecord,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.duckOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.45);
  } catch (e) {
    debugPrint('[speech_io] tts init: $e');
  }
}

/// speech_to_text expects e.g. en_IN; we get BCP-47 from the app (en-IN).
String? _localeIdForListen(String bcp47) {
  final t = bcp47.trim();
  if (t.isEmpty) return null;
  final parts = t.replaceAll('_', '-').split('-');
  if (parts.length >= 2) {
    return '${parts[0]}_${parts[1].toUpperCase()}';
  }
  return '${parts[0]}_${parts[0].toUpperCase()}';
}

/// Prefer a locale the engine actually has (en_IN missing on many devices → fall back to en_US).
Future<String?> _pickLocaleId(String languageCode) async {
  final ok = await _ensureStt();
  if (!ok || !_stt.isAvailable) return null;
  try {
    final available = await _stt.locales();
    if (available.isEmpty) return null;

    final preferred = _localeIdForListen(
      languageCode.trim().isEmpty ? 'en-IN' : languageCode,
    );
    if (preferred != null &&
        available.any((l) => l.localeId.toLowerCase() == preferred.toLowerCase())) {
      return preferred;
    }
    final lang = (languageCode.trim().isEmpty ? 'en' : languageCode)
        .replaceAll('_', '-')
        .split('-')
        .first
        .toLowerCase();
    for (final l in available) {
      if (l.localeId.toLowerCase().startsWith(lang)) return l.localeId;
    }
  } catch (e) {
    debugPrint('[speech_io] locale pick: $e');
  }
  return null;
}

void startListening(
  String languageCode,
  void Function(String) onResult,
  void Function() onEnd,
  void Function(String) onError,
  void Function() onSoundDetected,
) {
  unawaited(_startListeningAsync(
    languageCode,
    onResult,
    onEnd,
    onError,
    onSoundDetected,
  ));
}

Future<void> _startListeningAsync(
  String languageCode,
  void Function(String) onResult,
  void Function() onEnd,
  void Function(String) onError,
  void Function() onSoundDetected,
) async {
  final ok = await _ensureStt();
  if (!ok || !_stt.isAvailable) {
    onError('not_available');
    onEnd();
    return;
  }

  try {
    if (_stt.isListening) {
      await _stt.stop();
    }
  } catch (e) {
    debugPrint('[speech_io] pre-listen stop: $e');
  }
  await Future<void>.delayed(const Duration(milliseconds: 120));

  _listenSession = true;
  _pendingListenEnd = onEnd;

  try {
    final localeId = await _pickLocaleId(languageCode);
    debugPrint('[speech_io] listen localeId=$localeId');
    await _stt.listen(
      onResult: (res) {
        if (res.recognizedWords.isNotEmpty) {
          onResult(res.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 8),
      localeId: localeId,
      onSoundLevelChange: (level) {
        if (level > 0.03) onSoundDetected();
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        // Short yes/no matches confirmation tuning better than dictation on Android.
        listenMode: ListenMode.confirmation,
      ),
    );
  } catch (e) {
    _listenSession = false;
    _pendingListenEnd = null;
    onError('$e');
    onEnd();
  }
}

void stopListening() {
  if (!_sttInited) return;
  unawaited(() async {
    try {
      await _stt.stop();
    } catch (e) {
      debugPrint('[speech_io] stop: $e');
    }
    _listenSession = false;
    final cb = _pendingListenEnd;
    _pendingListenEnd = null;
    cb?.call();
  }());
}

void speakText(String text, {String lang = 'en-IN', void Function()? onDone}) {
  unawaited(_speakAsync(text, lang, onDone));
}

Future<void> _speakAsync(String text, String lang, void Function()? onDone) async {
  final cleaned = text.trim();
  if (cleaned.isEmpty) {
    onDone?.call();
    return;
  }
  await _ensureTts();
  try {
    await _tts.stop();
    final langTag = lang.replaceAll('_', '-');
    await _tts.setLanguage(langTag);
    // Robust standard: forcefully reset volume & pitch before every utterance.
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.speak(cleaned);
  } catch (e) {
    debugPrint('[speech_io] speak: $e');
  } finally {
    onDone?.call();
  }
}

void cancelSpeechText() {
  unawaited(() async {
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _stt.stop();
    } catch (_) {}
    _listenSession = false;
    _pendingListenEnd = null;
  }());
}

void primeSpeechAudioContext() {}
