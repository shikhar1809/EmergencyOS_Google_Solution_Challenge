import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/lifeline_progress_repository.dart';
import '../../domain/lifeline_training_levels.dart';
import 'lifeline_level_play_page.dart';

/// Clash-style horizontal path of training nodes + elite unlock status.
class LifelineTrainingArena extends StatelessWidget {
  const LifelineTrainingArena({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LifelineArenaSnapshot>(
      stream: LifelineProgressRepository.instance.watchArenaSnapshot(),
      builder: (context, snap) {
        final arena = snap.data ??
            const LifelineArenaSnapshot(levelsCleared: 0, volunteerXp: 0, volunteerLivesSaved: 0);
        final cleared = arena.levelsCleared;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 14 : 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2A1F4E).withValues(alpha: 0.95),
                  AppColors.surfaceHighlight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.military_tech_rounded, color: Colors.amber.shade300, size: compact ? 26 : 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lifeline arena',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: compact ? 17 : 20,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            'Watch · learn · pass the quiz · climb the path',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: compact ? 11 : 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 14),
                _statsRow(arena, compact),
                SizedBox(height: compact ? 12 : 16),
                _eliteBanner(arena, compact),
                SizedBox(height: compact ? 12 : 16),
                SizedBox(
                  height: compact ? 118 : 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kLifelineTrainingLevels.length,
                    separatorBuilder: (context, index) => Center(
                      child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    itemBuilder: (context, i) {
                      final level = kLifelineTrainingLevels[i];
                      final levelIndex = i + 1;
                      final unlocked = levelIndex <= cleared + 1;
                      final done = levelIndex <= cleared;
                      final stagger = (i % 2 == 0) ? 0.0 : (compact ? 14.0 : 22.0);
                      return Transform.translate(
                        offset: Offset(0, stagger),
                        child: _LevelNode(
                          level: level,
                          levelIndex: levelIndex,
                          unlocked: unlocked,
                          cleared: done,
                          compact: compact,
                          onTap: () async {
                            final r = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => LifelineLevelPlayPage(
                                  level: level,
                                  isUnlocked: unlocked,
                                  isCleared: done,
                                ),
                              ),
                            );
                            if (r == true && context.mounted) {
                              // Parent may refresh streams automatically via Firestore.
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statsRow(LifelineArenaSnapshot arena, bool compact) {
    return Row(
      children: [
        _miniStat('Levels', '${arena.levelsCleared}/${kLifelineTrainingLevels.length}', Icons.flag_rounded, Colors.cyanAccent),
        SizedBox(width: compact ? 8 : 12),
        _miniStat('Volunteer XP', '${arena.volunteerXp}', Icons.bolt_rounded, Colors.amberAccent),
        SizedBox(width: compact ? 8 : 12),
        _miniStat('Lives helped', '${arena.volunteerLivesSaved}', Icons.favorite_rounded, Colors.pinkAccent),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10, fontWeight: FontWeight.w700)),
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eliteBanner(LifelineArenaSnapshot arena, bool compact) {
    final ok = arena.eliteVoiceUnlocked;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ok ? Colors.greenAccent.withValues(alpha: 0.45) : Colors.white24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.verified_user_rounded : Icons.lock_open_rounded, color: ok ? Colors.greenAccent : Colors.white54, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'Elite voice bridge unlocked' : 'Elite voice bridge — locked',
                  style: TextStyle(
                    color: ok ? Colors.greenAccent : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ok
                      ? 'You may join incident LiveKit rooms as an elite volunteer from the active incident screen.'
                      : 'Clear level 10 here, or reach 5 lives helped with 1,000 volunteer XP (accept SOS responses to earn XP).',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: compact ? 11 : 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.levelIndex,
    required this.unlocked,
    required this.cleared,
    required this.compact,
    required this.onTap,
  });

  final LifelineTrainingLevel level;
  final int levelIndex;
  final bool unlocked;
  final bool cleared;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = compact ? 92.0 : 104.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: unlocked
                  ? [level.accent.withValues(alpha: 0.55), level.accent.withValues(alpha: 0.2)]
                  : [Colors.grey.shade800, Colors.grey.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: cleared ? Colors.amberAccent : (unlocked ? level.accent.withValues(alpha: 0.8) : Colors.white24),
              width: cleared ? 2 : 1,
            ),
            boxShadow: unlocked
                ? [BoxShadow(color: level.accent.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (cleared)
                const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 26)
              else if (!unlocked)
                Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.45), size: 24)
              else
                Icon(Icons.play_circle_fill_rounded, color: level.accent, size: 28),
              const SizedBox(height: 6),
              Text(
                '$levelIndex',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 20 : 22,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  level.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: unlocked ? 0.95 : 0.45),
                    fontSize: compact ? 9.5 : 10,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
