import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

Future<Uint8List?> captureIncidentVoiceNote({
  required int maxSeconds,
  void Function(String message)? onStatus,
}) async {
  final mic = await Permission.microphone.request();
  if (!mic.isGranted) {
    onStatus?.call('Microphone permission is required.');
    return null;
  }

  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}/incident_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  final recorder = AudioRecorder();

  try {
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    await Future<void>.delayed(Duration(seconds: maxSeconds));
    await recorder.stop();
  } catch (e) {
    onStatus?.call('Recording failed: $e');
    return null;
  } finally {
    await recorder.dispose();
  }

  final f = File(path);
  if (!await f.exists()) return null;
  try {
    return await f.readAsBytes();
  } finally {
    try {
      await f.delete();
    } catch (_) {}
  }
}
