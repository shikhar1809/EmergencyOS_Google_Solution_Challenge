import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:emergency_os/core/l10n/app_localizations.dart';
import 'package:emergency_os/core/theme/app_colors.dart';
import 'package:emergency_os/services/voice_comms_service.dart';
import 'package:emergency_os/features/ai_assist/domain/lifeline_training_levels.dart';
import 'widgets/guide_detail_page.dart';
import 'widgets/lifeline_voice_agent_overlay.dart';

class AIAssistScreen extends StatefulWidget {
  final String? openAid;
  final String? mode;
  final String? incidentId;
  final bool isDrillShell;

  const AIAssistScreen({
    super.key,
    this.openAid,
    this.mode,
    this.incidentId,
    this.isDrillShell = false,
  });

  @override
  State<AIAssistScreen> createState() => _AIAssistScreenState();
}

class _AIAssistScreenState extends State<AIAssistScreen> {
  late final PageController _pageController;
  int _activePage = 0;
  double _pageValue = 0;
  bool _emergencyMode = false;

  static const _levels = kLifelineTrainingLevels;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    final p = _pageController.page;
    if (p != null) {
      setState(() => _pageValue = p);
    }
  }

  void _goToPage(int index) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleEmergencyMode() {
    HapticFeedback.heavyImpact();
    if (kIsWeb) {
      VoiceCommsService.primeForVoiceGuidance();
    }
    setState(() => _emergencyMode = !_emergencyMode);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePad = MediaQuery.of(context).padding;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.isDrillShell)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.cyan.shade900.withValues(alpha: 0.88),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      l.aiAssistPracticeBanner,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              _SlidingRail(
                levels: _levels,
                currentPage: _pageValue,
                activePage: _activePage,
                onTap: _goToPage,
                safePad: safePad,
                emergencyMode: _emergencyMode,
                onToggleEmergency: _toggleEmergencyMode,
                l10n: l,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const _SnapScrollPhysics(),
                  itemCount: _levels.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _activePage = i);
                    SemanticsService.announce(
                      l.aiAssistRailSemantics(i + 1, _levels[i].title),
                      Directionality.of(context),
                    );
                  },
                  itemBuilder: (context, index) {
                    return GuideDetailPage(
                      key: ValueKey('guide_${index}_$_emergencyMode'),
                      level: _levels[index],
                      isActive: _activePage == index,
                      pageIndex: index,
                      totalPages: _levels.length,
                      safePadding: safePad,
                      emergencyMode: _emergencyMode,
                    );
                  },
                ),
              ),
            ],
          ),
          LifelineVoiceAgentOverlay(
            activeLevelIndex: _activePage,
            activeLevelTitle: _levels[_activePage].title,
            safePadding: safePad,
          ),
        ],
      ),
    );
  }
}

class _SlidingRail extends StatelessWidget {
  final List<LifelineTrainingLevel> levels;
  final double currentPage;
  final int activePage;
  final ValueChanged<int> onTap;
  final EdgeInsets safePad;
  final bool emergencyMode;
  final VoidCallback onToggleEmergency;
  final AppLocalizations l10n;

  const _SlidingRail({
    required this.levels,
    required this.currentPage,
    required this.activePage,
    required this.onTap,
    required this.safePad,
    required this.emergencyMode,
    required this.onToggleEmergency,
    required this.l10n,
  });

  Color _lerpAccent() {
    if (emergencyMode) return AppColors.primaryDanger;
    final floor = currentPage.floor().clamp(0, levels.length - 1);
    final ceil = currentPage.ceil().clamp(0, levels.length - 1);
    final t = currentPage - floor;
    return Color.lerp(levels[floor].accent, levels[ceil].accent, t) ??
        levels[floor].accent;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = safePad.top + 12;
    final bottomPad = safePad.bottom + 12;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 62,
      decoration: BoxDecoration(
        color: emergencyMode
            ? AppColors.primaryDanger.withValues(alpha: 0.12)
            : AppColors.surface.withValues(alpha: 0.62),
        border: Border(
          right: BorderSide(
            color: emergencyMode
                ? AppColors.primaryDanger.withValues(alpha: 0.2)
                : AppColors.stroke,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
        child: Column(
          children: [
            _buildEmergencyToggle(),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalH = constraints.maxHeight;
                  final itemH = math.max(48.0, totalH / levels.length);
                  final indicatorAccent = _lerpAccent();

                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height: totalH,
                      child: Stack(
                        children: [
                          // Vertical track line
                          Positioned(
                            left: 30,
                            top: (totalH / levels.length) * 0.5,
                            bottom: (totalH / levels.length) * 0.5,
                            child: Container(
                              width: 2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                color: emergencyMode
                                    ? AppColors.primaryDanger.withValues(alpha: 0.15)
                                    : AppColors.stroke,
                              ),
                            ),
                          ),

                          // Sliding glow indicator
                          Positioned(
                            left: 0,
                            right: 0,
                            top: currentPage * (totalH / levels.length),
                            height: totalH / levels.length,
                            child: Center(
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: indicatorAccent.withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: indicatorAccent.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: indicatorAccent.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: indicatorAccent.withValues(alpha: 0.1),
                                      blurRadius: 40,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Track progress fill
                          Positioned(
                            left: 30,
                            top: (totalH / levels.length) * 0.5,
                            width: 2,
                            height: math.max(0, currentPage * (totalH / levels.length)),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (emergencyMode ? AppColors.primaryDanger : levels.first.accent).withValues(alpha: 0.4),
                                    indicatorAccent.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Icon buttons
                          ...List.generate(levels.length, (i) {
                            final level = levels[i];
                            final dist = (currentPage - i).abs();
                            final isNearest = dist < 0.5;
                            final scale = (1.0 - dist * 0.08).clamp(0.7, 1.0);
                            final opacity = (1.0 - dist * 0.15).clamp(0.35, 1.0);
                            final perItemH = totalH / levels.length;

                            return Positioned(
                              left: 0,
                              right: 0,
                              top: i * perItemH,
                              height: perItemH,
                              child: Semantics(
                                button: true,
                                selected: i == activePage,
                                label: l10n.aiAssistRailSemantics(i + 1, level.title),
                                child: GestureDetector(
                                  onTap: () => onTap(i),
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: Transform.scale(
                                      scale: scale,
                                      child: Opacity(
                                        opacity: opacity,
                                        child: Icon(
                                          level.icon,
                                          size: isNearest ? 21 : 16,
                                          semanticLabel: level.title,
                                          color: isNearest
                                              ? (emergencyMode ? AppColors.primaryDanger : level.accent)
                                              : AppColors.textSecondary
                                                  .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${activePage + 1}/${levels.length}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyToggle() {
    return Semantics(
      button: true,
      toggled: emergencyMode,
      label: emergencyMode ? l10n.aiAssistEmergencyToggleOn : l10n.aiAssistEmergencyToggleOff,
      child: Tooltip(
        message: emergencyMode ? l10n.aiAssistEmergencyToggleOn : l10n.aiAssistEmergencyToggleOff,
        child: GestureDetector(
          onTap: onToggleEmergency,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: 46,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: emergencyMode
                  ? AppColors.primaryDanger
                  : AppColors.surfaceHighlight,
              border: Border.all(
                color: emergencyMode
                    ? AppColors.primaryDanger
                    : AppColors.stroke,
                width: 1,
              ),
              boxShadow: emergencyMode
                  ? [
                      BoxShadow(
                        color: AppColors.primaryDanger.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              emergencyMode ? 'LIVE' : 'SOS',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: emergencyMode
                    ? Colors.white
                    : AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Snaps crisply to whichever page the user drags/flings toward.
class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({super.parent});

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapScrollPhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.8,
        stiffness: 300,
        damping: 28,
      );

  double _getTargetPixels(
      ScrollMetrics position, Tolerance tolerance, double velocity) {
    double page = position.pixels / position.viewportDimension;
    if (velocity < -tolerance.velocity) {
      page -= 0.4;
    } else if (velocity > tolerance.velocity) {
      page += 0.4;
    }
    return page.roundToDouble() * position.viewportDimension;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final target = _getTargetPixels(position, toleranceFor(position), velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(spring, position.pixels, target, velocity,
          tolerance: toleranceFor(position));
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
