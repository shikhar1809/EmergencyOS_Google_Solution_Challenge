import 'dart:js_interop';
import 'package:flutter/foundation.dart';
@JS('initAudioMeter')
external JSPromise<JSBoolean> _jsInitAudioMeter();

@JS('getAudioVolume')
external JSNumber _jsGetAudioVolume();

class AudioMeterWeb {
  static bool _isInitialized = false;

  static Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      final jsResult = await _jsInitAudioMeter().toDart;
      _isInitialized = jsResult.toDart;
      return _isInitialized;
    } catch (e) {
      debugPrint('AudioMeterWeb INIT ERROR: $e');
      return false;
    }
  }

  static double getVolume() {
    if (!_isInitialized) return 0.0;
    try {
      return _jsGetAudioVolume().toDartDouble;
    } catch (e) {
      return 0.0;
    }
  }
}
