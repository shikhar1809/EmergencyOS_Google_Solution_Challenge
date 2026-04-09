import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Short UI cues when remote participants join / leave LiveKit rooms (debounced per event).
abstract final class LivekitUiSounds {
  static AudioPlayer? _player;

  static Future<void> playJoin() => _play('sounds/livekit_join.wav');

  static Future<void> playLeave() => _play('sounds/livekit_leave.wav');

  static Future<void> _play(String assetPath) async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.setVolume(0.35);
      await _player!.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('[LivekitUiSounds] $e');
    }
  }
}
