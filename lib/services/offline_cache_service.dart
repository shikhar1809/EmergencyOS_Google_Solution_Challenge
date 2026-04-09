import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Offline Cache Service
// Caches Places results, incidents, and pre-loaded trauma protocols
// ---------------------------------------------------------------------------

/// EmergencyOS: OfflineCacheService in lib/services/offline_cache_service.dart.
class OfflineCacheService {
  static const _placesKey = 'cached_places_';
  static const _packPlacesKey = 'offline_pack_places_';
  static const _pastArchiveKey = 'cached_past_incidents_archive_v1';
  static const _protocolsKey = 'cached_protocols';
  static const int _placesTtlMinutes = 30;
  static const int _packPlacesTtlDays = 30;

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _seedProtocolsIfNeeded();
  }

  // ─── Places Cache ─────────────────────────────────────────────────────────

  static Future<void> savePlaces(String type, List<Map<String, dynamic>> places) async {
    final prefs = _prefs!;
    final data = json.encode({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'data': places,
    });
    await prefs.setString('$_placesKey$type', data);
  }

  static List<Map<String, dynamic>>? loadPlaces(String type) {
    final prefs = _prefs;
    if (prefs == null) return null;
    final raw = prefs.getString('$_placesKey$type');
    if (raw == null) return null;
    try {
      final parsed = json.decode(raw) as Map<String, dynamic>;
      final ts = parsed['ts'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _placesTtlMinutes * 60 * 1000) return null; // stale
      final data = (parsed['data'] as List).cast<Map<String, dynamic>>();
      // Empty results must not be treated as cache hits — they block live Places fetches.
      if (data.isEmpty) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Long-lived snapshot for offline map / navigation (refreshed after each successful online fetch).
  static Future<void> saveOfflinePackPlaces(String type, List<Map<String, dynamic>> places) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (places.isEmpty) return;
    final data = json.encode({'ts': DateTime.now().millisecondsSinceEpoch, 'data': places});
    await prefs.setString('$_packPlacesKey$type', data);
  }

  static List<Map<String, dynamic>>? loadOfflinePackPlaces(String type) {
    final prefs = _prefs;
    if (prefs == null) return null;
    final raw = prefs.getString('$_packPlacesKey$type');
    if (raw == null) return null;
    try {
      final parsed = json.decode(raw) as Map<String, dynamic>;
      final ts = parsed['ts'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _packPlacesTtlDays * 24 * 60 * 60 * 1000) return null;
      final data = (parsed['data'] as List).cast<Map<String, dynamic>>();
      if (data.isEmpty) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePastIncidentsArchive(List<Map<String, dynamic>> incidents) async {
    await _prefs?.setString(_pastArchiveKey, json.encode(incidents));
  }

  static List<Map<String, dynamic>> loadPastIncidentsArchive() {
    try {
      final raw = _prefs?.getString(_pastArchiveKey);
      if (raw == null) return [];
      final list = json.decode(raw);
      if (list is! List) return [];
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ─── Trauma Protocols (Offline LIFELINE fallback) ─────────────────────────

  static Future<void> _seedProtocolsIfNeeded() async {
    final prefs = _prefs!;
    if (prefs.containsKey(_protocolsKey)) return;
    await prefs.setString(_protocolsKey, json.encode(_builtInProtocols));
  }

  static List<Map<String, dynamic>> getOfflineProtocols() {
    try {
      final raw = _prefs?.getString(_protocolsKey);
      if (raw == null) return _builtInProtocols;
      return (json.decode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return _builtInProtocols;
    }
  }

  // ─── Last Incidents Cache ─────────────────────────────────────────────────

  static Future<void> saveIncidents(List<Map<String, dynamic>> incidents) async {
    await _prefs?.setString('cached_incidents', json.encode(incidents));
  }

  static List<Map<String, dynamic>> loadIncidents() {
    try {
      final raw = _prefs?.getString('cached_incidents');
      if (raw == null) return [];
      return (json.decode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

// ─── Pre-seeded Offline C-ABCDE Trauma Protocols ──────────────────────────

const List<Map<String, dynamic>> _builtInProtocols = [
  {
    'q': 'cpr',
    'keywords': ['cpr', 'cardiac', 'heart', 'arrest', 'not breathing', 'unconscious'],
    'a': '''**CPR — C-ABCDE Protocol (Offline)**

**C — Catastrophic Hemorrhage:** Check for major bleeding first. Apply direct pressure.

**A — Airway:** Tilt head, lift chin. Clear any obstruction.

**B — Breathing:** Look-listen-feel. No breath → start CPR.

**Steps:**
1. **Call 112** immediately or shout for help
2. Place heel of hand on center of chest
3. Push **DOWN at least 5 cm** at **100–120 compressions/min**
4. After **30 compressions** → **2 rescue breaths**
5. Repeat 30:2 until AED arrives or help takes over

⚡ **AED:** Power on → follow voice prompts → shock if advised
✅ Every minute of delay = 7–10% lower survival. DO NOT STOP.''',
  },
  {
    'q': 'bleeding',
    'keywords': ['bleeding', 'blood', 'hemorrhage', 'wound', 'cut', 'laceration'],
    'a': '''**Severe Bleeding Control (Offline)**

1. Apply **FIRM direct pressure** with clean cloth immediately
2. **DO NOT remove cloth** — add more on top if soaked
3. **Tourniquet** for limb wounds: apply 5–8 cm above wound, tighten until bleeding stops
4. **Note the TIME** tourniquet was applied — tell paramedics
5. Raise injured limb above heart level if possible
6. Watch for **shock signs**: pale/cold skin, rapid weak pulse, confusion

⚠️ NEVER tourniquet the neck, chest, or abdomen.
✅ Maintain pressure until EMS arrives.''',
  },
  {
    'q': 'choking',
    'keywords': ['choking', 'choke', 'airway blocked', 'heimlich', 'cannot breathe'],
    'a': '''**Choking Protocol (Offline)**

**If coughing forcefully:** Encourage — do NOT interfere.

**If cannot breathe or speak:**
1. **5 firm back blows** between shoulder blades
2. **5 abdominal thrusts (Heimlich):** Stand behind, fist above navel, sharp inward-upward pull
3. Alternate 5 back blows + 5 thrusts until object expelled
4. If unconscious: lower carefully, start CPR

👶 **Infants (under 1 year):** 5 back blows + 5 CHEST thrusts (not abdominal)
✅ Keep alternating until help arrives.''',
  },
  {
    'q': 'shock',
    'keywords': ['shock', 'unconscious', 'pale', 'cold sweat', 'faint', 'collapse'],
    'a': '''**Shock / Unconscious Protocol (Offline)**

1. **Lay flat** on their back
2. **Raise legs 30 cm** unless spinal injury suspected
3. Keep **warm** — cover with blanket
4. **DO NOT** give anything to eat or drink
5. Monitor breathing every 2 minutes
6. If breathing: **recovery position** (on side)

**Shock signs:** Pale/grey skin, cold/clammy, rapid weak pulse, confusion, unconsciousness

📞 Call 112 immediately. Stay with victim.''',
  },
  {
    'q': 'burns',
    'keywords': ['burn', 'fire', 'scald', 'hot', 'flame'],
    'a': '''**Burns First Aid (Offline)**

**Minor burns:**
1. Cool under **cool running water for 10–20 minutes**
2. Remove jewellery near the burn
3. Cover loosely with cling film or clean non-fluffy material
4. DO NOT burst blisters

**Severe burns (large area / face / hands):**
1. Call 112 immediately
2. Cool with water while waiting
3. DO NOT remove stuck clothing
4. Keep victim warm — large burns cause hypothermia

⚠️ NEVER use ice, butter, or toothpaste on burns.''',
  },
  {
    'q': 'fracture',
    'keywords': ['fracture', 'broken', 'bone', 'sprain', 'ligament', 'fall'],
    'a': '''**Fracture / Broken Bone (Offline)**

1. **Immobilize** the injured area — do NOT attempt to realign
2. Support above and below the fracture site
3. Apply a splint if available (rigid object + bandage)
4. Apply **ice pack** wrapped in cloth to reduce swelling
5. Elevate if possible
6. Monitor circulation below injury: check pulse, sensation, movement

⚠️ **Spinal injury suspected:** DO NOT move victim. Keep head/neck still. Call 112.''',
  },
  {
    'q': 'seizure',
    'keywords': ['seizure', 'epilepsy', 'convulsion', 'fit', 'shaking'],
    'a': '''**Seizure Protocol (Offline)**

**During seizure:**
1. Clear area of hard/sharp objects
2. Place something soft under their head
3. DO NOT restrain movements
4. DO NOT put anything in their mouth
5. Note the TIME the seizure started

**After seizure:**
1. Place in recovery position (on side)
2. Stay with them until fully conscious
3. Speak calmly and reassuringly

📞 Call 112 if: first seizure, lasts >5 minutes, injury occurred, or doesn't regain consciousness.''',
  },
  {
    'q': 'stroke',
    'keywords': ['stroke', 'face drooping', 'arm weak', 'speech slurred', 'fast', 'brain'],
    'a': '''**Stroke — FAST Protocol (Offline)**

**F — Face:** Ask to smile. Is one side drooping?
**A — Arms:** Ask to raise both arms. Does one drift down?
**S — Speech:** Ask to repeat a phrase. Is it slurred or strange?
**T — Time:** If ANY sign is present → **call 112 IMMEDIATELY**

**While waiting:**
- Lay them down with head and shoulders slightly raised
- Do NOT give food or water
- Loosen tight clothing
- Note exact time symptoms started — critical for treatment

⚡ Time is brain. Every minute = 2 million neurons lost.''',
  },
];
