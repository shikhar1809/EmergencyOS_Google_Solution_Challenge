import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SosActiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDrillMode;
  final bool isUnlocking;
  final VoidCallback onUnlock;
  final VoidCallback onStopSpeaking;
  final String? drillPracticePin;

  const SosActiveAppBar({
    super.key,
    required this.isDrillMode,
    required this.isUnlocking,
    required this.onUnlock,
    required this.onStopSpeaking,
    this.drillPracticePin,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kBottomNavigationBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isDrillMode ? 'SOS PRACTICE (DRILL)' : 'SOS ACTIVE',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 17,
            ),
          ),
          if (isDrillMode) ...[
            Text(
              'No real dispatch · location not shared with responders',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.amberAccent.withValues(alpha: 0.95),
                letterSpacing: 0.2,
              ),
            ),
            if (drillPracticePin != null)
              Text(
                'UNLOCK PIN (practice): $drillPracticePin',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.cyanAccent.withValues(alpha: 0.92),
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Stop speaking',
          onPressed: onStopSpeaking,
          icon: const Icon(Icons.volume_off_rounded),
        ),
        TextButton.icon(
          onPressed: isUnlocking ? null : onUnlock,
          icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
          label: Text(
            isUnlocking ? '...' : 'UNLOCK',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: const TabBar(
        indicatorColor: AppColors.primaryDanger,
        labelColor: AppColors.primaryDanger,
        unselectedLabelColor: Colors.white70,
        tabs: [
          Tab(text: 'STATUS', icon: Icon(Icons.warning_rounded)),
          Tab(text: 'LIVE MAP', icon: Icon(Icons.near_me_rounded)),
        ],
      ),
    );
  }
}
