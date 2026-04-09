import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/incident_service.dart';

class AreaIntelOverlay extends StatelessWidget {
  final AreaIntelligence intel;

  const AreaIntelOverlay({super.key, required this.intel});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: Colors.amberAccent,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'AREA INTELLIGENCE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Avg Response Time:',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Text(
                  '${intel.avgResponseMinutes} mins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Recent Incident Volume:',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Text(
                  '${intel.totalPastIncidents} past incidents',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Congestion Warning:',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Text(
                  intel.riskScore > 50 ? 'High (Expect delays)' : 'Low',
                  style: TextStyle(
                    color: intel.riskScore > 50
                        ? AppColors.primaryDanger
                        : AppColors.primarySafe,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
