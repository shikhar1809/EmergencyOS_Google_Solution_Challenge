import 'package:flutter/material.dart';

/// One quiz question for a Lifeline training level.
class LifelineQuiz {
  final String question;
  final List<String> choices;
  /// Index into [choices] for the correct answer.
  final int correctIndex;

  const LifelineQuiz({
    required this.question,
    required this.choices,
    required this.correctIndex,
  });
}

/// Gamified Lifeline level (Clash-style arena node).
class LifelineTrainingLevel {
  final int id;
  final String title;
  final String subtitle;
  final String youtubeVideoId;
  final List<LifelineInfographicStep> infographic;
  final LifelineQuiz quiz;
  final int xpReward;
  final Color accent;
  final IconData icon;
  final List<String> cautions;
  final List<String> redFlags;

  const LifelineTrainingLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.youtubeVideoId,
    required this.infographic,
    required this.quiz,
    this.xpReward = 100,
    required this.accent,
    required this.icon,
    this.cautions = const [],
    this.redFlags = const [],
  });
}

/// EmergencyOS: LifelineInfographicStep in lib/features/ai_assist/domain/lifeline_training_levels.dart.
class LifelineInfographicStep {
  final IconData icon;
  final String headline;
  final String detail;

  const LifelineInfographicStep({
    required this.icon,
    required this.headline,
    required this.detail,
  });
}

/// Fixed curriculum — order defines the path (level 1 = first node).
const List<LifelineTrainingLevel> kLifelineTrainingLevels = [
  LifelineTrainingLevel(
    id: 1,
    title: 'CPR basics',
    subtitle: 'Unresponsive & not breathing normally',
    youtubeVideoId: 'cosVBV96E2g',
    accent: Colors.redAccent,
    icon: Icons.monitor_heart_rounded,
    redFlags: [
      'Unresponsive and not breathing normally',
      'No pulse or only gasping breaths',
    ],
    cautions: [
      'Do not delay calling emergency services',
      'Do not stop compressions for long pauses',
      'Do not move victim if no immediate danger',
      'Allow full chest recoil between compressions',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.phone_in_talk_rounded,
        headline: 'Get help',
        detail: 'Call emergency services or tell someone to call — start CPR if not breathing normally.',
      ),
      LifelineInfographicStep(
        icon: Icons.compress_rounded,
        headline: 'Position',
        detail: 'Heel of hand on lower half of sternum; other hand on top, arms straight.',
      ),
      LifelineInfographicStep(
        icon: Icons.speed_rounded,
        headline: 'Depth & rate',
        detail: 'Push hard ~5–6 cm, 100–120/min, full chest recoil.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'When should you start CPR on an unresponsive adult?',
      choices: [
        'Only if you are a healthcare professional',
        'If they are not breathing normally or only gasping',
        'After waiting 5 minutes to see if they wake up',
        'Only if there is no pulse and you have an AED',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 2,
    title: 'Cardiac arrest rescue',
    subtitle: 'CPR + AED — start compressions, use the defibrillator early',
    youtubeVideoId: 'O_ahpK-VDDA',
    accent: Colors.redAccent,
    icon: Icons.monitor_heart_rounded,
    redFlags: [
      'Sudden collapse — unresponsive and not breathing normally',
      'Gasping only (agonal breathing) — treat as cardiac arrest',
      'No signs of life after checking responsiveness and breathing',
    ],
    cautions: [
      'Call emergency services and send for an AED immediately — don’t delay compressions',
      'Minimise pauses in chest compressions — full recoil between pushes',
      'Ensure nobody is touching the patient during AED analysis or shock',
      'Resume CPR right away after a shock (or if “no shock advised”)',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.phone_in_talk_rounded,
        headline: 'Call & fetch AED',
        detail: 'Start help and send someone for a defibrillator while you begin CPR.',
      ),
      LifelineInfographicStep(
        icon: Icons.compress_rounded,
        headline: 'High-quality CPR',
        detail: 'Centre of chest, 5–6 cm depth, 100–120/min, allow full chest recoil.',
      ),
      LifelineInfographicStep(
        icon: Icons.electrical_services_rounded,
        headline: 'AED on, pads on, follow prompts',
        detail: 'Bare dry chest; place pads as shown; clear the body before any shock.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'During cardiac arrest, after turning on an AED and attaching pads, you should:',
      choices: [
        'Remove the pads if the person looks pale',
        'Follow voice prompts and ensure everyone is clear before a shock',
        'Stop CPR permanently once the AED is attached',
        'Pour water on the chest to improve contact',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 3,
    title: 'AED essentials',
    subtitle: 'Turn it on — follow the voice',
    youtubeVideoId: 'O_ahpK-VDDA',
    accent: Colors.amberAccent,
    icon: Icons.electrical_services_rounded,
    redFlags: [
      'Cardiac arrest — no pulse, no breathing',
      'Wet environment near the patient',
    ],
    cautions: [
      'Ensure no one is touching the person during shock',
      'Do not use AED in standing water — move patient first',
      'Do not place pads over medication patches or pacemaker bumps',
      'Resume CPR immediately after shock delivery',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.power_settings_new_rounded,
        headline: 'Power on',
        detail: 'Open the case; the device will tell you each next step.',
      ),
      LifelineInfographicStep(
        icon: Icons.front_hand_rounded,
        headline: 'Bare chest',
        detail: 'Dry skin if possible; place pads as shown on diagrams.',
      ),
      LifelineInfographicStep(
        icon: Icons.warning_amber_rounded,
        headline: 'Clear!',
        detail: 'Nobody touching the person when the shock is delivered.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'Before the AED delivers a shock, you should:',
      choices: [
        'Keep compressions going',
        'Make sure no one is touching the person',
        'Pour water on the chest',
        'Remove the pads if the person moves',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 4,
    title: 'Breathing Problem/Blockage',
    subtitle: 'Open airway — look, listen, feel',
    youtubeVideoId: 'CpMxVSHCdLM',
    accent: Colors.lightBlueAccent,
    icon: Icons.air_rounded,
    redFlags: [
      'Cannot speak, cough, or breathe',
      'Turning blue (cyanosis) around lips or fingers',
      'Agonal gasps mistaken for normal breathing',
    ],
    cautions: [
      'Do not tilt head if spinal injury is suspected — use jaw thrust instead',
      'Do not spend more than 10 seconds checking breathing',
      'Do not confuse agonal gasps with normal breathing — begin CPR',
      'Place in recovery position only if breathing normally',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.air_rounded,
        headline: 'Head tilt / chin lift',
        detail: 'If no spinal injury suspected — opens the airway for rescue breaths.',
      ),
      LifelineInfographicStep(
        icon: Icons.visibility_rounded,
        headline: 'Check breathing',
        detail: 'No more than 10 seconds; normal breathing vs agonal gasps.',
      ),
      LifelineInfographicStep(
        icon: Icons.hotel_rounded,
        headline: 'Recovery position',
        detail: 'If breathing, place on side to keep airway clear.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'Agonal gasps can be mistaken for normal breathing. You should:',
      choices: [
        'Assume the person is fine',
        'Start CPR if the person is unresponsive with only gasping',
        'Wait one minute before acting',
        'Only use rescue breaths, no compressions',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 5,
    title: 'Choking (adult)',
    subtitle: 'Back blows & abdominal thrusts',
    youtubeVideoId: 'PA9hpOnvtCk',
    accent: Colors.orangeAccent,
    icon: Icons.no_food_rounded,
    redFlags: [
      'Cannot speak, cough, or breathe',
      'Turning blue or losing consciousness',
    ],
    cautions: [
      'Do not blind finger-sweep the mouth',
      'If coughing effectively, encourage cough only — do not intervene',
      'Use chest thrusts for pregnant or obese victims',
      'If unresponsive, begin CPR immediately and call EMS',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.record_voice_over_rounded,
        headline: 'Encourage cough',
        detail: 'If coughing effectively, stay with them — do not hit the back yet.',
      ),
      LifelineInfographicStep(
        icon: Icons.back_hand_rounded,
        headline: '5 back blows',
        detail: 'Between shoulder blades with heel of hand.',
      ),
      LifelineInfographicStep(
        icon: Icons.sports_martial_arts_rounded,
        headline: '5 thrusts',
        detail: 'Stand behind; fist above navel; quick inward-upward motion.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'For a conscious adult who cannot speak or breathe, first try:',
      choices: [
        'Giving water',
        '5 firm back blows, then abdominal thrusts',
        'CPR immediately while standing',
        'Driving them to hospital without calling EMS',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 6,
    title: 'Severe bleeding',
    subtitle: 'Pressure — tourniquet on limbs if trained',
    youtubeVideoId: 'NxO5LvgqZe0',
    accent: Colors.deepOrange,
    icon: Icons.water_drop_rounded,
    redFlags: [
      'Blood is spurting or pooling rapidly',
      'Signs of shock: pale, clammy, confused',
    ],
    cautions: [
      'Do not remove soaked dressing — add layers on top',
      'Do not loosen a tourniquet once tightened',
      'Never apply tourniquet to neck, chest, or abdomen',
      'Maintain uninterrupted pressure until EMS arrives',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.compress_rounded,
        headline: 'Direct pressure',
        detail: 'Firm pressure with cloth; add layers — do not remove soaked dressing.',
      ),
      LifelineInfographicStep(
        icon: Icons.watch_later_rounded,
        headline: 'Tourniquet time',
        detail: 'Note time applied; only on limbs, not neck/chest/abdomen.',
      ),
      LifelineInfographicStep(
        icon: Icons.trending_up_rounded,
        headline: 'Shock watch',
        detail: 'Pale, clammy, fast pulse — keep warm, monitor breathing.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'For life-threatening bleeding on an arm, after direct pressure fails and you are trained:',
      choices: [
        'Remove all dressings every minute',
        'Apply a tourniquet proximal to the wound and note the time',
        'Apply a tourniquet across the joint only',
        'Wait for the person to lose consciousness before acting',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 7,
    title: 'Stroke — FAST',
    subtitle: 'Time lost is brain lost',
    youtubeVideoId: '0nJmSvrDzdI',
    accent: Colors.indigoAccent,
    icon: Icons.psychology_rounded,
    redFlags: [
      'Sudden facial drooping or numbness',
      'Sudden arm weakness or drift',
      'Sudden speech difficulty or confusion',
      'Sudden severe headache with no known cause',
    ],
    cautions: [
      'Do not give aspirin or any medication',
      'Do not give food or drink — swallowing may be impaired',
      'Do not let the person "sleep it off" — every minute matters',
      'Note the exact time symptoms started for EMS',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.face_rounded,
        headline: 'Face',
        detail: 'Smile droop or uneven face.',
      ),
      LifelineInfographicStep(
        icon: Icons.accessibility_new_rounded,
        headline: 'Arms',
        detail: 'Both arms up — does one drift down?',
      ),
      LifelineInfographicStep(
        icon: Icons.schedule_rounded,
        headline: 'Time',
        detail: 'Call EMS immediately; note when last seen well.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'FAST stands for Face, Arms, Speech, and:',
      choices: ['Temperature', 'Time', 'Transport', 'Tablet'],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 8,
    title: 'Burns',
    subtitle: 'Cool, cover, call',
    youtubeVideoId: 'gfP9bYx6gQw',
    accent: Colors.deepOrangeAccent,
    icon: Icons.local_fire_department_rounded,
    redFlags: [
      'Breathing difficulty after smoke exposure',
      'Burns on face, neck, hands, or genitals',
      'Burns encircling a limb or the torso',
    ],
    cautions: [
      'Do not apply ice, toothpaste, or butter',
      'Do not burst blisters',
      'Do not apply ointments to severe burns',
      'Avoid very cold water and full-body cooling — use cool running water',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.water_drop_rounded,
        headline: 'Cool water',
        detail: '10–20 minutes running cool water — not ice.',
      ),
      LifelineInfographicStep(
        icon: Icons.watch_off_rounded,
        headline: 'Remove constricting items',
        detail: 'Rings/watches before swelling.',
      ),
      LifelineInfographicStep(
        icon: Icons.medication_liquid_rounded,
        headline: 'Loose cover',
        detail: 'Sterile dressing or clean cloth; severe/large burns → EMS.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'For a significant thermal burn, you should cool with:',
      choices: ['Ice directly on skin', 'Cool running water 10–20 minutes', 'Butter or oil', 'Hot water to "balance" the burn'],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 9,
    title: 'Shock & positioning',
    subtitle: 'Lie flat, legs up if safe',
    youtubeVideoId: 'CpMxVSHCdLM',
    accent: Colors.purpleAccent,
    icon: Icons.airline_seat_flat_rounded,
    redFlags: [
      'Pale, cold, clammy skin',
      'Rapid, weak pulse',
      'Confusion or decreasing consciousness',
    ],
    cautions: [
      'Do not elevate legs if spinal or major pelvic injury is suspected',
      'Do not give food or drink',
      'Do not leave victim alone — monitor breathing continuously',
      'Keep victim warm with blankets but do not overheat',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.horizontal_rule_rounded,
        headline: 'Lie down',
        detail: 'Flat on back unless spinal injury suspected.',
      ),
      LifelineInfographicStep(
        icon: Icons.height_rounded,
        headline: 'Legs elevated',
        detail: '~30 cm if no pelvic/spinal injury — improves blood return.',
      ),
      LifelineInfographicStep(
        icon: Icons.dry_cleaning_rounded,
        headline: 'Warmth',
        detail: 'Blanket; nothing to eat or drink.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'Leg elevation for shock is avoided when:',
      choices: [
        'The person feels cold',
        'Spinal or major pelvic injury is suspected',
        'EMS is 10 minutes away',
        'The person is pregnant',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 10,
    title: 'Scene command',
    subtitle: 'Safety, hazards, handoff to EMS',
    youtubeVideoId: 'PLQyyPIGrQ4',
    accent: Colors.tealAccent,
    icon: Icons.shield_rounded,
    redFlags: [
      'Major bleeding at scene',
      'Unconscious or worsening confusion in victim',
      'Breathing distress or chest pain',
    ],
    cautions: [
      'Do not enter an unsafe scene — protect yourself first',
      'Do not move victim unless immediate danger exists',
      'Do not give food or drink to an unstable victim',
      'Update EMS on any status changes during handoff',
    ],
    infographic: [
      LifelineInfographicStep(
        icon: Icons.shield_rounded,
        headline: 'Scene safe',
        detail: 'Traffic, fire, electricity, violence — protect yourself first.',
      ),
      LifelineInfographicStep(
        icon: Icons.flag_rounded,
        headline: 'Mark hazards',
        detail: 'Guide EMS in; brief on mechanism of injury.',
      ),
      LifelineInfographicStep(
        icon: Icons.handshake_rounded,
        headline: 'Handoff',
        detail: 'What you saw, what you did, times and allergies if known.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'The first priority at any emergency scene is:',
      choices: [
        'Filming for social media',
        'Your safety and the safety of bystanders',
        'Moving the patient immediately without looking',
        'Treating the most minor injury first',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 11,
    title: 'Anaphylaxis',
    subtitle: 'Severe allergy — use epinephrine fast',
    youtubeVideoId: 'CpMxVSHCdLM',
    accent: Colors.red,
    icon: Icons.vaccines_rounded,
    redFlags: [
      'Throat or tongue swelling — difficulty breathing',
      'Sudden drop in blood pressure / loss of consciousness',
      'Rash spreading rapidly with dizziness',
    ],
    cautions: [
      'Do NOT wait to see if symptoms improve — act immediately',
      'Epinephrine auto-injector: outer thigh, even through clothing',
      'Call EMS immediately even after epinephrine — effects last only 10–20 min',
      'Keep victim lying down with legs raised unless breathing is difficult',
    ],
    xpReward: 150,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.vaccines_rounded,
        headline: 'Epinephrine NOW',
        detail: 'Use auto-injector (EpiPen) on outer thigh — even through clothing.',
      ),
      LifelineInfographicStep(
        icon: Icons.call_rounded,
        headline: 'Call EMS',
        detail: 'Call 112 immediately — epinephrine buys 10–20 min, not a cure.',
      ),
      LifelineInfographicStep(
        icon: Icons.airline_seat_recline_extra_rounded,
        headline: 'Position',
        detail: 'Lie flat, legs raised. Sit up only if breathing is difficult.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'After administering epinephrine for anaphylaxis, you should:',
      choices: [
        'Consider the emergency over',
        'Call EMS immediately and monitor the person',
        'Give a second dose immediately as backup',
        'Make the person walk to stay alert',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 12,
    title: 'Drowning rescue',
    subtitle: 'Reach, throw, row — never jump in',
    youtubeVideoId: 'O_ahpK-VDDA',
    accent: Colors.blue,
    icon: Icons.pool_rounded,
    redFlags: [
      'Person is submerged or not moving in water',
      'Blue lips or face after removal from water',
      'Unconscious after water rescue — no breathing',
    ],
    cautions: [
      'Do NOT enter the water yourself unless trained — reach or throw first',
      'Spinal injury risk after diving accident — support the neck',
      'Begin CPR immediately after removing from water — do NOT wait for water to drain',
      'Hypothermia is likely — keep warm after rescue',
    ],
    xpReward: 150,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.open_with_rounded,
        headline: 'Reach or throw',
        detail: 'Extend a pole, rope, or clothing — then pull. Don\'t enter the water.',
      ),
      LifelineInfographicStep(
        icon: Icons.monitor_heart_rounded,
        headline: 'CPR on shore',
        detail: 'Start CPR immediately after pullingout — don\'t wait for water to drain.',
      ),
      LifelineInfographicStep(
        icon: Icons.thermostat_rounded,
        headline: 'Warm & monitor',
        detail: 'Remove wet clothing, cover with blanket; hypothermia risk is high.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'The safest first approach to a drowning victim is:',
      choices: [
        'Jump into the water immediately',
        'Reach, throw, or extend something from shore',
        'Shout at them to swim to you',
        'Wait for professional help before doing anything',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 13,
    title: 'Seizure first aid',
    subtitle: 'Protect, time, recover — never restrain',
    youtubeVideoId: 'gfP9bYx6gQw',
    accent: Colors.deepPurple,
    icon: Icons.flash_on_rounded,
    redFlags: [
      'Seizure lasting more than 5 minutes',
      'No return to consciousness after seizure ends',
      'First ever seizure in the person\'s life',
    ],
    cautions: [
      'Do NOT restrain the person — you could injure yourself or them',
      'Do NOT put anything in their mouth',
      'Do NOT give water or food until fully alert',
      'Time the seizure — duration is critical info for paramedics',
    ],
    xpReward: 120,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.shield_rounded,
        headline: 'Clear and cushion',
        detail: 'Remove hard objects; place something soft under the head.',
      ),
      LifelineInfographicStep(
        icon: Icons.timer_rounded,
        headline: 'Time it',
        detail: 'Note when it started — call EMS if over 5 minutes.',
      ),
      LifelineInfographicStep(
        icon: Icons.hotel_rounded,
        headline: 'Recovery position',
        detail: 'When convulsions stop, gently place on side to keep airway clear.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'During a seizure, you should:',
      choices: [
        'Forcefully hold them still to stop the movements',
        'Put a spoon or wallet in their mouth to protect the tongue',
        'Clear the area and protect from injury without restraining',
        'Immediately pour cold water over them',
      ],
      correctIndex: 2,
    ),
  ),
  LifelineTrainingLevel(
    id: 14,
    title: 'Snake / animal bite',
    subtitle: 'Immobilise — do NOT suck the venom',
    youtubeVideoId: 'cosVBV96E2g',
    accent: Colors.green,
    icon: Icons.pest_control_rounded,
    redFlags: [
      'Swelling spreading rapidly beyond the bite site',
      'Difficulty breathing or swallowing',
      'Blurred vision, dizziness, or vomiting after bite',
    ],
    cautions: [
      'Do NOT suck, cut, or apply tourniquets — these increase tissue damage',
      'Do NOT apply ice to the bite site',
      'Keep the bitten limb below heart level to slow venom spread',
      'Remove rings/watches from the bitten limb before swelling',
    ],
    xpReward: 120,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.do_not_touch_rounded,
        headline: 'Immobilise',
        detail: 'Keep bitten area still and below heart level — avoid movement.',
      ),
      LifelineInfographicStep(
        icon: Icons.watch_off_rounded,
        headline: 'Remove jewellery',
        detail: 'Rings and watches cause constriction when swelling starts.',
      ),
      LifelineInfographicStep(
        icon: Icons.photo_camera_rounded,
        headline: 'ID the snake (safely)',
        detail: 'Describe or photograph from safe distance — helps antivenin selection.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'The correct action immediately after a snakebite is to:',
      choices: [
        'Suck and spit the venom to remove it',
        'Apply a tight tourniquet above the bite',
        'Immobilise the limb below heart level and get to hospital',
        'Apply ice and elevate the bitten limb',
      ],
      correctIndex: 2,
    ),
  ),
  LifelineTrainingLevel(
    id: 15,
    title: 'Diabetic emergency',
    subtitle: 'Low blood sugar — give glucose fast',
    youtubeVideoId: 'PLQyyPIGrQ4',
    accent: Colors.orange,
    icon: Icons.water_drop_outlined,
    redFlags: [
      'Confusion, aggression, or unusual behaviour in a known diabetic',
      'Unconsciousness or seizure in a diabetic person',
      'Cold sweating with rapid heartbeat and pallor',
    ],
    cautions: [
      'Do NOT give anything by mouth if unconscious — risk of choking',
      'If in doubt between high/low, treat for low sugar — it\'s very rare to cause serious harm',
      'After sugar administration, monitor — relief should come within 10–15 minutes',
      'Do NOT leave alone until fully recovered',
    ],
    xpReward: 100,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.local_dining_rounded,
        headline: 'Sugar NOW (if conscious)',
        detail: '15–20g fast-acting sugar: juice, sweets, glucose gel, or sugar water.',
      ),
      LifelineInfographicStep(
        icon: Icons.timer_rounded,
        headline: 'Wait 15 minutes',
        detail: 'Recheck — if no improvement, repeat once. Call EMS if still unwell.',
      ),
      LifelineInfographicStep(
        icon: Icons.local_hospital_rounded,
        headline: 'Recovery meal',
        detail: 'Once alert, give a complex carbohydrate snack to stabilise levels.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'A known diabetic is confused and sweating. You should first:',
      choices: [
        'Tell them to take their insulin',
        'Give them fast-acting sugar if they are conscious',
        'Make them lie down and wait for EMS without giving anything',
        'Splash cold water on their face',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 16,
    title: 'Hypothermia & heat stroke',
    subtitle: 'Core temperature extremes — act quickly',
    youtubeVideoId: 'CpMxVSHCdLM',
    accent: Colors.cyan,
    icon: Icons.thermostat_rounded,
    redFlags: [
      'Hypothermia: shivering stops (severe stage) + confusion',
      'Heat stroke: body temp >40°C + confusion + dry skin',
      'Loss of consciousness in either condition',
    ],
    cautions: [
      'Hypothermia: Do NOT rub limbs vigorously — rewarming shock risk',
      'Hypothermia: Do NOT give alcohol',
      'Heat stroke: Do NOT give aspirin or paracetamol for fever',
      'Move the person out of the extreme environment immediately',
    ],
    xpReward: 150,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.wb_sunny_rounded,
        headline: 'Remove from environment',
        detail: 'Hypothermia: move to warmth. Heat stroke: move to cool, shaded area.',
      ),
      LifelineInfographicStep(
        icon: Icons.dry_cleaning_rounded,
        headline: 'Active temperature management',
        detail: 'Hypothermia: dry/warm layers. Heat stroke: cool wet cloths, fan, cold packs.',
      ),
      LifelineInfographicStep(
        icon: Icons.local_drink_rounded,
        headline: 'Hydration (if conscious)',
        detail: 'Warm sweet drinks for hypothermia; cool water for heat stroke.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'For heat stroke (hot, confused, no sweating), the priority is:',
      choices: [
        'Give paracetamol and wait',
        'Wrap in warm blankets to comfort them',
        'Move to cool area, apply cool wet cloths, and call EMS',
        'Make them walk to keep blood circulating',
      ],
      correctIndex: 2,
    ),
  ),
  LifelineTrainingLevel(
    id: 17,
    title: 'Accident / collision',
    subtitle: 'Scene safety first — then triage and call for help',
    youtubeVideoId: 'CpMxVSHCdLM',
    accent: Colors.blueGrey,
    icon: Icons.car_crash_rounded,
    redFlags: [
      'Vehicle fire, smoke, or fuel leak near casualties',
      'Unconscious or not breathing trapped in a vehicle',
      'Suspected spinal injury with neck pain after high-speed crash',
    ],
    cautions: [
      'Do NOT move casualties unless there is immediate danger (fire, traffic)',
      'Turn off ignition if safe; beware of airbags and traffic',
      'Do NOT remove helmets from motorcyclists unless airway is blocked',
      'Wear high-visibility clothing and use hazard lights if directing traffic',
    ],
    xpReward: 150,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.warning_amber_rounded,
        headline: 'Make the scene safe',
        detail: 'Park safely, hazards on, fire extinguisher if trained — protect yourself first.',
      ),
      LifelineInfographicStep(
        icon: Icons.phone_in_talk_rounded,
        headline: 'Call emergency services',
        detail: 'Give location, number of vehicles, injuries, and any fire or fuel leak.',
      ),
      LifelineInfographicStep(
        icon: Icons.medical_services_rounded,
        headline: 'Treat life threats',
        detail: 'Control severe bleeding with pressure; open airway if trained; reassure and cover.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'At a road collision, your first priority should be:',
      choices: [
        'Move every casualty out of the car immediately',
        'Make the scene safe and call emergency services',
        'Film the scene for social media before helping',
        'Disconnect the battery on every vehicle before checking victims',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 18,
    title: 'Asthma attack',
    subtitle: 'Sit upright — reliever inhaler — escalate if no improvement',
    youtubeVideoId: 'PLQyyPIGrQ4',
    accent: Colors.lightBlueAccent,
    icon: Icons.air_rounded,
    redFlags: [
      'Cannot speak in full sentences or too breathless to walk',
      'Blue lips or fingernails, or silent chest with little air movement',
      'No improvement after repeated doses of reliever inhaler',
    ],
    cautions: [
      'Do NOT lie the person flat — sitting upright helps breathing effort',
      'Do NOT give sedatives or “calming” drinks — focus on prescribed reliever',
      'If they have an asthma action plan, follow it',
      'Call EMS if symptoms are severe or not improving within minutes',
    ],
    xpReward: 120,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.chair_rounded,
        headline: 'Sit them upright',
        detail: 'Loosen tight clothing; stay calm; reassure — leaning slightly forward can help.',
      ),
      LifelineInfographicStep(
        icon: Icons.medication_liquid_rounded,
        headline: 'Reliever inhaler',
        detail: 'Usually blue “rescue” inhaler: 1 puff via spacer, repeat per plan or 4 puffs spaced.',
      ),
      LifelineInfographicStep(
        icon: Icons.phone_in_talk_rounded,
        headline: 'Escalate care',
        detail: 'If no quick improvement, worsening, or exhaustion — call emergency services.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'During a severe asthma attack, positioning should be:',
      choices: [
        'Flat on their back with legs raised',
        'Sitting upright, leaning slightly forward if comfortable',
        'Head-down in a chair',
        'Walking fast to “clear the lungs”',
      ],
      correctIndex: 1,
    ),
  ),
  LifelineTrainingLevel(
    id: 19,
    title: 'Seizure',
    subtitle: 'Time the episode — protect from injury — call EMS if prolonged',
    youtubeVideoId: 'gfP9bYx6gQw',
    accent: Colors.indigoAccent,
    icon: Icons.flash_on_rounded,
    redFlags: [
      'Seizure lasts longer than 5 minutes or repeats without full recovery',
      'First seizure ever, pregnancy, diabetes, or injury during the seizure',
      'Breathing difficulty or cyanosis during or after the event',
    ],
    cautions: [
      'Do NOT restrain movements or put anything in the mouth',
      'Do NOT give food or drink until fully awake and alert',
      'Clear hard or sharp objects; cushion the head with something soft',
      'Note start time — duration guides when to call emergency services',
    ],
    xpReward: 120,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.shield_rounded,
        headline: 'Protect the space',
        detail: 'Ease them to floor if safe; move furniture away; cushion head.',
      ),
      LifelineInfographicStep(
        icon: Icons.timer_rounded,
        headline: 'Time it',
        detail: 'Start a timer — call EMS if convulsions exceed ~5 minutes.',
      ),
      LifelineInfographicStep(
        icon: Icons.hotel_rounded,
        headline: 'After it stops',
        detail: 'Place in recovery position when breathing normally; stay with them; reassure.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'You should call emergency services during a seizure when:',
      choices: [
        'It is the person’s first seizure, lasts over 5 minutes, or another starts without recovery',
        'The person is still blinking normally',
        'They have a known epilepsy diagnosis and recover quickly as usual',
        'Only if they ask you politely to call',
      ],
      correctIndex: 0,
    ),
  ),
  LifelineTrainingLevel(
    id: 20,
    title: 'Foreign object penetration',
    subtitle: 'Stabilise the object — do not remove deep impalements',
    youtubeVideoId: 'cosVBV96E2g',
    accent: Colors.deepOrange,
    icon: Icons.healing_rounded,
    redFlags: [
      'Object in chest, neck, eye, or abdomen with heavy bleeding',
      'Object moves with breathing or pulse (possible major vessel injury)',
      'Person is shocked, confused, or breathing poorly',
    ],
    cautions: [
      'Do NOT pull out a deeply embedded object — it may be plugging a vessel',
      'Do NOT push the object further in while dressing',
      'Control bleeding around (not through) the object with bulky dressings',
      'Immobilise the object and limb; treat for shock; urgent EMS transport',
    ],
    xpReward: 150,
    infographic: [
      LifelineInfographicStep(
        icon: Icons.back_hand_rounded,
        headline: 'Leave it in place',
        detail: 'Deep penetration: stabilise with dressings around the object to prevent movement.',
      ),
      LifelineInfographicStep(
        icon: Icons.compress_rounded,
        headline: 'Bleeding control',
        detail: 'Apply pressure beside the entry site; build up padding — never lever the object.',
      ),
      LifelineInfographicStep(
        icon: Icons.local_hospital_rounded,
        headline: 'Immobilise & EMS',
        detail: 'Support the injured part in the position found; minimal movement; call emergency services.',
      ),
    ],
    quiz: LifelineQuiz(
      question: 'A screwdriver is stuck deep in someone’s forearm and bleeding. You should:',
      choices: [
        'Pull it out quickly to let the wound drain',
        'Stabilise it in place, pad around it, apply pressure beside it, and get EMS',
        'Twist it slightly to “check if it’s loose”',
        'Wait until bleeding stops completely before calling for help',
      ],
      correctIndex: 1,
    ),
  ),
];
