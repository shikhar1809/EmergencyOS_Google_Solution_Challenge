import 'package:cloud_functions/cloud_functions.dart';

import '../features/ai_assist/data/lifeline_curriculum_digest.dart';

/// BCP-47 tag for on-device TTS matching [kSupportedLocales] language codes.
String lifelineTtsBcp47(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'en':
      return 'en-IN';
    case 'hi':
      return 'hi-IN';
    case 'ta':
      return 'ta-IN';
    case 'te':
      return 'te-IN';
    case 'kn':
      return 'kn-IN';
    case 'ml':
      return 'ml-IN';
    case 'bn':
      return 'bn-IN';
    case 'mr':
      return 'mr-IN';
    case 'gu':
      return 'gu-IN';
    case 'pa':
      return 'pa-IN';
    case 'or':
      return 'or-IN';
    case 'ur':
      return 'ur-IN';
    default:
      return 'en-IN';
  }
}

abstract final class LifelineTrainingChatService {
  /// Prior turns only (exclude current user message). Each map: `role` user|model, `text`.
  static Future<String> send({
    required String message,
    required String replyLocaleBcp47,
    List<Map<String, String>> history = const [],
  }) async {
    final digest = LifelineCurriculumDigest.build();
    final callable = FirebaseFunctions.instance.httpsCallable('lifelineChat');
    final res = await callable.call(<String, dynamic>{
      'message': message,
      'scenario': 'Lifeline training assistant',
      'trainingMode': true,
      'replyLocale': replyLocaleBcp47,
      'contextDigest': digest,
      'history': history,
      'analyticsMode': false,
    });
    final raw = res.data;
    final Map<String, dynamic> data =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final status = (data['status'] as String?)?.trim() ?? 'ok';
    var reply = (data['text'] as String?)?.trim() ?? '';
    if (reply.isEmpty) reply = 'No response.';
    if (status == 'rate_limited') {
      reply = '[Rate limited] $reply';
    } else if (status == 'offline') {
      reply = '[Offline] $reply';
    } else if (status == 'error') {
      reply = '[Error] $reply';
    }
    return reply;
  }
}
