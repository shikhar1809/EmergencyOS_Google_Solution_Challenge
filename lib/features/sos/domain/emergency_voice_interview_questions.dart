import '../../../core/l10n/app_localizations.dart';

/// Fixed three-step victim interview on active SOS. Answers are stored under
/// `voiceInterview` on the incident for responder triage.
abstract final class EmergencyVoiceInterviewQuestions {
  static const String categoryAnswerKey = 'emergencyCategory';

  /// Chip label that opens a free-text "Other" detail dialog (Q1 only).
  static const String otherEmergencyTypeChipLabel = 'Other';

  static const String q1EmergencyTypeKey = 'q1_emergency_type';
  static const String q2SafetySeriousKey = 'q2_safety_serious';
  static const String q3PeopleCountKey = 'q3_people_count';

  static const List<String> situationTypeOptions = [
    'Accident',
    'Medical',
    'Hazard (fire, drowning, etc.)',
    'Assault',
    otherEmergencyTypeChipLabel,
  ];

  /// Legacy name — same as [situationTypeOptions] (onboarding / pickers).
  static const List<String> tappableCategories = situationTypeOptions;

  static const String describeKey = 'emergencyDescription';

  /// Normalizes incident / triage / chip labels to a scenario bucket (dispatch hints).
  static String bucketFor(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('assault')) return 'assault';
    if (s.contains('hazard') || s.contains('fire') || s.contains('drown')) return 'hazard';
    if (s.contains('accident') || s.contains('crash') || s.contains('collision') || s.contains('vehicle')) {
      return 'accident';
    }
    if (s.contains('medical')) return 'medical';
    if (s.contains('allergic') || s.contains('anaphyl')) return 'allergy';
    if (s.contains('seizure') || s.contains('convulsion')) return 'seizure';
    if (s.contains('poison') || s.contains('overdose')) return 'poison';
    if (s.contains('unconscious') || s.contains('unresponsive')) return 'unconscious';
    if (s.contains('head') || s.contains('spinal') || s.contains('spine')) return 'headspine';
    if (s.contains('cardiac') || (s.contains('heart') && s.contains('attack'))) return 'cardiac';
    if (s.contains('stroke') || s.contains('weakness')) return 'stroke';
    if (s.contains('chok') || s.contains('airway') || s.contains('breath')) return 'airway';
    if (s.contains('bleed') || s.contains('blood') || s.contains('hemorrh')) return 'bleeding';
    return 'generic';
  }

  /// Always the same three chip questions (type → safety/seriousness → headcount).
  static List<Map<String, String>> fixedInterviewFlow() => [
        {
          'key': q1EmergencyTypeKey,
          'prompt': 'What is happening? (type of emergency)',
          'type': 'chip',
          'options': situationTypeOptions.join('|'),
        },
        {
          'key': q2SafetySeriousKey,
          'prompt': 'Are you safe? How serious is it?',
          'type': 'chip',
          'options':
              'Critical (life-threatening)|Injured but stable|Not injured but in danger|Safe now',
        },
        {
          'key': q3PeopleCountKey,
          'prompt': 'How many people are involved?',
          'type': 'chip',
          'options': 'Only me|Two|More than two',
        },
      ];

  static List<Map<String, String>> flowForType(String? incidentOrTriageType) => fixedInterviewFlow();

  /// Same keys and English [options] as [fixedInterviewFlow] (for Firestore / triage logic);
  /// [prompt] and [labels] are localized for UI + TTS.
  static List<Map<String, String>> localizedFlow(AppLocalizations l) {
    final q1Labels = [
      l.get('sos_chip_cat_accident'),
      l.get('sos_chip_cat_medical'),
      l.get('sos_chip_cat_hazard'),
      l.get('sos_chip_cat_assault'),
      l.get('sos_chip_cat_other'),
    ];
    final q2Canon =
        'Critical (life-threatening)|Injured but stable|Not injured but in danger|Safe now';
    final q2Labels = [
      l.get('sos_chip_safe_critical'),
      l.get('sos_chip_safe_injured'),
      l.get('sos_chip_safe_danger'),
      l.get('sos_chip_safe_safe_now'),
    ];
    final q3Canon = 'Only me|Two|More than two';
    final q3Labels = [
      l.get('sos_chip_people_me'),
      l.get('sos_chip_people_two'),
      l.get('sos_chip_people_many'),
    ];
    return [
      {
        'key': q1EmergencyTypeKey,
        'prompt': l.get('sos_interview_q1_prompt'),
        'type': 'chip',
        'options': situationTypeOptions.join('|'),
        'labels': q1Labels.join('|'),
      },
      {
        'key': q2SafetySeriousKey,
        'prompt': l.get('sos_interview_q2_prompt'),
        'type': 'chip',
        'options': q2Canon,
        'labels': q2Labels.join('|'),
      },
      {
        'key': q3PeopleCountKey,
        'prompt': l.get('sos_interview_q3_prompt'),
        'type': 'chip',
        'options': q3Canon,
        'labels': q3Labels.join('|'),
      },
    ];
  }

  static final Map<String, String> promptsByAnswerKey = () {
    final m = <String, String>{};
    for (final q in fixedInterviewFlow()) {
      final k = q['key'];
      final p = q['prompt'];
      if (k != null && p != null && k.isNotEmpty && p.isNotEmpty) {
        m[k] = p;
      }
    }
    return m;
  }();

  static String? promptForAnswerKey(String key) {
    final k = key.trim();
    if (k.isEmpty) return null;
    return promptsByAnswerKey[k];
  }

  static String? promptForAnswerKeyWithL10n(String key, AppLocalizations l) {
    final k = key.trim();
    if (k.isEmpty) return null;
    switch (k) {
      case q1EmergencyTypeKey:
        return l.get('sos_interview_q1_prompt');
      case q2SafetySeriousKey:
        return l.get('sos_interview_q2_prompt');
      case q3PeopleCountKey:
        return l.get('sos_interview_q3_prompt');
      default:
        return promptForAnswerKey(k);
    }
  }
}
