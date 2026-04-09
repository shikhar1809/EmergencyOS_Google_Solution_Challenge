import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LivekitBridgeStatusStrip extends StatelessWidget {
  final bool isConnected;
  final String bridgeStatus;
  final bool isPausedForStt;
  final int visibleParticipantCount;
  final bool hasAttempted;

  const LivekitBridgeStatusStrip({
    super.key,
    required this.isConnected,
    required this.bridgeStatus,
    required this.isPausedForStt,
    required this.visibleParticipantCount,
    required this.hasAttempted,
  });

  String get titleLabel {
    final suffix = visibleParticipantCount == 0
        ? ''
        : ' \u00b7 $visibleParticipantCount on channel';
    if (isConnected) return 'Emergency voice channel$suffix';
    if (bridgeStatus == 'failed')
      return 'Emergency channel \u00b7 tap retry$suffix';
    if (hasAttempted) return 'Emergency channel \u00b7 connecting$suffix';
    return 'Emergency voice channel$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color accent;
    final String label;
    final String detail;

    if (!isConnected) {
      switch (bridgeStatus) {
        case 'failed':
          icon = Icons.mic_off_rounded;
          accent = AppColors.primaryDanger;
          label = 'Mic \u00b7 Disrupted';
          detail = 'Voice channel unavailable. Use RETRY above.';
        case 'reconnecting':
          icon = Icons.sync_rounded;
          accent = AppColors.primaryWarning;
          label = 'Mic \u00b7 Reconnecting';
          detail = 'Restoring live audio\u2026';
        case 'connecting':
          icon = Icons.mic_none_rounded;
          accent = AppColors.primaryWarning;
          label = 'Mic \u00b7 Connecting';
          detail = 'Joining emergency voice channel\u2026';
        default:
          icon = Icons.mic_none_rounded;
          accent = Colors.white38;
          label = 'Mic \u00b7 Standby';
          detail = 'Waiting for voice channel\u2026';
      }
    } else if (isPausedForStt) {
      icon = Icons.mic_rounded;
      accent = AppColors.primaryWarning;
      label = 'Mic \u00b7 Interrupted';
      detail = 'Brief pause while the app processes audio.';
    } else {
      icon = Icons.mic_rounded;
      accent = AppColors.primarySafe;
      label = 'Mic \u00b7 Active';
      detail = 'Live channel is receiving your microphone.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
