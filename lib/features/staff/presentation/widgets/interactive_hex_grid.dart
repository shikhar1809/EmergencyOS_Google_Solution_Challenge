import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';

class HexCellData {
  final String key;
  final int q, r;
  final LatLng center;
  final List<LatLng> ring;
  final int incidentCount48h;
  final int incidentCount24h;
  final int incidentCount7d;
  final int volunteerCount;
  final int hospitalCount;
  final List<String> incidentTypes;
  final List<String> activeIncidentIds;

  const HexCellData({
    required this.key,
    required this.q,
    required this.r,
    required this.center,
    required this.ring,
    required this.incidentCount48h,
    required this.incidentCount24h,
    required this.incidentCount7d,
    required this.volunteerCount,
    required this.hospitalCount,
    this.incidentTypes = const [],
    this.activeIncidentIds = const [],
  });

  double get densityRatio => incidentCount48h / math.max(1, 10);
}

class InteractiveHexGridOverlay {
  static Set<Polygon> buildPolygons(
    List<HexCellData> cells, {
    HexCellData? selectedCell,
    bool showGridMode = true,
  }) {
    final polygons = <Polygon>{};
    for (final cell in cells) {
      final isSelected = selectedCell?.key == cell.key;
      final t = cell.densityRatio.clamp(0.0, 1.0);

      final fillColor = !showGridMode
          ? Color.lerp(
              const Color(0xFF1565C0).withValues(alpha: 0.1),
              const Color(0xFFFF5722).withValues(alpha: 0.5),
              t,
            )!
          : isSelected
          ? AppColors.accentBlue.withValues(alpha: 0.45)
          : AppColors.accentBlue.withValues(alpha: 0.08 + (t * 0.25));

      polygons.add(
        Polygon(
          polygonId: PolygonId('ihx_${cell.key.replaceAll(',', '_')}'),
          points: cell.ring,
          strokeColor: isSelected
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.25),
          strokeWidth: isSelected ? 3 : 1,
          fillColor: fillColor,
          consumeTapEvents: true,
        ),
      );
    }
    return polygons;
  }

  static Widget buildCellDetailSheet(HexCellData cell) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 340),
      decoration: const BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_on,
                    color: AppColors.accentBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hex Cell Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'q=${cell.q}, r=${cell.r} · ${cell.center.latitude.toStringAsFixed(4)}, ${cell.center.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _miniStat(
                        '24h',
                        '${cell.incidentCount24h}',
                        Icons.today,
                        Colors.orangeAccent,
                      ),
                      _miniStat(
                        '48h',
                        '${cell.incidentCount48h}',
                        Icons.calendar_today,
                        AppColors.accentBlue,
                      ),
                      _miniStat(
                        '7d',
                        '${cell.incidentCount7d}',
                        Icons.date_range,
                        Colors.cyanAccent,
                      ),
                      _miniStat(
                        'Volunteers',
                        '${cell.volunteerCount}',
                        Icons.people,
                        Colors.greenAccent,
                      ),
                      _miniStat(
                        'Hospitals',
                        '${cell.hospitalCount}',
                        Icons.local_hospital,
                        Colors.lightBlueAccent,
                      ),
                    ],
                  ),
                  if (cell.incidentTypes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'INCIDENT TYPES',
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: cell.incidentTypes.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (cell.activeIncidentIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'ACTIVE INCIDENTS',
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...cell.activeIncidentIds.take(5).map((id) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                id.length > 24
                                    ? '${id.substring(0, 22)}...'
                                    : id,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _miniStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.slate900, color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
