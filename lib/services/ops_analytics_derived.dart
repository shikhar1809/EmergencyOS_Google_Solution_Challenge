import '../core/constants/india_ops_zones.dart';
import '../core/utils/ops_analytics_hex_grid.dart';
import 'incident_service.dart';

/// Trend + hex hotspot strings for UI and Gemini context.
abstract final class OpsAnalyticsDerived {
  /// Index 0 = six days ago, 6 = today (local midnight buckets).
  static List<int> sevenDayCountsInZone(List<SosIncident> inZone, DateTime now) {
    final localNow = now.toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final counts = List<int>.filled(7, 0);
    for (final e in inZone) {
      final t = e.timestamp.toLocal();
      final day = DateTime(t.year, t.month, t.day);
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff <= 6) {
        counts[6 - diff]++;
      }
    }
    return counts;
  }

  static Map<String, int> hexBinsForIncidents(
    List<SosIncident> incidents,
    IndiaOpsZone zone,
  ) {
    final size = OpsAnalyticsHexGrid.hexSizeMetersForZone(zone.radiusM);
    return OpsAnalyticsHexGrid.binIncidents(
      incidents.map((e) => e.liveVictimPin),
      zone.center,
      size,
    );
  }

  /// Human-readable top cell + coords for AI digest.
  static String hotspotSummary(Map<String, int> bins, IndiaOpsZone zone) {
    if (bins.isEmpty) {
      return 'Hex density: no incidents in the selected time window.';
    }
    var bestK = '';
    var bestC = 0;
    for (final e in bins.entries) {
      if (e.value > bestC) {
        bestC = e.value;
        bestK = e.key;
      }
    }
    final size = OpsAnalyticsHexGrid.hexSizeMetersForZone(zone.radiusM);
    final h = OpsAnalyticsHexGrid.parseKey(bestK);
    final c = OpsAnalyticsHexGrid.centerForHex(h.q, h.r, zone.center, size);
    return 'Densest hex: $bestC incidents · approx center ${c.latitude.toStringAsFixed(4)}°N ${c.longitude.toStringAsFixed(4)}°E '
        '(pointy-top hex grid, ~${(size / 1000).toStringAsFixed(1)} km vertex radius).';
  }

  static String augmentForGemini({
    required List<int> trend7,
    required String hotspot48h,
    required String hotspot7d,
  }) {
    return '--- DERIVED ANALYTICS (client) ---\n'
        '7-day daily counts in zone (oldest day first, last = today): ${trend7.join(", ")}\n'
        'Hex hotspot (last 48h, same grid): $hotspot48h\n'
        'Hex hotspot (last 7d): $hotspot7d\n';
  }
}
