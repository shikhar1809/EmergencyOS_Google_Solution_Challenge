import 'package:flutter/material.dart';

/// EmergencyOS: ProtocolStep in lib/features/ai_assist/domain/protocol_engine.dart.
class ProtocolStep {
  final String id;
  final String action;
  final String why;
  final String caution;
  final int reminderSeconds;

  const ProtocolStep({
    required this.id,
    required this.action,
    required this.why,
    required this.caution,
    this.reminderSeconds = 0,
  });
}

/// EmergencyOS: ProtocolFlow in lib/features/ai_assist/domain/protocol_engine.dart.
class ProtocolFlow {
  final String id;
  final String title;
  final List<String> redFlags;
  final List<String> dontDo;
  final List<ProtocolStep> steps;
  final Color color;

  const ProtocolFlow({
    required this.id,
    required this.title,
    required this.redFlags,
    required this.dontDo,
    required this.steps,
    required this.color,
  });
}

/// EmergencyOS: ProtocolEngine in lib/features/ai_assist/domain/protocol_engine.dart.
class ProtocolEngine {
  static ProtocolFlow forScenario(String scenario) {
    final s = scenario.toLowerCase();
    if (s.contains('cardiac')) return _cpr();
    if (s.contains('bleeding')) return _bleeding();
    if (s.contains('fire') || s.contains('smoke') || s.contains('burn')) return _burns();
    if (s.contains('drowning')) return _chokingOrAirway();
    if (s.contains('collision') || s.contains('accident') || s.contains('traffic')) return _trauma();
    return _general();
  }

  static ProtocolFlow _cpr() => const ProtocolFlow(
        id: 'cpr',
        title: 'CPR Protocol',
        color: Colors.redAccent,
        redFlags: [
          'Unresponsive and not breathing normally',
          'No pulse or only gasping breaths',
        ],
        dontDo: [
          'Do not delay emergency call',
          'Do not stop compressions for long pauses',
        ],
        steps: [
          ProtocolStep(
            id: 'scene',
            action: 'Check scene safety and shout for help.',
            why: 'Prevents additional injuries and gets support early.',
            caution: 'Do not move victim if immediate danger is absent.',
          ),
          ProtocolStep(
            id: 'call',
            action: 'Call emergency services and request AED immediately.',
            why: 'Definitive care is required; CPR buys time.',
            caution: 'Use speakerphone to keep hands free.',
          ),
          ProtocolStep(
            id: 'compressions',
            action: 'Start chest compressions at 100-120/min, depth 5-6 cm.',
            why: 'Maintains blood flow to brain and heart.',
            caution: 'Allow full chest recoil between compressions.',
            reminderSeconds: 30,
          ),
          ProtocolStep(
            id: 'ratio',
            action: 'After 30 compressions, give 2 rescue breaths if trained.',
            why: 'Supports oxygen delivery.',
            caution: 'Skip breaths if not trained; continue compressions.',
          ),
          ProtocolStep(
            id: 'aed',
            action: 'Apply AED as soon as available and follow prompts.',
            why: 'Early defibrillation improves survival.',
            caution: 'Ensure no one touches victim during shock analysis.',
          ),
        ],
      );

  static ProtocolFlow _bleeding() => const ProtocolFlow(
        id: 'bleeding',
        title: 'Severe Bleeding Protocol',
        color: Colors.deepOrange,
        redFlags: [
          'Blood is spurting/pooling rapidly',
          'Signs of shock: pale, clammy, confused',
        ],
        dontDo: [
          'Do not remove soaked dressing; add layers on top',
          'Do not loosen a tourniquet once tightened',
        ],
        steps: [
          ProtocolStep(
            id: 'call',
            action: 'Call emergency services first.',
            why: 'Major blood loss can become fatal within minutes.',
            caution: 'Use speakerphone while applying pressure.',
          ),
          ProtocolStep(
            id: 'pressure',
            action: 'Apply firm direct pressure with clean cloth or gloved hand.',
            why: 'Direct pressure is first-line bleeding control.',
            caution: 'Maintain uninterrupted pressure.',
            reminderSeconds: 20,
          ),
          ProtocolStep(
            id: 'tourniquet',
            action: 'If limb bleeding continues, apply tourniquet 5-8 cm above wound.',
            why: 'Tourniquet can stop life-threatening extremity bleeding.',
            caution: 'Never apply to neck/chest/abdomen.',
          ),
          ProtocolStep(
            id: 'record',
            action: 'Record tourniquet application time and monitor consciousness.',
            why: 'Critical handoff detail for responders.',
            caution: 'Keep victim warm and still.',
          ),
        ],
      );

  static ProtocolFlow _chokingOrAirway() => const ProtocolFlow(
        id: 'airway',
        title: 'Airway / Choking Protocol',
        color: Colors.orange,
        redFlags: [
          'Cannot speak, cough, or breathe',
          'Turning blue or losing consciousness',
        ],
        dontDo: [
          'Do not blind finger-sweep the mouth',
          'Do not delay emergency call',
        ],
        steps: [
          ProtocolStep(
            id: 'assess',
            action: 'Confirm severe airway obstruction (silent, weak/no cough).',
            why: 'Distinguishes mild choking from severe choking.',
            caution: 'If coughing effectively, encourage cough only.',
          ),
          ProtocolStep(
            id: 'backblows',
            action: 'Give 5 firm back blows between shoulder blades.',
            why: 'Can dislodge obstruction quickly.',
            caution: 'Support chest while delivering blows.',
          ),
          ProtocolStep(
            id: 'thrusts',
            action: 'Give 5 abdominal thrusts; alternate with back blows.',
            why: 'Creates pressure to expel blockage.',
            caution: 'Use chest thrusts for pregnant/obese victims.',
          ),
          ProtocolStep(
            id: 'unresponsive',
            action: 'If unresponsive, begin CPR and call emergency services.',
            why: 'Cardiac arrest risk is high with prolonged hypoxia.',
            caution: 'Use AED if available.',
          ),
        ],
      );

  static ProtocolFlow _burns() => const ProtocolFlow(
        id: 'burns',
        title: 'Burn / Smoke Protocol',
        color: Colors.amber,
        redFlags: [
          'Breathing difficulty after smoke exposure',
          'Burns on face, neck, hands, or genitals',
        ],
        dontDo: [
          'Do not apply ice, toothpaste, or butter',
          'Do not burst blisters',
        ],
        steps: [
          ProtocolStep(
            id: 'remove',
            action: 'Move away from heat/smoke source safely.',
            why: 'Prevents ongoing tissue and airway damage.',
            caution: 'Do not re-enter unsafe area.',
          ),
          ProtocolStep(
            id: 'cool',
            action: 'Cool burn under clean running water for 20 minutes.',
            why: 'Reduces burn depth and pain.',
            caution: 'Avoid very cold water and full-body cooling.',
            reminderSeconds: 20,
          ),
          ProtocolStep(
            id: 'cover',
            action: 'Cover with sterile/non-fluffy dressing or clean cloth.',
            why: 'Protects wound from contamination.',
            caution: 'Do not apply ointments to severe burns.',
          ),
          ProtocolStep(
            id: 'call',
            action: 'Call emergency services for severe burns or smoke inhalation.',
            why: 'Airway injury can worsen quickly.',
            caution: 'Monitor breathing continuously.',
          ),
        ],
      );

  static ProtocolFlow _trauma() => const ProtocolFlow(
        id: 'trauma',
        title: 'Trauma Primary Survey (C-ABCDE)',
        color: Colors.purpleAccent,
        redFlags: [
          'Major bleeding',
          'Unconscious or worsening confusion',
          'Breathing distress or chest pain',
        ],
        dontDo: [
          'Do not move victim unless immediate danger exists',
          'Do not give food/drink to unstable victim',
        ],
        steps: [
          ProtocolStep(
            id: 'catastrophic',
            action: 'Control catastrophic bleeding first.',
            why: 'Massive hemorrhage kills fastest.',
            caution: 'Use direct pressure or tourniquet as needed.',
          ),
          ProtocolStep(
            id: 'airway',
            action: 'Check airway and clear only visible obstructions.',
            why: 'Airway patency is essential for oxygenation.',
            caution: 'Avoid blind sweeps.',
          ),
          ProtocolStep(
            id: 'breathing',
            action: 'Check breathing rate/effort and chest movement.',
            why: 'Detects respiratory compromise early.',
            caution: 'Prepare to start CPR if breathing stops.',
          ),
          ProtocolStep(
            id: 'circulation',
            action: 'Assess pulse, skin color, and signs of shock.',
            why: 'Guides urgency while awaiting responders.',
            caution: 'Keep victim warm and reassured.',
          ),
          ProtocolStep(
            id: 'neuro',
            action: 'Check responsiveness and pupils; track changes.',
            why: 'Neurological decline needs urgent escalation.',
            caution: 'Report changes to responders immediately.',
          ),
        ],
      );

  static ProtocolFlow _general() => const ProtocolFlow(
        id: 'general',
        title: 'General Emergency Protocol',
        color: Colors.blueGrey,
        redFlags: [
          'Unconsciousness',
          'Severe breathing trouble',
          'Uncontrolled bleeding',
        ],
        dontDo: [
          'Do not delay emergency call in critical signs',
          'Do not leave victim alone unless unsafe',
        ],
        steps: [
          ProtocolStep(
            id: 'call',
            action: 'Call emergency services and keep line open.',
            why: 'Dispatcher guidance plus rapid response.',
            caution: 'Share exact location and landmarks.',
          ),
          ProtocolStep(
            id: 'survey',
            action: 'Perform quick C-ABCDE check and prioritize threats.',
            why: 'Structured triage improves outcomes.',
            caution: 'Treat catastrophic bleeding first.',
          ),
          ProtocolStep(
            id: 'support',
            action: 'Provide immediate aid and monitor until help arrives.',
            why: 'Continuous support prevents deterioration.',
            caution: 'Update responders on any status changes.',
          ),
        ],
      );
}

