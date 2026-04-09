import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Models ────────────────────────────────────────────────────────────────

/// EmergencyOS: PttMessageType in lib/features/ptt/domain/ptt_models.dart.
enum PttMessageType { text, voice, panic, join, resolved }

/// EmergencyOS: PttMessage in lib/features/ptt/domain/ptt_models.dart.
class PttMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final String? audioBase64; // Web Audio MediaRecorder output, base64 encoded
  /// e.g. audio/webm, audio/mp4 — improves playback across browsers when set.
  final String? audioMimeType;
  final PttMessageType type;
  final DateTime timestamp;

  const PttMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text,
    this.audioBase64,
    this.audioMimeType,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    if (text != null) 'text': text,
    if (audioBase64 != null) 'audioBase64': audioBase64,
    if (audioMimeType != null) 'audioMimeType': audioMimeType,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PttMessage.fromJson(Map<String, dynamic> j) => PttMessage(
    id: j['id'] ?? '',
    senderId: j['senderId'] ?? '',
    senderName: j['senderName'] ?? 'Responder',
    text: j['text'] as String?,
    audioBase64: j['audioBase64'] as String?,
    audioMimeType: j['audioMimeType'] as String?,
    type: PttMessageType.values.firstWhere(
      (t) => t.name == j['type'], orElse: () => PttMessageType.text),
    timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
  );

  factory PttMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PttMessage.fromJson({...d, 'id': doc.id});
  }
}

/// EmergencyOS: PttChannel in lib/features/ptt/domain/ptt_models.dart.
class PttChannel {
  final String incidentId;
  final String incidentType;
  final List<String> memberIds;
  final List<String> memberNames;
  final String? panicActiveBy; // uid of person who triggered panic, null if none
  final String? panicActiveName;

  const PttChannel({
    required this.incidentId,
    required this.incidentType,
    required this.memberIds,
    required this.memberNames,
    this.panicActiveBy,
    this.panicActiveName,
  });

  bool get hasPanic => panicActiveBy != null;

  factory PttChannel.fromJson(Map<String, dynamic> j) => PttChannel(
    incidentId: j['incidentId'] ?? '',
    incidentType: j['incidentType'] ?? 'Emergency',
    memberIds: List<String>.from(j['memberIds'] ?? []),
    memberNames: List<String>.from(j['memberNames'] ?? []),
    panicActiveBy: j['panicActiveBy'] as String?,
    panicActiveName: j['panicActiveName'] as String?,
  );
}
