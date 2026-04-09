import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

Future<void> playPttVoiceClipBase64(String? base64, {String? mimeType}) async {
  if (base64 == null || base64.isEmpty) return;
  try {
    final bytes = base64Decode(base64);
    final dir = await getTemporaryDirectory();
    final ext = (mimeType ?? '').contains('mp4') ? 'm4a' : 'webm';
    final f = File('${dir.path}/ptt_${DateTime.now().millisecondsSinceEpoch}.$ext');
    await f.writeAsBytes(bytes);
    final player = AudioPlayer();
    await player.play(DeviceFileSource(f.path));
  } catch (_) {}
}
