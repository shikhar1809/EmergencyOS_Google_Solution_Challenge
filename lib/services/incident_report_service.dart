import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_service.dart';

/// Builds and stores narrative incident reports for sharing and audit.
class IncidentReportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String goodSamaritanShieldText =
      'This report documents bystander assistance provided in good faith '
      'during an emergency. Nothing in this document should be interpreted '
      'as a waiver of Good Samaritan protections available under applicable law.';

  /// Compose a simple narrative from the SosIncident snapshot.
  static Map<String, dynamic> buildReportPayload(SosIncident inc) {
    final now = DateTime.now();
    final Map<String, dynamic> triage = inc.triage ?? const {};

    final buffer = StringBuffer()
      ..writeln('Incident ID: ${inc.id}')
      ..writeln('Type: ${inc.type}')
      ..writeln('Reported at: ${inc.timestamp.toIso8601String()}')
      ..writeln('Location: ${inc.location.latitude}, ${inc.location.longitude}')
      ..writeln()
      ..writeln('Status: ${inc.status.name}')
      ..writeln('Lifecycle: ${inc.lifecyclePhaseLabel}')
      ..writeln();

    if (inc.firstAcknowledgedAt != null) {
      buffer.writeln('First acknowledgement at: ${inc.firstAcknowledgedAt!.toIso8601String()}');
    }
    if (inc.emsAcceptedAt != null) {
      buffer.writeln('EMS accepted at: ${inc.emsAcceptedAt!.toIso8601String()}');
    }
    if (inc.emsOnSceneAt != null) {
      buffer.writeln('EMS on scene at: ${inc.emsOnSceneAt!.toIso8601String()}');
    }

    buffer.writeln();
    buffer.writeln('Victim medical snapshot:');
    buffer.writeln('  Blood type: ${inc.bloodType ?? "-"}');
    buffer.writeln('  Allergies: ${inc.allergies ?? "-"}');
    buffer.writeln('  Conditions: ${inc.medicalConditions ?? "-"}');

    if (triage.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Triage summary:');
      triage.forEach((k, v) {
        buffer.writeln('  $k: $v');
      });
    }

    buffer.writeln();
    buffer.writeln('Good Samaritan Shield:');
    buffer.writeln(goodSamaritanShieldText);

    return <String, dynamic>{
      'incidentId': inc.id,
      'userId': inc.userId,
      'type': inc.type,
      'status': inc.status.name,
      'createdAt': now.toIso8601String(),
      'narrative': buffer.toString(),
      'triage': triage,
      'goodSamaritanShield': goodSamaritanShieldText,
    };
  }

  /// Generate and persist a report document under `sos_incidents/{id}/incident_reports`.
  static Future<void> generateAndStoreReport(SosIncident incident) async {
    final payload = buildReportPayload(incident);
    await _db
        .collection('sos_incidents')
        .doc(incident.id)
        .collection('incident_reports')
        .add(<String, dynamic>{
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

