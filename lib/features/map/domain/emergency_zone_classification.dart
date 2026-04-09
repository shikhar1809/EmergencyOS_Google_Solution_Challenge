import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import '../../../services/places_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ZONE CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

/// Total hex coverage radius (metres) — command centre resource mesh (~45 km).
/// Covers Lucknow core through Barabanki with margin.
const double kMaxCoverageRadiusM = 45000.0;

/// Admin command centre map: hex grid + cover circle use this radius (metres), capped vs hospital scope.
const double kCommandCenterHexCoverRadiusM = 15000.0;

/// Annulus tiers for summaries: [kZoneTierWidthM] steps out to [kMaxCoverageRadiusM].
const int kZoneTierCount = 15;
const double kZoneTierWidthM = 3000.0;

/// Circumradius (centre → vertex) for flat-top hexagons in metres.
/// ~2.4 km cells keep the 45 km command mesh readable without excessive polygon count.
const double kZoneHexCircumRadiusM = 2400.0;

/// Tier-circle radii used for dispatch visualization on SOS/volunteer maps.
const double kDispatchTier1RadiusM = 2400.0;
const double kDispatchTier2RadiusM = 12000.0;
const double kDispatchTier3RadiusM = 45000.0;

// ═══════════════════════════════════════════════════════════════════════════
// COVERAGE MODEL
// ═══════════════════════════════════════════════════════════════════════════

/// local coverage counts that colour one hex cell.
class HexCellCoverage {
  const HexCellCoverage({
    required this.hospitals,
    required this.volunteers,
  });

  final int hospitals;
  final int volunteers;
}

/// EmergencyOS: TierHealth in lib/features/map/domain/emergency_zone_classification.dart.
enum TierHealth { green, yellow, red }

// ═══════════════════════════════════════════════════════════════════════════
// HEX MATH  (flat-top, axial coordinates — Red Blob Games convention)
// ═══════════════════════════════════════════════════════════════════════════

/// EmergencyOS: HexAxial in lib/features/map/domain/emergency_zone_classification.dart.
class HexAxial {
  const HexAxial(this.q, this.r);
  final int q;
  final int r;

  @override
  bool operator ==(Object other) =>
      other is HexAxial && other.q == q && other.r == r;

  @override
  int get hashCode => Object.hash(q, r);

  /// Firestore / assignment key for this cell (hospital-centered grid).
  String get storageKey => '$q,$r';

  static HexAxial? tryParseStorageKey(String raw) {
    final s = raw.trim();
    final i = s.lastIndexOf(',');
    if (i <= 0 || i >= s.length - 1) return null;
    final qi = int.tryParse(s.substring(0, i).trim());
    final ri = int.tryParse(s.substring(i + 1).trim());
    if (qi == null || ri == null) return null;
    return HexAxial(qi, ri);
  }
}

double _metersPerDegLat() => 111320.0;
double _metersPerDegLng(double atLat) =>
    111320.0 * math.cos(atLat * math.pi / 180.0);

/// Pixel offset in **local ENU metres** for flat-top hex axial (q, r).
Offset _hexToWorldMeters(double size, HexAxial h) {
  final x = size * (3.0 / 2.0) * h.q;
  final y = size * math.sqrt(3.0) * (h.r + h.q / 2.0);
  return Offset(x, y);
}

HexAxial _worldMetersToHex(double size, double x, double y) {
  final fq = (2.0 / 3.0 * x) / size;
  final fr = (-1.0 / 3.0 * x + math.sqrt(3.0) / 3.0 * y) / size;
  return _hexRound(fq, fr);
}

HexAxial _hexRound(double fq, double fr) {
  var q = fq.round();
  var r = fr.round();
  final s = (-fq - fr).round();
  final qDiff = (q - fq).abs();
  final rDiff = (r - fr).abs();
  final sDiff = (s - (-fq - fr)).abs();
  if (qDiff > rDiff && qDiff > sDiff) {
    q = -r - s;
  } else if (rDiff > sDiff) {
    r = -q - s;
  }
  return HexAxial(q, r);
}

/// ENU offset in metres of [lat,lng] relative to [centerLat, centerLng].
Offset _enuOffsetMeters(
    double centerLat, double centerLng, double lat, double lng) {
  final y = (lat - centerLat) * _metersPerDegLat();
  final x = (lng - centerLng) * _metersPerDegLng(centerLat);
  return Offset(x, y);
}

/// Map a geographic point to its containing hex cell.
HexAxial placeToHex(double size, double centerLat, double centerLng,
    EmergencyPlace p) {
  final enu = _enuOffsetMeters(centerLat, centerLng, p.lat, p.lng);
  return _worldMetersToHex(size, enu.dx, enu.dy);
}

HexAxial volunteerToHex(double size, double centerLat, double centerLng,
    double vLat, double vLng) {
  final enu = _enuOffsetMeters(centerLat, centerLng, vLat, vLng);
  return _worldMetersToHex(size, enu.dx, enu.dy);
}

/// Tier health for the hex cell that contains [victimPin] on the ops grid.
///
/// Used for dispatch priority and analytics (not the same as annulus distance tiers).
TierHealth tierHealthAtVictimPin({
  required LatLng gridCenter,
  required LatLng victimPin,
  double coverRadiusM = kMaxCoverageRadiusM,
  required List<EmergencyPlace> hospitals,
  required List<LatLng> volunteerPositions,
}) {
  final size = kZoneHexCircumRadiusM;
  final r = coverRadiusM.clamp(2000.0, kMaxCoverageRadiusM);
  final distFromOrigin = Geolocator.distanceBetween(
    gridCenter.latitude,
    gridCenter.longitude,
    victimPin.latitude,
    victimPin.longitude,
  );
  if (distFromOrigin > r + size) {
    return TierHealth.red;
  }
  final victimHex = volunteerToHex(
    size,
    gridCenter.latitude,
    gridCenter.longitude,
    victimPin.latitude,
    victimPin.longitude,
  );
  final scan = r + size * 3;
  var h = 0;
  var v = 0;
  for (final p in hospitals) {
    if (Geolocator.distanceBetween(
          gridCenter.latitude,
          gridCenter.longitude,
          p.lat,
          p.lng,
        ) >
        scan) {
      continue;
    }
    if (placeToHex(size, gridCenter.latitude, gridCenter.longitude, p) ==
        victimHex) {
      h++;
    }
  }
  for (final pos in volunteerPositions) {
    if (Geolocator.distanceBetween(
          gridCenter.latitude,
          gridCenter.longitude,
          pos.latitude,
          pos.longitude,
        ) >
        scan) {
      continue;
    }
    if (volunteerToHex(
          size,
          gridCenter.latitude,
          gridCenter.longitude,
          pos.latitude,
          pos.longitude,
        ) ==
        victimHex) {
      v++;
    }
  }
  return tierHealthForCell(HexCellCoverage(hospitals: h, volunteers: v));
}

/// Returns the 6 LatLng vertices of the hex polygon for map overlay.
/// Uses a single longitude scale anchored at grid origin to keep shared
/// edges gap-free across the mesh.
List<LatLng> hexVerticesLatLng(
    LatLng centerWorld, double circumRadiusM, HexAxial h) {
  final o = _hexToWorldMeters(circumRadiusM, h);
  final cx = o.dx;
  final cy = o.dy;
  final mLat = _metersPerDegLat();
  final mLng = _metersPerDegLng(centerWorld.latitude);

  final pts = <LatLng>[];
  for (var i = 0; i < 6; i++) {
    // flat-top: vertices at 0°, 60°, … (aligns with _hexToWorldMeters / axial math)
    final ang = i * math.pi / 3.0;
    final vx = cx + circumRadiusM * math.cos(ang);
    final vy = cy + circumRadiusM * math.sin(ang);
    pts.add(LatLng(
      centerWorld.latitude + vy / mLat,
      centerWorld.longitude + vx / mLng,
    ));
  }
  return pts;
}

// ═══════════════════════════════════════════════════════════════════════════
// HEALTH CLASSIFICATION
// ═══════════════════════════════════════════════════════════════════════════

TierHealth tierHealthForCell(HexCellCoverage z) {
  final h = z.hospitals;
  final v = z.volunteers;

  // Red: no acute-care anchor in the cell.
  if (h == 0) return TierHealth.red;

  // Green: hospital plus volunteer support.
  if (h >= 1 && v >= 1) return TierHealth.green;

  // Yellow: hospital only (no volunteer layer in the cell).
  return TierHealth.yellow;
}

/// Main consumer map only: colour by hospital count per hex (not volunteer pairing).
enum MainMapHexPalette { green, yellow, red, grey }

MainMapHexPalette mainMapHexPaletteForCell(HexCellCoverage z) {
  final h = z.hospitals;
  if (h >= 3) return MainMapHexPalette.green;
  if (h == 2) return MainMapHexPalette.yellow;
  if (h == 1) return MainMapHexPalette.red;
  return MainMapHexPalette.grey;
}

// ═══════════════════════════════════════════════════════════════════════════
// VISUAL STYLES
// ═══════════════════════════════════════════════════════════════════════════

/// EmergencyOS: HexZoneStyle in lib/features/map/domain/emergency_zone_classification.dart.
class HexZoneStyle {
  const HexZoneStyle({required this.fill, required this.stroke});
  final Color fill;
  final Color stroke;
}

HexZoneStyle styleForTierHealth(TierHealth t) {
  switch (t) {
    case TierHealth.green:
      return HexZoneStyle(
        fill: const Color(0xFF4CAF50).withValues(alpha: 0.20),
        stroke: const Color(0xFF00E676).withValues(alpha: 0.58),
      );
    case TierHealth.yellow:
      return HexZoneStyle(
        fill: const Color(0xFFFFEB3B).withValues(alpha: 0.19),
        stroke: const Color(0xFFFFEA00).withValues(alpha: 0.58),
      );
    case TierHealth.red:
      return HexZoneStyle(
        // No hospital anchor in this cell: show as non-coverage grey.
        fill: Colors.grey.shade800.withValues(alpha: 0.16),
        stroke: Colors.grey.shade500.withValues(alpha: 0.55),
      );
  }
}

HexZoneStyle styleForMainMapHexPalette(MainMapHexPalette p) {
  switch (p) {
    case MainMapHexPalette.green:
      return HexZoneStyle(
        fill: const Color(0xFF4CAF50).withValues(alpha: 0.20),
        stroke: const Color(0xFF00E676).withValues(alpha: 0.58),
      );
    case MainMapHexPalette.yellow:
      return HexZoneStyle(
        fill: const Color(0xFFFFEB3B).withValues(alpha: 0.19),
        stroke: const Color(0xFFFFEA00).withValues(alpha: 0.58),
      );
    case MainMapHexPalette.red:
      return HexZoneStyle(
        fill: const Color(0xFFE53935).withValues(alpha: 0.22),
        stroke: const Color(0xFFFF1744).withValues(alpha: 0.58),
      );
    case MainMapHexPalette.grey:
      return HexZoneStyle(
        fill: Colors.grey.shade800.withValues(alpha: 0.16),
        stroke: Colors.grey.shade500.withValues(alpha: 0.55),
      );
  }
}

/// Header bar colour for the zone panel.
Color zoneClassificationHeaderColor(TierHealth t) {
  switch (t) {
    case TierHealth.green:
      return const Color(0xFF1B5E20);
    case TierHealth.yellow:
      return const Color(0xFFE65100);
    case TierHealth.red:
      return const Color(0xFFB71C1C);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIER LABELS
// ═══════════════════════════════════════════════════════════════════════════

/// Maps a distance in metres to a tier index 0..kZoneTierCount-1.
int tierSummaryBucket(double distM) {
  if (distM < 0) return 0;
  final idx = (distM / kZoneTierWidthM).floor();
  return idx.clamp(0, kZoneTierCount - 1);
}

/// Human-readable label for one annulus tier.
String tierBandLabelKm(int tierIndex) {
  final wKm = (kZoneTierWidthM / 1000.0).round();
  final lo = tierIndex * wKm;
  final hi = (tierIndex + 1) * wKm;
  if (tierIndex == kZoneTierCount - 1) return '$lo–$hi km (outer ring)';
  return '$lo–$hi km';
}

// ═══════════════════════════════════════════════════════════════════════════
// OUTPUT MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// EmergencyOS: TierAnnulusSummary in lib/features/map/domain/emergency_zone_classification.dart.
class TierAnnulusSummary {
  const TierAnnulusSummary({
    required this.tierIndex,
    required this.greenHexes,
    required this.yellowHexes,
    required this.redHexes,
    this.greyHexes = 0,
  });
  final int tierIndex;
  final int greenHexes;
  final int yellowHexes;
  final int redHexes;
  /// Main map hospital-density mode: cells with zero hospitals.
  final int greyHexes;
  int get total => greenHexes + yellowHexes + redHexes + greyHexes;
}

/// EmergencyOS: EmergencyHexZoneModel in lib/features/map/domain/emergency_zone_classification.dart.
class EmergencyHexZoneModel {
  const EmergencyHexZoneModel({
    required this.polygons,
    required this.tierSummaries,
    required this.coverRadiusM,
    required this.userCellHealth,
    required this.totalCells,
    required this.coveragePercent,
    this.zonePanelHeaderColorOverride,
    this.mainAppHospitalDensityLegend = false,
  });

  final Set<Polygon> polygons;
  final List<TierAnnulusSummary> tierSummaries;
  final double coverRadiusM;
  final TierHealth userCellHealth;
  /// Total hex cells rendered across all tiers.
  final int totalCells;
  /// % of cells that are green (well-covered).
  final double coveragePercent;
  /// When set (main map hospital-density mode), zone panel header uses this colour.
  final Color? zonePanelHeaderColorOverride;
  /// Tier legend on map uses hospital counts (incl. grey); staff hex maps keep volunteer logic.
  final bool mainAppHospitalDensityLegend;
}

// ═══════════════════════════════════════════════════════════════════════════
// CORE BUILDER — complete coverage disk, no gaps
// ═══════════════════════════════════════════════════════════════════════════

HexCellCoverage _mergeCov(HexCellCoverage a, HexCellCoverage b) {
  return HexCellCoverage(
    hospitals: a.hospitals + b.hospitals,
    volunteers: a.volunteers + b.volunteers,
  );
}

/// Hex cells intersecting the coverage disk + per-cell hospital/volunteer counts.
Map<HexAxial, HexCellCoverage> buildHexCellCoverageMap({
  required LatLng center,
  double coverRadiusM = kMaxCoverageRadiusM,
  required List<EmergencyPlace> hospitals,
  required List<LatLng> volunteerPositions,
}) {
  final size = kZoneHexCircumRadiusM;
  final r = coverRadiusM.clamp(2000.0, kMaxCoverageRadiusM);
  final apothem = size * math.sqrt(3.0) / 2.0;
  final qMax = (r / apothem).ceil() + 3;
  final inclusionDist = r + size;

  final cells = <HexAxial, HexCellCoverage>{};

  for (var q = -qMax; q <= qMax; q++) {
    for (var r0 = -qMax; r0 <= qMax; r0++) {
      final h = HexAxial(q, r0);
      final o = _hexToWorldMeters(size, h);
      final centreDist = math.sqrt(o.dx * o.dx + o.dy * o.dy);
      if (centreDist > inclusionDist) continue;

      var inside = centreDist <= r;
      if (!inside) {
        for (var i = 0; i < 6 && !inside; i++) {
          final ang = i * math.pi / 3.0;
          final vx = o.dx + size * math.cos(ang);
          final vy = o.dy + size * math.sin(ang);
          if (math.sqrt(vx * vx + vy * vy) <= r) inside = true;
        }
      }
      if (!inside) continue;

      cells.putIfAbsent(h, () => const HexCellCoverage(hospitals: 0, volunteers: 0));
    }
  }

  void bump(HexAxial h, HexCellCoverage delta) {
    final prev = cells[h];
    if (prev == null) return;
    cells[h] = _mergeCov(prev, delta);
  }

  const oneHospital = HexCellCoverage(hospitals: 1, volunteers: 0);
  const oneVolunteer = HexCellCoverage(hospitals: 0, volunteers: 1);

  for (final p in hospitals) {
    if (Geolocator.distanceBetween(center.latitude, center.longitude, p.lat, p.lng) > inclusionDist) {
      continue;
    }
    bump(placeToHex(size, center.latitude, center.longitude, p), oneHospital);
  }
  for (final v in volunteerPositions) {
    if (Geolocator.distanceBetween(center.latitude, center.longitude, v.latitude, v.longitude) >
        inclusionDist) {
      continue;
    }
    bump(volunteerToHex(size, center.latitude, center.longitude, v.latitude, v.longitude), oneVolunteer);
  }

  return cells;
}

/// Builds a watertight hexagonal mesh covering every point within
/// [coverRadiusM] (clamped to [kMaxCoverageRadiusM]).
///
/// **Gap-free guarantee:**
/// A hex cell is included when ANY of its 6 vertices OR its centre lies
/// within [coverRadiusM], ensuring the boundary ring is fully closed with
/// no leftover wedges or slivers.
Color? _mainMapZonePanelHeaderColor(int hospitalCount) {
  if (hospitalCount >= 3) return const Color(0xFF1B5E20);
  if (hospitalCount == 2) return const Color(0xFFE65100);
  if (hospitalCount == 1) return const Color(0xFFB71C1C);
  return const Color(0xFF424242);
}

EmergencyHexZoneModel buildEmergencyHexZones({
  required LatLng center,
  double coverRadiusM = kMaxCoverageRadiusM,
  required List<EmergencyPlace> hospitals,
  required List<LatLng> volunteerPositions,
  /// Main consumer map: green/yellow/red/grey by hospital count per hex only.
  bool useMainAppHospitalDensityColors = false,
}) {
  final size = kZoneHexCircumRadiusM;
  final r = coverRadiusM.clamp(2000.0, kMaxCoverageRadiusM);

  final cells = buildHexCellCoverageMap(
    center: center,
    coverRadiusM: coverRadiusM,
    hospitals: hospitals,
    volunteerPositions: volunteerPositions,
  );

  // ── 3. Build polygons & summaries ─────────────────────────────────────

  const userAxial = HexAxial(0, 0);
  final userCov = cells[userAxial] ?? const HexCellCoverage(hospitals: 0, volunteers: 0);
  final userCellHealth = tierHealthForCell(userCov);

  final tierGreen = List<int>.filled(kZoneTierCount, 0);
  final tierYellow = List<int>.filled(kZoneTierCount, 0);
  final tierRed = List<int>.filled(kZoneTierCount, 0);
  final tierGrey = useMainAppHospitalDensityColors
      ? List<int>.filled(kZoneTierCount, 0)
      : null;

  final polygons = <Polygon>{};
  var pi = 0;
  var greenCount = 0;

  for (final entry in cells.entries) {
    final h = entry.key;
    final cov = entry.value;
    final o = _hexToWorldMeters(size, h);
    final dist = math.sqrt(o.dx * o.dx + o.dy * o.dy);

    final bucket = tierSummaryBucket(dist);

    if (useMainAppHospitalDensityColors) {
      final palette = mainMapHexPaletteForCell(cov);
      switch (palette) {
        case MainMapHexPalette.green:
          tierGreen[bucket]++;
          greenCount++;
        case MainMapHexPalette.yellow:
          tierYellow[bucket]++;
        case MainMapHexPalette.red:
          tierRed[bucket]++;
        case MainMapHexPalette.grey:
          tierGrey![bucket]++;
      }
      final st = styleForMainMapHexPalette(palette);
      final verts = hexVerticesLatLng(center, size, h);
      if (verts.length < 3) continue;

      polygons.add(Polygon(
        polygonId: PolygonId('hz_${pi++}'),
        points: verts,
        fillColor: st.fill,
        strokeColor: st.stroke.withValues(alpha: 0.34),
        strokeWidth: 1,
        zIndex: 2,
      ));
    } else {
      final health = tierHealthForCell(cov);
      switch (health) {
        case TierHealth.green:
          tierGreen[bucket]++;
          greenCount++;
        case TierHealth.yellow:
          tierYellow[bucket]++;
        case TierHealth.red:
          tierRed[bucket]++;
      }

      final st = styleForTierHealth(health);
      final verts = hexVerticesLatLng(center, size, h);
      if (verts.length < 3) continue;

      polygons.add(Polygon(
        polygonId: PolygonId('hz_${pi++}'),
        points: verts,
        fillColor: st.fill,
        strokeColor: st.stroke.withValues(alpha: 0.34),
        strokeWidth: 1,
        zIndex: 2,
      ));
    }
  }

  final totalCells = cells.length;
  final coveragePercent =
      totalCells > 0 ? (greenCount / totalCells) * 100.0 : 0.0;

  final summaries = <TierAnnulusSummary>[];
  for (var i = 0; i < kZoneTierCount; i++) {
    summaries.add(TierAnnulusSummary(
      tierIndex: i,
      greenHexes: tierGreen[i],
      yellowHexes: tierYellow[i],
      redHexes: tierRed[i],
      greyHexes: tierGrey != null ? tierGrey[i] : 0,
    ));
  }

  return EmergencyHexZoneModel(
    polygons: polygons,
    tierSummaries: summaries,
    coverRadiusM: r,
    userCellHealth: userCellHealth,
    totalCells: totalCells,
    coveragePercent: coveragePercent,
    zonePanelHeaderColorOverride: useMainAppHospitalDensityColors
        ? _mainMapZonePanelHeaderColor(userCov.hospitals)
        : null,
    mainAppHospitalDensityLegend: useMainAppHospitalDensityColors,
  );
}
