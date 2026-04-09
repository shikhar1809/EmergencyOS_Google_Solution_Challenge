import 'dart:typed_data';

/// Web / non-IO: voice capture not available.
Future<Uint8List?> captureIncidentVoiceNote({
  required int maxSeconds,
  void Function(String message)? onStatus,
}) async {
  onStatus?.call('Voice notes are available on iOS and Android.');
  return null;
}
