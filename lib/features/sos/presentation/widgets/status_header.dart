import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StatusHeader extends StatelessWidget {
  final String timeStr;
  final int acceptedCount;
  final int onSceneVolunteerCount;
  final String? ambulanceEta;
  final String? medicalStatus;

  const StatusHeader({
    super.key,
    required this.timeStr,
    required this.acceptedCount,
    required this.onSceneVolunteerCount,
    required this.ambulanceEta,
    required this.medicalStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sos_rounded,
                color: AppColors.primaryDanger,
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE SOS',
                      style: TextStyle(
                        color: AppColors.primaryDanger,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        fontSize: 24,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Help is coming. Stay calm.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (acceptedCount > 0
                              ? AppColors.primarySafe
                              : AppColors.primaryDanger)
                          .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        (acceptedCount > 0
                                ? AppColors.primarySafe
                                : AppColors.primaryDanger)
                            .withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  acceptedCount > 0 ? '$acceptedCount EN ROUTE' : 'WAITING',
                  style: TextStyle(
                    color: acceptedCount > 0
                        ? AppColors.primarySafe
                        : AppColors.primaryDanger,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MiniStat(label: 'Ambulance', value: ambulanceEta ?? '—'),
              MiniStat(
                label: 'On scene',
                value: onSceneVolunteerCount <= 0
                    ? '0'
                    : '$onSceneVolunteerCount volunteers',
              ),
              MiniStat(label: 'Status', value: medicalStatus ?? '—'),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const MiniStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
