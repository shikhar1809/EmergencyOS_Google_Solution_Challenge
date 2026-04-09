/// Profile pronouns for **map runner sprites** (green volunteer / red emergency contact).
///
/// Stored on `users/{uid}` as [fieldMapAvatarPronouns]: `he_him` | `she_her` | `they_them`.
abstract final class MapAvatarPronouns {
  static const String fieldMapAvatarPronouns = 'mapAvatarPronouns';

  static const String heHim = 'he_him';
  static const String sheHer = 'she_her';
  static const String theyThem = 'they_them';

  /// `true` → use **female** PNG; `false` → male (includes `they_them` until a third asset exists).
  static bool useFemaleSprite(Map<String, dynamic>? d) {
    if (d == null) return false;
    final p = (d[fieldMapAvatarPronouns] as String?)?.trim().toLowerCase();
    if (p == sheHer || p == 'she/her') return true;
    if (p == heHim || p == 'he/him' || p == theyThem || p == 'they/them') return false;

    final g = d['gender'];
    if (g is String) {
      final lower = g.trim().toLowerCase();
      if (lower == 'female' || lower == 'f') return true;
      if (lower == 'male' || lower == 'm') return false;
    }
    final email = (d['email'] as String? ?? '').split('@').first.toLowerCase();
    const femaleHints = ['she', 'her', 'girl', 'lady'];
    for (final hint in femaleHints) {
      if (email.contains(hint)) return true;
    }
    return false;
  }

  /// `'male'` or `'female'` for [ActiveVolunteerNearby.gender] and map icon pickers.
  static String mapRunnerGender(Map<String, dynamic>? d) =>
      useFemaleSprite(d) ? 'female' : 'male';
}
