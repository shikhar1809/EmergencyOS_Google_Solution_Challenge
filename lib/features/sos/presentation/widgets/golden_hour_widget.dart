import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/usage_analytics_service.dart';

// ---------------------------------------------------------------------------
// Golden Hour Timer Widget
// Counts down from 60 minutes from incident start
// Fires milestone callbacks at 5, 10, 20, 30, 60 minutes
// ---------------------------------------------------------------------------

class GoldenHourMilestone {
  final int minuteMark;
  final String title;
  final String action;
  final Color color;
  const GoldenHourMilestone({
    required this.minuteMark, required this.title,
    required this.action, required this.color,
  });
}

const _milestones = [
  GoldenHourMilestone(minuteMark: 5,  color: Colors.orange,   title: '5-Min Mark',  action: 'Check tourniquet tightness. Reassess bleeding.'),
  GoldenHourMilestone(minuteMark: 10, color: Colors.deepOrange, title: '10-Min Mark', action: 'Airway reassessment. Check breathing rate.'),
  GoldenHourMilestone(minuteMark: 20, color: Colors.red,       title: '20-Min Mark', action: 'Shock protocol: legs elevated, keep warm.'),
  GoldenHourMilestone(minuteMark: 30, color: Colors.redAccent, title: '⚠️ 30-Min',   action: 'CRITICAL: ETA to hospital? Inform trauma team.'),
  GoldenHourMilestone(minuteMark: 60, color: Colors.red,       title: '🚨 GOLDEN HOUR EXPIRED', action: 'Survival odds drop sharply. Maximise speed to OR.'),
];

class GoldenHourWidget extends StatefulWidget {
  final DateTime startTime;
  final void Function(GoldenHourMilestone)? onMilestone;

  const GoldenHourWidget({super.key, required this.startTime, this.onMilestone});

  @override
  State<GoldenHourWidget> createState() => _GoldenHourWidgetState();
}

class _GoldenHourWidgetState extends State<GoldenHourWidget>
    with SingleTickerProviderStateMixin {
  late Timer _ticker;
  Duration _remaining = const Duration(hours: 1);
  final Set<int> _firedMilestones = {};
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), _tick);
    _tick(null);
  }

  void _tick(Timer? _) {
    if (!context.mounted) return;
    final elapsed = DateTime.now().difference(widget.startTime);
    final remaining = const Duration(hours: 1) - elapsed;
    setState(() => _remaining = remaining.isNegative ? Duration.zero : remaining);

    final elapsedMin = elapsed.inMinutes;
    for (final m in _milestones) {
      if (elapsedMin >= m.minuteMark && !_firedMilestones.contains(m.minuteMark)) {
        _firedMilestones.add(m.minuteMark);
        widget.onMilestone?.call(m);
        SemanticsService.announce(
          '${m.minuteMark} minute golden hour milestone. ${m.title}. ${m.action}',
          TextDirection.ltr,
        );
        UsageAnalyticsService.instance.goldenHourMilestoneReached(minuteMark: m.minuteMark);
      }
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _timerColor {
    final elapsed = DateTime.now().difference(widget.startTime).inMinutes;
    if (elapsed >= 50) return Colors.red;
    if (elapsed >= 30) return Colors.deepOrange;
    if (elapsed >= 15) return Colors.orange;
    return AppColors.primarySafe;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _remaining.inSeconds / 3600.0;
    final isExpired = _remaining == Duration.zero;
    final mm = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _timerColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.timer_rounded, color: _timerColor, size: 18),
              const SizedBox(width: 8),
              Text('GOLDEN HOUR',
                style: TextStyle(color: _timerColor, fontWeight: FontWeight.w900,
                    fontSize: 11, letterSpacing: 1.5)),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isExpired
                        ? Colors.red
                        : _timerColor.withValues(alpha: 0.5 + 0.5 * _pulseController.value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ring + countdown
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100, height: 100,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  color: _timerColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$mm:$ss',
                    style: TextStyle(
                      color: isExpired ? Colors.red : Colors.white,
                      fontSize: 26, fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(isExpired ? 'EXPIRED' : 'remaining',
                    style: TextStyle(
                      color: isExpired ? Colors.redAccent : Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Milestone markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _milestones.take(4).map((m) {
              final done = _firedMilestones.contains(m.minuteMark);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? m.color.withValues(alpha: 0.2) : Colors.white10,
                      border: Border.all(color: done ? m.color : Colors.white24, width: 1.5),
                    ),
                    child: Center(
                      child: Text('${m.minuteMark}',
                        style: TextStyle(color: done ? m.color : Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('min', style: TextStyle(color: done ? m.color : Colors.white24, fontSize: 8)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}
