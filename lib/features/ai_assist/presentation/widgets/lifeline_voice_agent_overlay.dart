import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emergency_os/core/theme/app_colors.dart';
import 'package:emergency_os/services/lifeline_voice_agent_service.dart';

class LifelineVoiceAgentOverlay extends ConsumerStatefulWidget {
  final int? activeLevelIndex;
  final String? activeLevelTitle;
  final EdgeInsets safePadding;

  const LifelineVoiceAgentOverlay({
    super.key,
    this.activeLevelIndex,
    this.activeLevelTitle,
    this.safePadding = EdgeInsets.zero,
  });

  @override
  ConsumerState<LifelineVoiceAgentOverlay> createState() =>
      _LifelineVoiceAgentOverlayState();
}

class _LifelineVoiceAgentOverlayState
    extends ConsumerState<LifelineVoiceAgentOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  LifelineVoiceState _state = LifelineVoiceState.idle;
  StreamSubscription<LifelineVoiceState>? _stateSubscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _setupVoiceAgent();
    }
  }

  void _setupVoiceAgent() {
    final service = LifelineVoiceAgentService.instance;
    service.setOnStateChanged((state) {
      if (mounted) {
        setState(() => _state = state);
        if (state == LifelineVoiceState.listening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });

    service.setOnOfflineFallback((keyword) {
      if (mounted) {
        _navigateToLevel(keyword);
      }
    });

    service.setLanguage('en');
  }

  void _navigateToLevel(String keyword) {
    context.go('/drill/lifeline');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stateSubscription?.cancel();
    LifelineVoiceAgentService.instance.dispose();
    super.dispose();
  }

  void _onAgentTap() {
    final service = LifelineVoiceAgentService.instance;

    switch (_state) {
      case LifelineVoiceState.idle:
        HapticFeedback.mediumImpact();
        service.startListening();
        break;
      case LifelineVoiceState.listening:
        HapticFeedback.lightImpact();
        service.stopListening();
        break;
      case LifelineVoiceState.processing:
        HapticFeedback.lightImpact();
        service.cancel();
        break;
      case LifelineVoiceState.speaking:
        HapticFeedback.lightImpact();
        service.cancel();
        break;
    }
  }

  Color _agentColor() {
    switch (_state) {
      case LifelineVoiceState.idle:
        return AppColors.textSecondary;
      case LifelineVoiceState.listening:
        return const Color(0xFFFF1744);
      case LifelineVoiceState.processing:
        return const Color(0xFF2979FF);
      case LifelineVoiceState.speaking:
        return const Color(0xFF00E676);
    }
  }

  List<BoxShadow> _agentShadows() {
    final pulse = _state == LifelineVoiceState.listening
        ? 0.4 + 0.45 * _pulseController.value
        : 0.3;

    switch (_state) {
      case LifelineVoiceState.idle:
        return [];
      case LifelineVoiceState.listening:
        return [
          BoxShadow(
            color: const Color(0xFFFF1744).withValues(alpha: pulse),
            blurRadius: 18 + 14 * _pulseController.value,
            spreadRadius: 2 + 2 * _pulseController.value,
          ),
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: 0.35 * pulse),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ];
      case LifelineVoiceState.processing:
        return [
          BoxShadow(
            color: const Color(0xFF2979FF).withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ];
      case LifelineVoiceState.speaking:
        return [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.5),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ];
    }
  }

  String _tooltipText() {
    switch (_state) {
      case LifelineVoiceState.idle:
        return 'Tap and hold to ask about first aid';
      case LifelineVoiceState.listening:
        return 'Release to process';
      case LifelineVoiceState.processing:
        return 'Processing...';
      case LifelineVoiceState.speaking:
        return 'Tap to stop';
    }
  }

  double _agentScale() {
    if (_state != LifelineVoiceState.listening) return 1.0;
    return 1.0 + 0.08 * _pulseController.value;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = widget.safePadding.bottom + 16;
    final right = 16.0;

    return Positioned(
      right: right,
      bottom: bottom,
      child: Tooltip(
        message: _tooltipText(),
        child: GestureDetector(
          onTap: _onAgentTap,
          behavior: HitTestBehavior.opaque,
          child: Transform.scale(
            scale: _agentScale(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _agentColor().withValues(alpha: 0.2),
                    _agentColor().withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: _agentColor(),
                  width: _state == LifelineVoiceState.idle ? 1.5 : 2.5,
                ),
                boxShadow: _agentShadows(),
              ),
              child: _buildAvatar(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_state == LifelineVoiceState.speaking)
          _buildSoundWaves(),
        if (_state == LifelineVoiceState.listening)
          _buildListeningIndicator(),
        Icon(
          Icons.medical_services_rounded,
          size: 28,
          color: _agentColor(),
        ),
      ],
    );
  }

  Widget _buildListeningIndicator() {
    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _agentColor(),
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildSoundWaves() {
    return SizedBox(
      width: 50,
      height: 50,
      child: CustomPaint(
        painter: _SoundWavePainter(
          color: _agentColor(),
          progress: _pulseController.value,
        ),
      ),
    );
  }
}

class _SoundWavePainter extends CustomPainter {
  final Color color;
  final double progress;

  _SoundWavePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final delay = i * 0.2;
      final adjustedProgress = ((progress + delay) % 1.0);
      final radius = maxRadius * 0.6 + (maxRadius * 0.5 * adjustedProgress);
      final opacity = (1.0 - adjustedProgress) * 0.5;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
