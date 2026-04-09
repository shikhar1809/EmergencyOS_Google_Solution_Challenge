import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/ptt_models.dart';

/// Firestore-backed PTT service.
/// Channels live at: ptt_channels/{incidentId}
/// Messages live at: ptt_channels/{incidentId}/messages/{messageId}
class PttService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'ptt_channels';
  static final _uuid = Uuid();

  /// Command post ↔ ambulance operator only (separate doc from the victim-facing SOS channel).
  static String commandOperationsChannelId(String baseIncidentId) => '${baseIncidentId}__command_ops';

  // ─── Channel ops ─────────────────────────────────────────────────────────

  /// Ensure the channel document exists. Idempotent — safe to call on every join.
  static Future<void> ensureChannel(String incidentId, String incidentType) async {
    try {
      final ref = _db.collection(_col).doc(incidentId);
      await ref.set({
        'incidentId': incidentId,
        'incidentType': incidentType,
        'memberIds': [],
        'memberNames': [],
        'panicActiveBy': null,
        'panicActiveName': null,
        'createdAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Add a responder to the channel member list and post a JOIN event.
  static Future<void> joinChannel(
      String incidentId, String uid, String displayName) async {
    try {
      final ref = _db.collection(_col).doc(incidentId);
      final snap = await ref.get();
      final data = snap.data();
      final memberIds = (data?['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
      if (memberIds.contains(uid)) return; // already joined → don't spam system messages

      await ref.set({
        'memberIds': FieldValue.arrayUnion([uid]),
        'memberNames': FieldValue.arrayUnion([displayName]),
      }, SetOptions(merge: true));

      await sendSystemMessage(
        incidentId,
        uid,
        displayName,
        '$displayName joined the channel',
        PttMessageType.join,
      );
    } catch (_) {}
  }

  /// Watch the channel document.
  static Stream<PttChannel?> watchChannel(String incidentId) {
    return _db.collection(_col).doc(incidentId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return PttChannel.fromJson(snap.data()!);
    });
  }

  // ─── Messages ────────────────────────────────────────────────────────────

  /// Watch the last 50 messages in the channel, ordered oldest-first for display.
  static Stream<List<PttMessage>> watchMessages(String incidentId) {
    return _db
        .collection(_col)
        .doc(incidentId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(50)
        .snapshots()
        .map((snap) => snap.docs.map(PttMessage.fromFirestore).toList());
  }

  /// Send a text message.
  static Future<void> sendText(
      String incidentId, String senderId, String senderName, String text) async {
    try {
      final id = _uuid.v4();
      final msg = PttMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        text: text,
        type: PttMessageType.text,
        timestamp: DateTime.now(),
      );
      await _db
          .collection(_col)
          .doc(incidentId)
          .collection('messages')
          .doc(id)
          .set(msg.toJson());
    } catch (_) {}
  }

  /// Send a voice clip (base64-encoded audio data).
  static Future<void> sendVoice(
    String incidentId,
    String senderId,
    String senderName,
    String audioBase64, {
    String? audioMimeType,
  }) async {
    try {
      final id = _uuid.v4();
      final msg = PttMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        audioBase64: audioBase64,
        audioMimeType: audioMimeType,
        type: PttMessageType.voice,
        timestamp: DateTime.now(),
      );
      await _db
          .collection(_col)
          .doc(incidentId)
          .collection('messages')
          .doc(id)
          .set(msg.toJson());
    } catch (_) {}
  }

  /// Broadcast a PANIC alert — updates channel state + posts panic message.
  static Future<void> triggerPanic(
      String incidentId, String uid, String displayName) async {
    try {
      await _db.collection(_col).doc(incidentId).update({
        'panicActiveBy': uid,
        'panicActiveName': displayName,
      });
      await sendSystemMessage(incidentId, uid, displayName,
          '🚨 PANIC — $displayName needs immediate help!', PttMessageType.panic);
    } catch (_) {}
  }

  /// Clear a panic state.
  static Future<void> clearPanic(String incidentId) async {
    try {
      await _db.collection(_col).doc(incidentId).update({
        'panicActiveBy': null,
        'panicActiveName': null,
      });
    } catch (_) {}
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  static Future<void> sendSystemMessage(String incidentId, String senderId,
      String senderName, String text, PttMessageType type) async {
    final id = _uuid.v4();
    final msg = PttMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      text: text,
      type: type,
      timestamp: DateTime.now(),
    );
    await _db
        .collection(_col)
        .doc(incidentId)
        .collection('messages')
        .doc(id)
        .set(msg.toJson());
  }
}

// ─── Riverpod Providers ───────────────────────────────────────────────────

final pttChannelProvider = StreamProvider.family<PttChannel?, String>(
  (ref, incidentId) => PttService.watchChannel(incidentId),
);

final pttMessagesProvider = StreamProvider.family<List<PttMessage>, String>(
  (ref, incidentId) => PttService.watchMessages(incidentId),
);
