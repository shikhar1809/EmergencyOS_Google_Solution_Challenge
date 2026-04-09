import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'incident_service.dart';

/// Non-critical Gemini advisory for dispatchers.
///
/// Uses the existing `lifelineChat` Cloud Function for incident context
/// summaries. Failures are swallowed so they never block critical flows.
class GeminiDispatchAdvisoryService {
  GeminiDispatchAdvisoryService._();

  /// Asks Gemini to generate a concise situation summary for a given incident,
  /// incorporating victim data, responder state, and hospital assignment.
  ///
  /// Intended for the command-center inspector panel as a non-critical overview.
  static Future<String?> generateIncidentSituationSummary({
    required SosIncident incident,
    String? hospitalAssignmentInfo,
  }) async {
    try {
      final digest = _buildIncidentDigest(incident, hospitalAssignmentInfo);
      final callable = FirebaseFunctions.instance.httpsCallable('lifelineChat');
      final res = await callable.call(<String, dynamic>{
        'message':
            'Generate a brief incident situation summary (4-5 sentences max) for a '
            'command center dispatcher. Include: incident type and severity assessment, '
            'victim status clues (blood type, allergies if present), responder status, '
            'hospital assignment if available, and one actionable recommendation. '
            'Be direct and clinical. Do NOT speculate on diagnosis.',
        'scenario': 'Dispatch situation summary (non-critical, informational)',
        'contextDigest': digest,
        'history': <Map<String, String>>[],
        'analyticsMode': false,
      }).timeout(const Duration(seconds: 12));
      final data = (res.data as Map?) ?? {};
      final text = (data['text'] as String?)?.trim();
      return (text != null && text.isNotEmpty) ? text : null;
    } catch (e) {
      debugPrint('[GeminiDispatchAdvisory] generateIncidentSituationSummary: $e');
      return null;
    }
  }

  static String _buildIncidentDigest(
    SosIncident incident,
    String? hospitalAssignmentInfo,
  ) {
    final buf = StringBuffer();
    buf.writeln('INCIDENT: ${incident.id}');
    buf.writeln('Type: ${incident.type}');
    buf.writeln('Victim: ${incident.userDisplayName}');
    buf.writeln(
      'Location: ${incident.liveVictimPin.latitude.toStringAsFixed(5)}, '
      '${incident.liveVictimPin.longitude.toStringAsFixed(5)}',
    );
    buf.writeln('Status: ${incident.status.name}');
    buf.writeln('EMS phase: ${incident.emsWorkflowPhase ?? "not started"}');
    buf.writeln('Volunteers accepted: ${incident.acceptedVolunteerIds.length}');
    buf.writeln('On-scene volunteers: ${incident.onSceneVolunteerIds.length}');
    buf.writeln('Ambulance ETA: ${incident.ambulanceEta ?? "—"}');
    buf.writeln('Medical status: ${incident.medicalStatus ?? "—"}');
    if (incident.bloodType != null) buf.writeln('Blood type: ${incident.bloodType}');
    if (incident.allergies != null) buf.writeln('Allergies: ${incident.allergies}');
    if (incident.medicalConditions != null) buf.writeln('Conditions: ${incident.medicalConditions}');
    if (incident.triage != null && incident.triage!.isNotEmpty) {
      buf.writeln('Triage: category=${incident.triage!['category'] ?? "—"}, '
          'score=${incident.triage!['severityScore'] ?? "—"}');
    }
    if (incident.smsRelayOrOrigin) buf.writeln('SMS-origin incident (GeoSMS)');
    final brief = incident.sharedSituationBrief;
    if (brief != null && brief.isNotEmpty) {
      final s = (brief['summary'] as String?)?.trim();
      if (s != null && s.isNotEmpty) {
        buf.writeln('Shared situation brief (summary): ${s.length > 800 ? "${s.substring(0, 800)}…" : s}');
      }
    }
    final scene = incident.volunteerSceneReport;
    if (scene != null && scene.isNotEmpty) {
      final desc = (scene['incidentDescription'] as String?)?.trim();
      final inj = (scene['visibleInjuries'] as String?)?.trim();
      if (desc != null && desc.isNotEmpty) buf.writeln('Volunteer scene — description: ${desc.length > 400 ? "${desc.substring(0, 400)}…" : desc}');
      if (inj != null && inj.isNotEmpty) buf.writeln('Volunteer scene — visible injuries: ${inj.length > 300 ? "${inj.substring(0, 300)}…" : inj}');
      final photos = scene['photoPaths'];
      if (photos is List && photos.isNotEmpty) {
        buf.writeln('Volunteer scene photos count: ${photos.length}');
      }
    }
    if (hospitalAssignmentInfo != null && hospitalAssignmentInfo.isNotEmpty) {
      buf.writeln('');
      buf.writeln('HOSPITAL ASSIGNMENT:');
      buf.writeln(hospitalAssignmentInfo);
    }
    return buf.toString();
  }
}
