import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'incident_service.dart';

/// Builds and stores narrative incident reports for sharing and audit.
class IncidentReportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String goodSamaritanShieldText =
      'This report documents bystander assistance provided in good faith '
      'during an emergency. Nothing in this document should be interpreted '
      'as a waiver of Good Samaritan protections available under applicable law.';

  static const String _clinicalSynthesisUnavailable =
      'Clinical synthesis unavailable — see structured sections above.';

  static dynamic _jsonEncodable(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate().toIso8601String();
    if (v is DateTime) return v.toIso8601String();
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _jsonEncodable(val)));
    }
    if (v is List) {
      return v.map(_jsonEncodable).toList();
    }
    if (v is num || v is String || v is bool) return v;
    return v.toString();
  }

  static String _fmtDur(Duration? d) {
    if (d == null) return '—';
    if (d.isNegative) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${d.inSeconds}s';
  }

  static String _dtLine(DateTime t) {
    final local = t.toLocal();
    return '${t.toIso8601String()} (${DateFormat.yMMMd().add_jm().format(local)})';
  }

  static void _sectionHeader(StringBuffer buf, String title) {
    buf.writeln();
    buf.writeln('===== $title =====');
  }

  static Future<List<Map<String, dynamic>>> _loadFleetOperatorHandoffs(String incidentId) async {
    final id = incidentId.trim();
    if (id.isEmpty) return [];
    try {
      final snap = await _db.collection('sos_incidents').doc(id).collection('fleet_operator_handoff').limit(16).get();
      final docs = snap.docs.toList()
        ..sort((a, b) {
          final ta = a.data()['updatedAt'];
          final tb = b.data()['updatedAt'];
          DateTime? da;
          DateTime? db;
          if (ta is Timestamp) da = ta.toDate();
          if (tb is Timestamp) db = tb.toDate();
          return (db ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(da ?? DateTime.fromMillisecondsSinceEpoch(0));
        });
      return docs
          .take(8)
          .map((d) {
            final m = Map<String, dynamic>.from(d.data());
            m['operatorDocId'] = d.id;
            return m;
          })
          .toList();
    } catch (e, st) {
      debugPrint('[IncidentReportService] fleet handoff load: $e\n$st');
      return [];
    }
  }

  static Future<Map<String, dynamic>> _loadPatientProfileExtras(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return {};
    try {
      final d = await _db.collection('users').doc(uid).get();
      if (!d.exists || d.data() == null) return {};
      final m = d.data()!;
      return <String, dynamic>{
        if (m['medications'] != null && '${m['medications']}'.trim().isNotEmpty)
          'medications': '${m['medications']}'.trim(),
        if (m['donorStatus'] != null && '${m['donorStatus']}'.trim().isNotEmpty)
          'donorStatus': '${m['donorStatus']}'.trim(),
        if (m['contactName'] != null && '${m['contactName']}'.trim().isNotEmpty)
          'contactName': '${m['contactName']}'.trim(),
        if (m['contactPhone'] != null && '${m['contactPhone']}'.trim().isNotEmpty)
          'contactPhone': '${m['contactPhone']}'.trim(),
        if (m['contactEmail'] != null && '${m['contactEmail']}'.trim().isNotEmpty)
          'contactEmail': '${m['contactEmail']}'.trim(),
        if (m['relationship'] != null && '${m['relationship']}'.trim().isNotEmpty)
          'relationship': '${m['relationship']}'.trim(),
        if (m['useEmergencyContactForSms'] is bool) 'useEmergencyContactForSms': m['useEmergencyContactForSms'] as bool,
      };
    } catch (e, st) {
      debugPrint('[IncidentReportService] profile extras: $e\n$st');
      return {};
    }
  }

  static Future<Map<String, dynamic>> _loadIncidentRawExtras(String incidentId) async {
    final id = incidentId.trim();
    if (id.isEmpty) return {};
    try {
      final d = await _db.collection('sos_incidents').doc(id).get();
      if (!d.exists || d.data() == null) return {};
      final m = d.data()!;
      final out = <String, dynamic>{};
      final st = m['severityTier'];
      if (st != null && '$st'.trim().isNotEmpty) {
        out['severityTier'] = '$st'.trim();
      }
      final va = m['videoAssessment'];
      if (va is Map) {
        out['videoAssessment'] = Map<String, dynamic>.from(va as Map);
      }
      return out;
    } catch (e, st) {
      debugPrint('[IncidentReportService] raw extras: $e\n$st');
      return {};
    }
  }

  static Future<Map<String, dynamic>?> _invokeClinicalSynthesis(String incidentId) async {
    final id = incidentId.trim();
    if (id.isEmpty) return null;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateClinicalReport');
      final res = await callable.call(<String, dynamic>{'incidentId': id});
      final data = res.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data as Map);
      }
      return null;
    } catch (e, st) {
      debugPrint('[IncidentReportService] clinical synthesis: $e\n$st');
      return null;
    }
  }

  static Map<String, dynamic>? _aiTriageSubset(Map<String, dynamic>? triage) {
    if (triage == null || triage.isEmpty) return null;
    final ai = triage['aiVision'];
    final out = <String, dynamic>{};
    if (ai is Map) {
      out['aiVision'] = _jsonEncodable(Map<String, dynamic>.from(ai as Map));
    }
    for (final k in [
      'bleeding',
      'chestPain',
      'breathingTrouble',
      'unconscious',
      'trapped',
      'notes',
      'severityScore',
      'consciousVoiceMissCount',
      'category',
      'severity',
      'severityFlags',
    ]) {
      if (triage.containsKey(k)) {
        out[k] = _jsonEncodable(triage[k]);
      }
    }
    return out.isEmpty ? null : out;
  }

  static List<Map<String, String>> _buildTimelineRows(SosIncident inc) {
    final sos = inc.timestamp;
    DateTime? prev = sos;
    final rows = <Map<String, String>>[];

    void add(String phase, DateTime? at) {
      if (at == null) return;
      final fromSos = at.difference(sos);
      final fromPrev = prev != null ? at.difference(prev!) : null;
      prev = at;
      rows.add(<String, String>{
        'phase': phase,
        'at': _dtLine(at),
        'deltaFromSos': _fmtDur(fromSos),
        'deltaFromPrev': fromPrev != null ? _fmtDur(fromPrev) : '—',
      });
    }

    add('SOS_received', inc.timestamp);
    add('First_acknowledgement', inc.firstAcknowledgedAt);
    add('EMS_unit_accepted', inc.emsAcceptedAt);
    add('EMS_on_scene', inc.emsOnSceneAt);
    add('EMS_rescue_complete_scene', inc.emsRescueCompleteAt);
    add('EMS_returning_to_hospital', inc.emsReturningStartedAt);
    add('EMS_hospital_arrival', inc.emsHospitalArrivalAt);
    add('EMS_response_complete', inc.emsResponseCompleteAt);
    return rows;
  }

  static void _writeTimelineNarrative(StringBuffer buf, SosIncident inc) {
    _sectionHeader(buf, 'EMS TIMELINE');
    final rows = _buildTimelineRows(inc);
    if (rows.isEmpty) {
      buf.writeln('No timeline rows.');
      return;
    }
    for (final r in rows) {
      buf.writeln('• ${r['phase']}');
      buf.writeln('  When: ${r['at']}');
      buf.writeln('  Δ from SOS: ${r['deltaFromSos']} · Δ from previous: ${r['deltaFromPrev']}');
    }
  }

  static void _writeSosIncoming(StringBuffer buf, SosIncident inc) {
    _sectionHeader(buf, 'SOS INCOMING');
    buf.writeln('Primary SOS time: ${_dtLine(inc.timestamp)}');
    buf.writeln('Location (original pin): ${inc.location.latitude}, ${inc.location.longitude}');
    buf.writeln('Live pin: ${inc.liveVictimPin.latitude}, ${inc.liveVictimPin.longitude}');
    if (inc.smsOrigin) {
      buf.writeln('Channel: SMS-origin incident');
    } else if (inc.smsRelayReceived) {
      buf.writeln('Channel: In-app SOS + parallel GeoSMS relay');
    } else {
      buf.writeln('Channel: In-app SOS');
    }
    if ((inc.senderPhone ?? '').trim().isNotEmpty) {
      buf.writeln('Sender / victim phone (relay): ${inc.senderPhone!.trim()}');
    }
    if (inc.smsRelayAt != null) {
      buf.writeln('SMS relay at: ${_dtLine(inc.smsRelayAt!)}');
    }
    if (inc.geoSmsPatternRecognized && inc.geoSmsRecognizedAt != null) {
      buf.writeln('GeoSMS recognized at: ${_dtLine(inc.geoSmsRecognizedAt!)}');
    }
    if (inc.firstAcknowledgedAt != null) {
      buf.writeln('First acknowledgement: ${_dtLine(inc.firstAcknowledgedAt!)}');
      buf.writeln('Time SOS → first ack: ${_fmtDur(inc.firstAcknowledgedAt!.difference(inc.timestamp))}');
      if ((inc.firstAcknowledgedByUid ?? '').trim().isNotEmpty) {
        buf.writeln('First acknowledged by UID: ${inc.firstAcknowledgedByUid!.trim()}');
      }
    } else {
      buf.writeln('First acknowledgement: —');
    }
    final genAt = DateTime.now();
    buf.writeln('Golden-hour anchor: ${_dtLine(inc.goldenHourStart)}');
    buf.writeln('Elapsed SOS → report generation: ${_fmtDur(genAt.difference(inc.timestamp))}');
  }

  static void _writeClinicalSynthesisNarrative(StringBuffer buf, Map<String, dynamic>? synth) {
    _sectionHeader(buf, 'CLINICAL SYNTHESIS (Gemini)');
    final ok = synth != null && synth['ok'] == true;
    final text = (synth?['clinicalSynthesis'] as String?)?.trim() ?? '';
    if (!ok || text.isEmpty) {
      buf.writeln(_clinicalSynthesisUnavailable);
      return;
    }
    buf.writeln(text);
    final rf = synth!['redFlags'];
    if (rf is List && rf.isNotEmpty) {
      buf.writeln();
      buf.writeln('Red flags:');
      for (final e in rf) {
        buf.writeln('  • $e');
      }
    }
    final exp = synth['expectedInterventions'];
    if (exp is List && exp.isNotEmpty) {
      buf.writeln();
      buf.writeln('Expected ED considerations:');
      for (final e in exp) {
        buf.writeln('  • $e');
      }
    }
    final script = (synth['handoverScript'] as String?)?.trim() ?? '';
    if (script.isNotEmpty) {
      buf.writeln();
      buf.writeln('Handover script (bay door):');
      buf.writeln(script);
    }
  }

  static void _writePreArrivalNarrative(StringBuffer buf, Map<String, dynamic>? ph) {
    _sectionHeader(buf, 'PRE-ARRIVAL HANDOFF (Gemini)');
    if (ph == null || ph.isEmpty) {
      buf.writeln('No pre-arrival handoff packet on record.');
      return;
    }
    void line(String k, String label) {
      final v = ph[k];
      if (v == null) return;
      if (v is String && v.trim().isEmpty) return;
      buf.writeln('$label: $v');
    }

    line('status', 'Status');
    line('patientSnapshot', 'Patient snapshot');
    line('likelyPresentation', 'Likely presentation');
    line('hospitalName', 'Hospital name');
    line('etaSeconds', 'ETA (seconds)');
    for (final key in ['prepareRoom', 'prepareTeam', 'bloodAndMeds', 'contraindications']) {
      final v = ph[key];
      if (v is! List || v.isEmpty) continue;
      buf.writeln('$key:');
      for (final e in v) {
        buf.writeln('  • $e');
      }
    }
  }

  static void _writeAiTriageNarrative(StringBuffer buf, Map<String, dynamic>? subset) {
    _sectionHeader(buf, 'AI TRIAGE & VICTIM FLAGS');
    if (subset == null || subset.isEmpty) {
      buf.writeln('No structured triage / AI vision snapshot.');
      return;
    }
    subset.forEach((k, v) {
      buf.writeln('$k: $v');
    });
  }

  static void _writeSituationBriefNarrative(StringBuffer buf, Map<String, dynamic>? brief) {
    _sectionHeader(buf, 'SITUATION BRIEF (Gemini)');
    if (brief == null || brief.isEmpty) {
      buf.writeln('No shared situation brief on record.');
      return;
    }
    final summary = (brief['summary'] as String?)?.trim();
    if (summary != null && summary.isNotEmpty) {
      buf.writeln(summary);
    }
    for (final key in ['highlights', 'recommendedActions', 'sourcesUsed']) {
      final v = brief[key];
      if (v is! List || v.isEmpty) continue;
      buf.writeln();
      buf.writeln('$key:');
      for (final e in v) {
        buf.writeln('  • $e');
      }
    }
    final lg = brief['lastGeneratedAt'];
    if (lg != null) buf.writeln('\nLast generated (raw): $lg');
  }

  static void _writePatientProfileNarrative(
    StringBuffer buf,
    SosIncident inc,
    Map<String, dynamic> profileExtras,
    String? severityTier,
  ) {
    _sectionHeader(buf, 'PATIENT MEDICAL PROFILE');
    buf.writeln('Display name: ${inc.userDisplayName}');
    if ((severityTier ?? '').isNotEmpty) {
      buf.writeln('Dispatch severity tier: $severityTier');
    }
    buf.writeln('Blood type: ${inc.bloodType ?? "—"}');
    buf.writeln('Allergies: ${inc.allergies ?? "—"}');
    buf.writeln('Conditions: ${inc.medicalConditions ?? "—"}');
    if ((profileExtras['medications'] as String?)?.isNotEmpty ?? false) {
      buf.writeln('Medications (profile): ${profileExtras['medications']}');
    }
    if ((profileExtras['donorStatus'] as String?)?.isNotEmpty ?? false) {
      buf.writeln('Donor status (profile): ${profileExtras['donorStatus']}');
    }
    buf.writeln('ICE phone (incident snapshot): ${inc.emergencyContactPhone ?? "—"}');
    buf.writeln('ICE email (incident snapshot): ${inc.emergencyContactEmail ?? "—"}');
    buf.writeln('Use ICE contact for SMS: ${inc.useEmergencyContactForSms}');
    if ((profileExtras['contactName'] as String?)?.isNotEmpty ?? false) {
      buf.writeln('ICE name (profile): ${profileExtras['contactName']}');
    }
    if ((profileExtras['relationship'] as String?)?.isNotEmpty ?? false) {
      buf.writeln('ICE relationship (profile): ${profileExtras['relationship']}');
    }
    if ((profileExtras['contactPhone'] as String?)?.isNotEmpty ?? false) {
      buf.writeln('ICE phone (profile): ${profileExtras['contactPhone']}');
    }
    if ((profileExtras['contactEmail'] as String?)?.isNotEmpty ?? false) {
      buf.writeln('ICE email (profile): ${profileExtras['contactEmail']}');
    }
  }

  static void _writeVolunteerSceneNarrative(StringBuffer buf, SosIncident inc, Map<String, dynamic>? scene) {
    _sectionHeader(buf, 'ON-SCENE VOLUNTEER REPORT');
    if (scene == null || scene.isEmpty) {
      buf.writeln('No volunteer scene report.');
      return;
    }
    final desc = (scene['incidentDescription'] as String?)?.trim();
    if (desc != null && desc.isNotEmpty) buf.writeln('Description: $desc');
    for (final key in ['voiceNoteTranscript', 'dictation', 'reportDetails']) {
      final v = scene[key];
      if (v is String && v.trim().isNotEmpty) {
        buf.writeln('$key: ${v.trim()}');
      }
    }
    final photos = scene['photoPaths'];
    if (photos is List && photos.isNotEmpty) {
      buf.writeln('Scene photo / media paths (${photos.length}):');
      for (final p in photos.take(12)) {
        buf.writeln('  • $p');
      }
      if (photos.length > 12) buf.writeln('  …');
    }
    final u = scene['updatedAt'];
    if (u != null) buf.writeln('Updated at (raw): $u');
    if (inc.responderNames.isNotEmpty) {
      buf.writeln('Responder names: ${inc.responderNames}');
    }
  }

  static void _writeFleetHandoffNarrative(StringBuffer buf, List<Map<String, dynamic>> drafts) {
    _sectionHeader(buf, 'FLEET OPERATOR HANDOFF');
    if (drafts.isEmpty) {
      buf.writeln('No fleet operator handoff notes on record.');
      return;
    }
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      final op = (d['operatorDocId'] ?? d['operatorUid'] ?? 'operator').toString();
      final notes = (d['notesText'] as String?)?.trim() ?? '';
      final urls = d['photoUrls'];
      var photoCount = 0;
      if (urls is List) {
        photoCount = urls.whereType<String>().where((e) => e.trim().isNotEmpty).length;
      }
      buf.writeln('— Operator $op');
      if (notes.isEmpty) {
        buf.writeln('  (no notes text)');
      } else {
        for (final line in notes.split('\n')) {
          if (line.trim().isEmpty) continue;
          buf.writeln('  $line');
        }
      }
      buf.writeln('  Attached photos: $photoCount');
      final ua = d['updatedAt'];
      if (ua != null) buf.writeln('  Updated at (raw): $ua');
      if (i < drafts.length - 1) buf.writeln();
    }
  }

  static void _writeVideoAssessmentNarrative(StringBuffer buf, Map<String, dynamic>? va) {
    _sectionHeader(buf, 'VIDEO ASSESSMENT');
    if (va == null || va.isEmpty) {
      buf.writeln('No video assessment on record.');
      return;
    }
    try {
      buf.writeln(const JsonEncoder.withIndent('  ').convert(_jsonEncodable(va)));
    } catch (_) {
      buf.writeln('${_jsonEncodable(va)}');
    }
  }

  static void _writeDispatchNarrative(StringBuffer buf, SosIncident inc) {
    _sectionHeader(buf, 'DISPATCH & RECEIVING HOSPITAL');
    final r = inc.aiHospitalRationale;
    if (r != null && r.isNotEmpty) {
      final name = (r['hospitalName'] as String?)?.trim();
      final hid = (r['hospitalId'] as String?)?.trim();
      final text = (r['text'] as String?)?.trim();
      if (name != null && name.isNotEmpty) buf.writeln('Receiving hospital (rationale): $name');
      if (hid != null && hid.isNotEmpty) buf.writeln('Hospital ID: $hid');
      if (text != null && text.isNotEmpty) buf.writeln('Dispatch rationale: $text');
    }
    if ((inc.returnHospitalId ?? '').trim().isNotEmpty) {
      buf.writeln('Return hospital ID (incident): ${inc.returnHospitalId!.trim()}');
    }
    if ((inc.stationedHospitalId ?? '').trim().isNotEmpty) {
      buf.writeln('Stationed hospital / route origin ID: ${inc.stationedHospitalId!.trim()}');
    }
    if ((inc.adminDispatchNote ?? '').trim().isNotEmpty) {
      buf.writeln('Admin dispatch note: ${inc.adminDispatchNote!.trim()}');
    }
    if ((inc.ambulanceEta ?? '').trim().isNotEmpty) {
      buf.writeln('Ambulance ETA (last reported): ${inc.ambulanceEta!.trim()}');
    }
    if ((inc.medicalStatus ?? '').trim().isNotEmpty) {
      buf.writeln('Medical status text: ${inc.medicalStatus!.trim()}');
    }
    buf.writeln('Incident status: ${inc.status.name}');
    buf.writeln('Lifecycle: ${inc.lifecyclePhaseLabel}');
    if ((inc.emsWorkflowPhase ?? '').trim().isNotEmpty) {
      buf.writeln('EMS workflow phase: ${inc.emsWorkflowPhase!.trim()}');
    }
  }

  static void _writeHeaderNarrative(StringBuffer buf, SosIncident inc, String? severityTier) {
    _sectionHeader(buf, 'INCIDENT HEADER');
    buf.writeln('Incident ID: ${inc.id}');
    buf.writeln('Patient / user ID: ${inc.userId}');
    buf.writeln('Report generated at: ${_dtLine(DateTime.now())}');
    final actor = FirebaseAuth.instance.currentUser?.uid ?? '';
    buf.writeln('Report generated by UID: ${actor.isEmpty ? "(unknown)" : actor}');
    buf.writeln('Incident type: ${inc.type}');
    if ((severityTier ?? '').isNotEmpty) {
      buf.writeln('Dispatch severity tier: $severityTier');
    }
    buf.writeln('Blood type (snapshot): ${inc.bloodType ?? "—"}');
  }

  /// Compose enhanced narrative + structured fields for `incident_reports`.
  static Future<Map<String, dynamic>> buildEnhancedReportPayload(SosIncident inc) async {
    final now = DateTime.now();
    final triage = inc.triage ?? const <String, dynamic>{};
    final results = await Future.wait([
      _loadFleetOperatorHandoffs(inc.id),
      _loadPatientProfileExtras(inc.userId),
      _loadIncidentRawExtras(inc.id),
      _invokeClinicalSynthesis(inc.id),
    ]);
    final fleetHandoffs = results[0] as List<Map<String, dynamic>>;
    final profileExtras = results[1] as Map<String, dynamic>;
    final rawExtras = results[2] as Map<String, dynamic>;
    final synthRaw = results[3] as Map<String, dynamic>?;

    final videoAssessment = rawExtras['videoAssessment'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawExtras['videoAssessment'] as Map<String, dynamic>)
        : null;
    final severityTier = rawExtras['severityTier'] as String?;

    final rescueDurationSeconds = (inc.emsRescueCompleteAt != null && inc.emsAcceptedAt != null)
        ? inc.emsRescueCompleteAt!.difference(inc.emsAcceptedAt!).inSeconds
        : null;
    final returnDurationSeconds = (inc.emsResponseCompleteAt != null && inc.emsReturningStartedAt != null)
        ? inc.emsResponseCompleteAt!.difference(inc.emsReturningStartedAt!).inSeconds
        : null;
    final totalCycleSeconds = inc.emsResponseCompleteAt != null
        ? inc.emsResponseCompleteAt!.difference(inc.timestamp).inSeconds
        : null;

    final aiSubset = _aiTriageSubset(inc.triage);
    final timeline = _buildTimelineRows(inc);
    final fleetForPayload = fleetHandoffs
        .map((d) => <String, dynamic>{
              'operatorDocId': d['operatorDocId'],
              'operatorUid': d['operatorUid'],
              'notesText': (d['notesText'] as String?)?.trim() ?? '',
              'photoCount': (d['photoUrls'] is List)
                  ? (d['photoUrls'] as List).whereType<String>().where((e) => e.trim().isNotEmpty).length
                  : 0,
              'updatedAt': _jsonEncodable(d['updatedAt']),
            })
        .toList();

    final clinicalPayload = synthRaw == null
        ? <String, dynamic>{
            'ok': false,
            'clinicalSynthesis': '',
            'redFlags': <String>[],
            'expectedInterventions': <String>[],
            'handoverScript': '',
          }
        : <String, dynamic>{
            'ok': synthRaw['ok'] == true,
            'clinicalSynthesis': '${synthRaw['clinicalSynthesis'] ?? ''}'.trim(),
            'redFlags': synthRaw['redFlags'] is List
                ? (synthRaw['redFlags'] as List).map((e) => '$e').where((e) => e.isNotEmpty).toList()
                : <String>[],
            'expectedInterventions': synthRaw['expectedInterventions'] is List
                ? (synthRaw['expectedInterventions'] as List).map((e) => '$e').where((e) => e.isNotEmpty).toList()
                : <String>[],
            'handoverScript': '${synthRaw['handoverScript'] ?? ''}'.trim(),
            if (synthRaw['error'] != null) 'error': '${synthRaw['error']}',
          };

    final patientProfile = <String, dynamic>{
      'userDisplayName': inc.userDisplayName,
      'bloodType': inc.bloodType,
      'allergies': inc.allergies,
      'medicalConditions': inc.medicalConditions,
      'emergencyContactPhone': inc.emergencyContactPhone,
      'emergencyContactEmail': inc.emergencyContactEmail,
      'useEmergencyContactForSms': inc.useEmergencyContactForSms,
      ...profileExtras,
    };

    final buffer = StringBuffer();
    _writeHeaderNarrative(buffer, inc, severityTier);
    _writeSosIncoming(buffer, inc);
    _writeClinicalSynthesisNarrative(buffer, synthRaw);
    _writePreArrivalNarrative(buffer, inc.preArrivalHandoff);
    _writeAiTriageNarrative(buffer, aiSubset);
    _writeSituationBriefNarrative(buffer, inc.sharedSituationBrief);
    _writePatientProfileNarrative(buffer, inc, profileExtras, severityTier);
    _writeVolunteerSceneNarrative(buffer, inc, inc.volunteerSceneReport);
    _writeFleetHandoffNarrative(buffer, fleetHandoffs);
    _writeVideoAssessmentNarrative(buffer, videoAssessment);
    _writeDispatchNarrative(buffer, inc);

    if (rescueDurationSeconds != null) {
      buffer.writeln();
      buffer.writeln('Rescue duration (accept → rescue complete): ${rescueDurationSeconds}s');
    }
    if (returnDurationSeconds != null) {
      buffer.writeln('Return leg duration (returning start → response complete): ${returnDurationSeconds}s');
    }
    if (totalCycleSeconds != null) {
      buffer.writeln('Total response cycle (SOS → response complete): ${totalCycleSeconds}s');
    }
    _writeTimelineNarrative(buffer, inc);

    buffer.writeln();
    buffer.writeln('===== GOOD SAMARITAN SHIELD =====');
    buffer.writeln(goodSamaritanShieldText);

    return <String, dynamic>{
      'incidentId': inc.id,
      'userId': inc.userId,
      if ((inc.returnHospitalId ?? '').trim().isNotEmpty) 'acceptedHospitalId': inc.returnHospitalId!.trim(),
      'type': inc.type,
      'status': inc.status.name,
      'createdAt': now.toIso8601String(),
      'narrative': buffer.toString(),
      'triage': triage,
      if (inc.sharedSituationBrief != null) 'situationBrief': _jsonEncodable(inc.sharedSituationBrief),
      if (inc.preArrivalHandoff != null) 'preArrivalHandoff': _jsonEncodable(inc.preArrivalHandoff),
      if (aiSubset != null) 'aiTriage': aiSubset,
      if (inc.volunteerSceneReport != null) 'volunteerSceneReport': _jsonEncodable(inc.volunteerSceneReport),
      'fleetOperatorNotes': fleetForPayload,
      'patientProfile': Map<String, dynamic>.from(_jsonEncodable(patientProfile) as Map),
      if (videoAssessment != null)
        'videoAssessment': Map<String, dynamic>.from(_jsonEncodable(videoAssessment) as Map),
      'clinicalSynthesis': clinicalPayload,
      'timeline': timeline,
      'goodSamaritanShield': goodSamaritanShieldText,
      if (severityTier != null && severityTier.isNotEmpty) 'severityTier': severityTier,
      if (inc.emsRescueCompleteAt != null) 'emsRescueCompleteAt': inc.emsRescueCompleteAt!.toIso8601String(),
      if (inc.emsReturningStartedAt != null) 'emsReturningStartedAt': inc.emsReturningStartedAt!.toIso8601String(),
      if (inc.emsHospitalArrivalAt != null) 'emsHospitalArrivalAt': inc.emsHospitalArrivalAt!.toIso8601String(),
      if (inc.emsResponseCompleteAt != null) 'emsResponseCompleteAt': inc.emsResponseCompleteAt!.toIso8601String(),
      if (rescueDurationSeconds != null) 'rescueDurationSeconds': rescueDurationSeconds,
      if (returnDurationSeconds != null) 'returnDurationSeconds': returnDurationSeconds,
      if (totalCycleSeconds != null) 'totalCycleSeconds': totalCycleSeconds,
    };
  }

  /// One-tap plaintext for ER handoff / SMS (kept short for radio + clipboard).
  static String buildTriageHandoffCard(SosIncident inc) {
    final triage = inc.triage ?? const <String, dynamic>{};
    final ai = triage['aiVision'];
    String? sev = (triage['severity'] ?? triage['triageLevel'] ?? triage['level'])?.toString().trim();
    if ((sev == null || sev.isEmpty) && ai is Map) {
      sev = (ai['severity'] as String?)?.trim();
    }

    final rationale = inc.aiHospitalRationale ?? const <String, dynamic>{};
    final hosp = (rationale['hospitalName'] as String?)?.trim() ?? '';
    final ph = inc.preArrivalHandoff ?? const <String, dynamic>{};
    var snapLine = (ph['patientSnapshot'] as String?)?.trim() ?? '';
    if (snapLine.isNotEmpty) {
      final first = snapLine.split(RegExp(r'[\r\n]+')).map((s) => s.trim()).firstWhere((s) => s.isNotEmpty, orElse: () => snapLine);
      snapLine = first.length > 120 ? '${first.substring(0, 117)}...' : first;
    }

    final buf = StringBuffer()
      ..writeln('EMERGENCYOS PRE-ARRIVAL')
      ..writeln('ID: ${inc.id}')
      ..writeln('Type: ${inc.type}')
      ..writeln('Status: ${inc.status.name}')
      ..writeln('Pin: ${inc.liveVictimPin.latitude.toStringAsFixed(5)},${inc.liveVictimPin.longitude.toStringAsFixed(5)}');
    if (hosp.isNotEmpty) buf.writeln('Receiving: $hosp');
    if (snapLine.isNotEmpty) buf.writeln('Snapshot: $snapLine');
    if (sev != null && sev.isNotEmpty) buf.writeln('Triage: $sev');
    if ((inc.ambulanceEta ?? '').trim().isNotEmpty) {
      buf.writeln('Ambulance ETA: ${inc.ambulanceEta!.trim()}');
    }
    buf.writeln('Blood: ${inc.bloodType ?? "—"}');
    buf.writeln('Allergies: ${inc.allergies ?? "—"}');
    buf.writeln('Conditions: ${inc.medicalConditions ?? "—"}');
    if ((inc.emergencyContactPhone ?? '').trim().isNotEmpty) {
      buf.writeln('ICE phone: ${inc.emergencyContactPhone!.trim()}');
    }
    var s = buf.toString().trim();
    if (s.length > 480) s = '${s.substring(0, 477)}...';
    return s;
  }

  /// Generate and persist a report document under `sos_incidents/{id}/incident_reports`.
  static Future<void> generateAndStoreReport(SosIncident incident) async {
    final payload = await buildEnhancedReportPayload(incident);
    await _db.collection('sos_incidents').doc(incident.id).collection('incident_reports').add(<String, dynamic>{
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
