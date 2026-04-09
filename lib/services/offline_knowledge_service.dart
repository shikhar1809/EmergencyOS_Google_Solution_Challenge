/// Offline Emergency Knowledge Base
/// A local lookup table of emergency Q&A pairs.
/// Used as a fallback when Gemini API is unreachable (no internet).
class OfflineKnowledgeService {
  static const String _noInternetPrefix =
      '⚠️ OFFLINE MODE — Gemini AI unavailable. Here is stored guidance:\n\n';

  /// Returns a stored answer if a keyword matches, otherwise returns null.
  static String? lookup(String query) {
    final q = query.toLowerCase();

    // ── CPR ──────────────────────────────────────────────────────────────────
    if (_matches(q, ['cpr', 'not breathing', 'cardiac arrest', 'chest compression', 'heart stopped', 'no pulse'])) {
      return _noInternetPrefix + '''
🫀 **CPR — Adult Protocol**

1. Call 112 immediately or have someone else call.
2. Lay the victim flat on a firm surface.
3. Tilt head back, lift chin — check for breathing (10 sec).
4. If not breathing: **30 chest compressions** at 100–120/min.
   - Place heel of hand on centre of chest (lower half of breastbone).
   - Compress 5–6 cm deep. Allow full chest recoil.
5. **2 rescue breaths** (pinch nose, seal mouth, 1 sec each).
6. Repeat 30:2 cycle until EMS arrives or victim breathes normally.

⚡ If AED is available: power on, follow prompts.
''';
    }

    // ── Bleeding ─────────────────────────────────────────────────────────────
    if (_matches(q, ['bleeding', 'blood', 'wound', 'cut', 'laceration', 'haemorrhage', 'hemorrhage'])) {
      return _noInternetPrefix + '''
🩸 **Severe Bleeding Control**

1. Apply **direct pressure** with a clean cloth or bandage. Press hard.
2. Do NOT remove the cloth — add more layers if soaked.
3. For limbs: elevate above heart level if no fracture suspected.
4. If bleeding uncontrolled after 10 min:
   - Apply a tourniquet 5–7 cm above wound (limb only).
   - Note the time applied.
5. Keep victim warm and still. Treat for shock (lay flat, raise legs).
6. Call 112 — uncontrolled bleeding is life-threatening.
''';
    }

    // ── Choking ──────────────────────────────────────────────────────────────
    if (_matches(q, ['choking', 'airway', 'heimlich', 'can\'t breathe', 'obstruction', 'blocked throat'])) {
      return _noInternetPrefix + '''
🫁 **Choking — Conscious Adult**

1. Ask: "Are you choking?" — if they cannot speak/cough:
2. **5 back blows**: Lean victim forward, give 5 firm blows between shoulder blades with the heel of your hand.
3. **5 abdominal thrusts (Heimlich)**: Stand behind victim, wrap arms around waist. Fist above navel, thumb side in. Pull sharply inward and upward.
4. Alternate 5 back blows + 5 abdominal thrusts.
5. If victim becomes unconscious → start CPR immediately.

⚠️ For pregnant women or obese victims: use chest thrusts instead of abdominal thrusts.
''';
    }

    // ── Stroke ───────────────────────────────────────────────────────────────
    if (_matches(q, ['stroke', 'face drooping', 'slurred', 'facial droop', 'sudden weakness', 'fast test'])) {
      return _noInternetPrefix + '''
🧠 **Stroke — FAST Assessment**

- **F**ace: Ask to smile — does one side droop?
- **A**rms: Raise both arms — does one drift down?
- **S**peech: Repeat a sentence — is speech slurred or strange?
- **T**ime: If ANY of the above → call 112 **immediately**.

⚠️ Time-critical — every minute counts. Do NOT give food or water.
Lay the victim on their side (recovery position) if unconscious.
''';
    }

    // ── Burns ─────────────────────────────────────────────────────────────────
    if (_matches(q, ['burn', 'fire burn', 'scald', 'chemical burn', 'heat'])) {
      return _noInternetPrefix + '''
🔥 **Burns First Aid**

1. Remove victim from the burning source. Do NOT pull burning clothing.
2. Cool the burn under **cool (not cold) running water for 20 minutes**.
3. Do NOT use butter, toothpaste, or ice.
4. Cover loosely with cling film or a clean non-fluffy cloth.
5. For severe burns (palm-size or larger) or face/hands: call 112.
6. Raise burned limbs above heart level.
''';
    }

    // ── Fracture ─────────────────────────────────────────────────────────────
    if (_matches(q, ['fracture', 'broken bone', 'broken arm', 'broken leg', 'splint', 'deformity'])) {
      return _noInternetPrefix + '''
🦴 **Fracture (Broken Bone)**

1. Do NOT try to realign or straighten the limb.
2. Immobilise using a splint (rigid support — board, rolled magazine).
3. Pad around the injury for comfort.
4. For open fractures (bone visible): Cover with clean dressing. Do NOT push bone back in.
5. Elevate the injury if possible.
6. Monitor circulation below the break: skin colour, warmth, sensation, movement.
7. Call 112 for all fractures above elbow/knee or if open.
''';
    }

    // ── Drowning ─────────────────────────────────────────────────────────────
    if (_matches(q, ['drowning', 'water rescue', 'drowned', 'pulled from water'])) {
      return _noInternetPrefix + '''
🌊 **Drowning**

1. Get victim out of water safely. Do NOT risk your own life.
2. Check response — call 112.
3. Start CPR immediately if not breathing (30:2 cycle).
4. Keep victim warm — risk of hypothermia is high.
5. Do NOT tilt head if spinal injury suspected.

⚠️ Always call 112 even if victim appears recovered — secondary drowning risk for 24 hours.
''';
    }

    // ── Shock ─────────────────────────────────────────────────────────────────
    if (_matches(q, ['shock', 'pale', 'sweating', 'fast pulse', 'collapse', 'faint'])) {
      return _noInternetPrefix + '''
😰 **Shock (Circulatory)**

1. Lay victim flat; raise legs 30 cm unless head/spine/leg injury suspected.
2. Loosen tight clothing.
3. Keep warm — use a blanket or jacket.
4. Do NOT give food or water.
5. Monitor breathing and pulse continuously.
6. Call 112 — shock is life-threatening.
''';
    }

    // ── Snake Bite ────────────────────────────────────────────────────────────
    if (_matches(q, ['snake', 'bite', 'venom', 'poison'])) {
      return _noInternetPrefix + '''
🐍 **Snake Bite**

1. Move victim away from the snake immediately.
2. Keep victim calm and still — movement spreads venom faster.
3. Immobilise the bitten limb below heart level.
4. Remove rings, watches, tight clothing near the bite.
5. Do NOT cut the wound, suck out venom, or apply tourniquet.
6. Note the time of the bite. Describe the snake if safely possible.
7. Call 112 urgently.
''';
    }

    // ── Unconscious ──────────────────────────────────────────────────────────
    if (_matches(q, ['unconscious', 'unresponsive', 'passed out', 'recovery position', 'not waking'])) {
      return _noInternetPrefix + '''
😶 **Unconscious but Breathing**

1. Call 112.
2. Place in **recovery position**: victim on their side, head tilted back to keep airway open.
3. Bend the upper knee forward to stabilise.
4. Monitor breathing continuously.
5. Reassess every 2–3 minutes.

If breathing STOPS → begin CPR immediately.
''';
    }

    // ── Hypothermia ───────────────────────────────────────────────────────────
    if (_matches(q, ['hypothermia', 'freezing', 'cold exposure', 'shivering', 'body temperature'])) {
      return _noInternetPrefix + '''
🥶 **Hypothermia**

1. Move victim to a warm, sheltered area.
2. Remove wet clothing carefully.
3. Cover with blankets, focus on core (chest, neck, groin) — NOT hands/feet.
4. Give warm (not hot) sweet drinks if conscious.
5. Warm the room, not direct heat on skin.
6. Call 112 for severe cases (confusion, slurred speech, stiff muscles).
''';
    }

    // ── General ───────────────────────────────────────────────────────────────
    return null; // No match found
  }

  static bool _matches(String query, List<String> keywords) {
    return keywords.any((kw) => query.contains(kw));
  }

  /// Lightweight scenario classifier for low/no-network operation.
  /// Returns one of the Lifeline scenario labels if detected, else null.
  static String? classifyScenario(String query) {
    final q = query.toLowerCase();
    if (_matches(q, ['crash', 'accident', 'car', 'bike', 'truck', 'collision', 'hit and run'])) {
      return 'Traffic Collision';
    }
    if (_matches(q, ['not breathing', 'no pulse', 'unresponsive', 'cardiac arrest', 'cpr', 'aed'])) {
      return 'Cardiac Arrest';
    }
    if (_matches(q, ['bleeding', 'blood', 'amputation', 'hemorrhage', 'haemorrhage'])) {
      return 'Severe Bleeding';
    }
    if (_matches(q, ['fire', 'smoke', 'burning', 'explosion', 'gas leak'])) {
      return 'Fire / Smoke';
    }
    if (_matches(q, ['drowning', 'water', 'pool', 'river', 'lake'])) {
      return 'Drowning';
    }
    return null;
  }

  /// Short scenario anchor when there is no keyword match and no AI (poor / no network).
  static String scenarioQuickGuide(String scenario) {
    const p =
        '📴 **LOCAL GUIDE** (AI unavailable). Use these steps until help arrives:\n\n';
    switch (scenario) {
      case 'Traffic Collision':
        return p +
            '1. Make the scene safe — hazards off, lights on.\n'
            '2. Call 112 (or local emergency) — say location and injuries.\n'
            '3. Do not move the person if neck/back pain or unconscious — support head/neck.\n'
            '4. Stop severe bleeding with firm direct pressure; limbs only: tourniquet if trained.\n'
            '5. If not breathing normally — start CPR and use AED if available.';
      case 'Cardiac Arrest':
        return p +
            '1. Confirm unresponsive and not breathing normally.\n'
            '2. Call 112 and get an AED.\n'
            '3. Start hard, fast chest compressions centre of chest 100–120/min, depth 5–6 cm.\n'
            '4. Use AED as soon as it arrives — follow voice prompts.\n'
            '5. Continue CPR until EMS takes over or the person responds.';
      case 'Severe Bleeding':
        return p +
            '1. Apply firm direct pressure with cloth — do not remove soaked layers; add on top.\n'
            '2. Raise limb above heart if no obvious fracture.\n'
            '3. If life-threatening limb bleeding — tourniquet high and tight; note time applied.\n'
            '4. Lay person down, treat for shock — keep warm.\n'
            '5. Call 112 — say “heavy bleeding”.';
      case 'Fire / Smoke':
        return p +
            '1. Move everyone away from smoke — stay low if you must pass through smoke.\n'
            '2. Call fire/emergency — give address.\n'
            '3. Stop, drop, and roll if clothes are on fire; cool small burns with cool water 20 min.\n'
            '4. Do not re-enter the building.\n'
            '5. Monitor breathing — give oxygen only if trained; support airway if drowsy.';
      case 'Drowning':
        return p +
            '1. Only enter water if safe — use reach/throw; do not become a second victim.\n'
            '2. Get the person out, call 112.\n'
            '3. If not breathing — start CPR immediately.\n'
            '4. Keep them warm; even if they “feel fine”, they need medical review.\n'
            '5. Protect cervical spine if shallow-water dive injury suspected.';
      default:
        return p +
            '1. Call 112 — state location and what you see.\n'
            '2. Check responsiveness and breathing.\n'
            '3. Control catastrophic bleeding first.\n'
            '4. Open airway, rescue breaths if trained and safe.\n'
            '5. Stay on the line with the dispatcher — they will guide you.';
    }
  }

  /// A general offline greeting shown when no keyword matches.
  static String offlineFallback(String query) {
    return '''⚠️ **OFFLINE MODE** — No Gemini AI available.

Your question: *"$query"*

I couldn\'t find a direct match in my offline knowledge base. Here are the built-in emergency guides available:

• 🫀 CPR / Cardiac Arrest
• 🩸 Bleeding Control
• 🫁 Choking (Heimlich)
• 🧠 Stroke (FAST test)
• 🔥 Burns
• 🦴 Fractures
• 🌊 Drowning
• 😰 Shock
• 🐍 Snake Bite
• 😶 Unconscious Victim
• 🥶 Hypothermia

Type any of the above keywords for stored offline guidance. Or reconnect to get full Gemini AI support.
''';
  }
}
