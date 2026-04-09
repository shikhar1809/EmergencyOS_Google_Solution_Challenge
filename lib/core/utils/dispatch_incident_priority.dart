import 'package:flutter/foundation.dart';

import '../../features/map/domain/emergency_zone_classification.dart';
import '../../services/incident_service.dart';

/// Command-center incident ordering: combines coverage cell health with clinical type.
@immutable
class DispatchIncidentPriority {
  const DispatchIncidentPriority({required this.label, required this.score});

  final String label;
  final int score;

  static int _typeWeight(SosIncident inc) {
    final t = inc.type.toLowerCase();
    if (t.contains('cardiac') ||
        t.contains('arrest') ||
        t.contains('stroke') ||
        t.contains('unconscious') ||
        t.contains('choking') ||
        t.contains('bleed') ||
        t.contains('hemorrh') ||
        t.contains('seizure') ||
        t.contains('spinal') ||
        t.contains('head /') ||
        t.contains('allergic')) {
      return 100;
    }
    if (t.contains('breath')) return 85;
    if (t.contains('rapid')) return 55;
    if (t.contains('poison')) return 80;
    return 40;
  }

  static int _tierWeight(TierHealth tier) {
    switch (tier) {
      case TierHealth.red:
        return 35;
      case TierHealth.yellow:
        return 18;
      case TierHealth.green:
        return 0;
    }
  }

  static DispatchIncidentPriority forIncident(SosIncident inc, TierHealth tier) {
    final score = _typeWeight(inc) + _tierWeight(tier);
    final label = score >= 115
        ? 'P1'
        : score >= 85
            ? 'P2'
            : score >= 55
                ? 'P3'
                : 'P4';
    return DispatchIncidentPriority(label: label, score: score);
  }

  /// Higher-priority incidents first; tie-break by newer timestamp.
  static int compare(
    SosIncident a,
    SosIncident b,
    TierHealth ta,
    TierHealth tb,
  ) {
    final sa = forIncident(a, ta).score;
    final sb = forIncident(b, tb).score;
    if (sa != sb) return sb.compareTo(sa);
    return b.timestamp.compareTo(a.timestamp);
  }
}

/// Maps an emergency type string to the hospital service tags required for dispatch.
///
/// Shared across SOS quick-intake, voice-interview category selection, and
/// Cloud Function fallback logic.
List<String> requiredServicesForType(String type) {
  if (type == 'Other medical emergency' ||
      type.startsWith('Other medical emergency:')) {
    return const ['trauma'];
  }
  if (type.startsWith('Other:')) return const ['trauma'];
  switch (type) {
    case 'Cardiac arrest / Heart attack':
      return const ['trauma', 'cardiology', 'icu'];
    case 'Stroke / Sudden weakness':
      return const ['trauma', 'neurology', 'icu'];
    case 'Severe bleeding / Hemorrhage':
      return const ['trauma', 'surgery', 'blood_bank'];
    case 'Breathing difficulty / Choking':
      return const ['trauma', 'ent', 'icu'];
    case 'Unconscious / Unresponsive':
      return const ['trauma', 'icu'];
    case 'Seizure / Convulsions':
      return const ['trauma', 'neurology', 'icu'];
    case 'Severe allergic reaction':
      return const ['trauma', 'icu'];
    case 'Poisoning / Overdose':
      return const ['trauma', 'icu'];
    case 'Head / Spinal injury':
      return const ['trauma', 'surgery', 'icu', 'orthopedics'];
    default:
      return const ['trauma'];
  }
}
