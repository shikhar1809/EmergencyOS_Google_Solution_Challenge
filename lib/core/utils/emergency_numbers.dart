import 'dart:ui';

class EmergencyNumbers {
  static String primaryNumberForLocale(Locale locale) {
    final cc = (locale.countryCode ?? '').toUpperCase();

    // Conservative defaults:
    // - Many countries support 112.
    // - US/CA primarily use 911.
    if (cc == 'US' || cc == 'CA') return '911';
    if (cc == 'IN') return '112';
    if (cc.isEmpty) return '112';
    return '112';
  }

  static String primaryLabel(Locale locale) {
    final n = primaryNumberForLocale(locale);
    return 'Call $n';
  }
}

