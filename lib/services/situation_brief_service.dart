import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Triggers server-side generation of [sharedSituationBrief] on `sos_incidents/{id}`.
class SituationBriefService {
  SituationBriefService._();

  static Future<Map<String, dynamic>?> requestGeneration(
    String incidentId, {
    bool force = false,
  }) async {
    final id = incidentId.trim();
    if (id.isEmpty) return null;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateSituationBriefForIncident',
      );
      final res = await callable.call({'incidentId': id, 'force': force});
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (e, st) {
      debugPrint('[SituationBriefService] $e\n$st');
      return null;
    }
  }
}
