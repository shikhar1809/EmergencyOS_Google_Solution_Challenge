import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum BridgeMicState { on, muted }

enum BridgeHearState { hearing, deafened }

class BridgeChatMessage {
  const BridgeChatMessage({
    required this.messageId,
    required this.userId,
    required this.displayName,
    this.hospitalId,
    required this.content,
    required this.timestamp,
  });

  final String messageId;
  final String userId;
  final String displayName;
  final String? hospitalId;
  final String content;
  final DateTime timestamp;

  bool get isLocal => userId == _currentUserId;

  static String? _currentUserId;
  static void setCurrentUserId(String uid) => _currentUserId = uid;

  factory BridgeChatMessage.fromData(Map<String, dynamic> data) {
    return BridgeChatMessage(
      messageId: (data['messageId'] as String?)?.trim() ?? _uuid.v4(),
      userId: (data['userId'] as String?)?.trim() ?? '',
      displayName: (data['displayName'] as String?)?.trim() ?? 'Unknown',
      hospitalId: (data['hospitalId'] as String?)?.trim(),
      content: (data['content'] as String?)?.trim() ?? '',
      timestamp: data['timestamp'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toData() => {
    'type': 'bridge_chat',
    'messageId': messageId,
    'userId': userId,
    'displayName': displayName,
    if (hospitalId != null) 'hospitalId': hospitalId,
    'content': content,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  static BridgeChatMessage createLocal({
    required String userId,
    required String displayName,
    String? hospitalId,
    required String content,
  }) {
    return BridgeChatMessage(
      messageId: _uuid.v4(),
      userId: userId,
      displayName: displayName,
      hospitalId: hospitalId,
      content: content,
      timestamp: DateTime.now(),
    );
  }
}

class BridgeVoiceState {
  const BridgeVoiceState({
    required this.participantId,
    required this.displayName,
    required this.isLocal,
    this.mic = BridgeMicState.on,
    this.hearing = BridgeHearState.hearing,
    this.isSpeaking = false,
  });

  final String participantId;
  final String displayName;
  final bool isLocal;
  final BridgeMicState mic;
  final BridgeHearState hearing;
  final bool isSpeaking;

  BridgeVoiceState copyWith({
    BridgeMicState? mic,
    BridgeHearState? hearing,
    bool? isSpeaking,
  }) {
    return BridgeVoiceState(
      participantId: participantId,
      displayName: displayName,
      isLocal: isLocal,
      mic: mic ?? this.mic,
      hearing: hearing ?? this.hearing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}
