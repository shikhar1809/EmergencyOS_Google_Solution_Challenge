import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:emergency_os/features/ai_assist/domain/lifeline_training_levels.dart';
import 'package:emergency_os/core/utils/speech_web.dart'
    if (dart.library.io) 'package:emergency_os/core/utils/speech_io.dart';

enum LifelineVoiceState {
  idle,
  listening,
  processing,
  speaking,
}

typedef LifelineVoiceCallback = void Function(LifelineVoiceState state);

class LifelineVoiceAgentService {
  LifelineVoiceAgentService._();
  static final LifelineVoiceAgentService instance = LifelineVoiceAgentService._();

  LifelineVoiceState _state = LifelineVoiceState.idle;
  LifelineVoiceCallback? _onStateChanged;
  String? _currentLanguageCode;
  final List<Map<String, String>> _history = [];
  bool _isListening = false;
  String _lastRecognizedText = '';
  void Function(String keyword)? _onOfflineFallback;

  LifelineVoiceState get state => _state;

  void setOnStateChanged(LifelineVoiceCallback callback) {
    _onStateChanged = callback;
  }

  void setOnOfflineFallback(void Function(String keyword) callback) {
    _onOfflineFallback = callback;
  }

  void _setState(LifelineVoiceState newState) {
    if (_state == newState) return;
    _state = newState;
    _onStateChanged?.call(newState);
  }

  void setLanguage(String languageCode) {
    _currentLanguageCode = languageCode;
  }

  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;
    _setState(LifelineVoiceState.listening);

    _lastRecognizedText = '';

    startListeningInternal(
      _currentLanguageCode ?? 'en',
      (text) {
        _lastRecognizedText = text;
        debugPrint('[LifelineVoice] Recognized: $text');
      },
      () {
        _isListening = false;
        if (_lastRecognizedText.trim().isNotEmpty) {
          _processText(_lastRecognizedText);
        } else {
          _setState(LifelineVoiceState.idle);
        }
      },
      (error) {
        debugPrint('[LifelineVoice] Error: $error');
        _isListening = false;
        _setState(LifelineVoiceState.idle);
      },
      () {
        debugPrint('[LifelineVoice] Sound detected');
      },
    );
  }

  void stopListening() {
    if (!_isListening) return;
    stopListeningInternal();
    _isListening = false;
  }

  Future<void> _processText(String text) async {
    _setState(LifelineVoiceState.processing);

    try {
      final reply = await _sendToGemini(text);
      if (reply != null) {
        _setState(LifelineVoiceState.speaking);
        await _speak(reply);
      }
    } catch (e) {
      debugPrint('[LifelineVoice] Gemini error: $e');
      _handleOfflineFallback(text);
    }

    if (_state == LifelineVoiceState.speaking) {
      _setState(LifelineVoiceState.idle);
    }
  }

  Future<String?> _sendToGemini(String text) async {
    try {
      final locale = _currentLanguageCode ?? 'en';
      final bcp = _bcp47ForLocale(locale);

      final callable = FirebaseFunctions.instance.httpsCallable('lifelineChat');
      final result = await callable.call(<String, dynamic>{
        'message': text,
        'replyLocaleBcp47': bcp,
        'history': _history,
        'scenario': 'Lifeline voice assistant',
      });

      final reply = result.data['reply'] as String?;
      if (reply != null && reply.isNotEmpty) {
        _history.add({'role': 'user', 'text': text});
        _history.add({'role': 'model', 'text': reply});
        while (_history.length > 12) {
          _history.removeAt(0);
        }
        return reply;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  void _handleOfflineFallback(String text) {
    final normalizedText = text.toLowerCase().trim();
    final matchedLevel = _matchKeyword(normalizedText);
    if (matchedLevel != null) {
      debugPrint('[LifelineVoice] Offline fallback: matched "${matchedLevel.title}"');
      _onOfflineFallback?.call(matchedLevel.title);
      _speakFallbackMessage(matchedLevel.title);
    } else {
      debugPrint('[LifelineVoice] No keyword match found for: $text');
      _speakText(
        'Sorry, I could not understand. You can browse the Lifeline library to learn about first aid topics.',
      );
    }
  }

  LifelineTrainingLevel? _matchKeyword(String text) {
    final keywordMap = <String, LifelineTrainingLevel>{};

    for (final level in kLifelineTrainingLevels) {
      final keywords = <String>[];
      keywords.add(level.title.toLowerCase());

      final titleWords = level.title.toLowerCase().split(RegExp(r'\s+'));
      for (final word in titleWords) {
        if (word.length > 3) {
          keywords.add(word);
        }
      }

      if (level.subtitle.isNotEmpty) {
        keywords.add(level.subtitle.toLowerCase());
      }

      for (final keyword in keywords) {
        keywordMap[keyword] = level;
      }
    }

    for (final entry in keywordMap.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  void _speakFallbackMessage(String matchedTitle) {
    final message =
        'Opening $matchedTitle. You can learn about this topic in the Lifeline library.';
    _speakText(message);
  }

  Future<void> _speak(String text) async {
    final lang = _bcp47ForLocale(_currentLanguageCode ?? 'en');
    speakText(
      text,
      lang: lang,
      onDone: () {
        if (_state == LifelineVoiceState.speaking) {
          _setState(LifelineVoiceState.idle);
        }
      },
    );
  }

  void _speakText(String text) {
    final lang = _bcp47ForLocale(_currentLanguageCode ?? 'en');
    speakText(
      text,
      lang: lang,
      onDone: () {
        if (_state == LifelineVoiceState.speaking) {
          _setState(LifelineVoiceState.idle);
        }
      },
    );
  }

  String _bcp47ForLocale(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'hi-IN';
      case 'en':
      default:
        return 'en-IN';
    }
  }

  void cancel() {
    stopListening();
    cancelSpeechText();
    _history.clear();
    _setState(LifelineVoiceState.idle);
  }

  void resetToListening() {
    cancel();
    Future.delayed(const Duration(milliseconds: 100), () {
      startListening();
    });
  }

  void dispose() {
    cancel();
    _onStateChanged = null;
    _onOfflineFallback = null;
  }
}

void startListeningInternal(
  String languageCode,
  void Function(String) onResult,
  void Function() onEnd,
  void Function(String) onError,
  void Function() onSoundDetected,
) {
  if (kIsWeb) {
    startListening(languageCode, onResult, onEnd, onError, onSoundDetected);
  } else {
    startListening(languageCode, onResult, onEnd, onError, onSoundDetected);
  }
}

void stopListeningInternal() {
  if (kIsWeb) {
    stopListening();
  } else {
    stopListening();
  }
}
