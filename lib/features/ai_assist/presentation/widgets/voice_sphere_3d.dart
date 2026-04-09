import 'dart:math' as math;
import 'package:flutter/material.dart';

class VoiceSphere3D extends StatefulWidget {
  final Color color;
  final bool isPulsing;
  final double size;

  const VoiceSphere3D({
    super.key,
    required this.color,
    this.isPulsing = false,
    this.size = 250,
  });

  @override
  State<VoiceSphere3D> createState() => _VoiceSphere3DState();
}

class _VoiceSphere3DState extends State<VoiceSphere3D> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
      _scaleController.forward();
    }

    // Initialize 150 particles
    for (int i = 0; i < 150; i++) {
      _particles.add(_Particle());
    }
  }

  @override
  void didUpdateWidget(VoiceSphere3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _pulseController.repeat(reverse: true);
        _scaleController.forward();
      } else {
        _pulseController.stop();
        _pulseController.animateTo(0, duration: const Duration(milliseconds: 500));
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _SpherePainter(
              particles: _particles,
              rotation: _rotationController.value * 2 * math.pi,
              pulse: _pulseController.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

final _random = math.Random();

class _Particle {
  final double theta; // 0 to pi
  final double phi;   // 0 to 2pi
  final double radiusOffset;

  _Particle()
      : theta = math.acos(_random.nextDouble() * 2 - 1),
        phi = _random.nextDouble() * 2 * math.pi,
        radiusOffset = _random.nextDouble() * 0.2 + 0.9;
}

class _SpherePainter extends CustomPainter {
  final List<_Particle> particles;
  final double rotation;
  final double pulse;
  final Color color;

  _SpherePainter({
    required this.particles,
    required this.rotation,
    required this.pulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 * 0.8;
    
    // Voice Visualizer Jitter
    // When red (listening), we add erratic movement
    double jitter = 0;
    if (color == Colors.red && pulse > 0) {
      jitter = (math.Random().nextDouble() - 0.5) * 15.0; // Simulated sound wave
    }
    
    final animatedRadius = baseRadius * (1.0 + pulse * 0.1) + jitter;

    // Background Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, animatedRadius * 1.1, glowPaint);

    final List<_ProjectedParticle> projected = [];

    for (var p in particles) {
      // Rotation around Y axis
      double currentPhi = p.phi + rotation;
      
      double x = animatedRadius * p.radiusOffset * math.sin(p.theta) * math.cos(currentPhi);
      double y = animatedRadius * p.radiusOffset * math.cos(p.theta);
      double z = animatedRadius * p.radiusOffset * math.sin(p.theta) * math.sin(currentPhi);

      // Simple 3D projection
      double focus = 400;
      double scale = focus / (focus + z);
      double dx = x * scale;
      double dy = y * scale;

      projected.add(_ProjectedParticle(Offset(dx, dy), z, scale));
    }

    // Sort by Z to handle occlusion (painter's algorithm)
    projected.sort((a, b) => b.z.compareTo(a.z));

    for (var p in projected) {
      // Opacity based on Z (deeper = dimmer)
      double alpha = ((p.z + animatedRadius) / (2 * animatedRadius)).clamp(0.2, 1.0);
      final pColor = color.withValues(alpha: alpha * 0.8);
      
      final paint = Paint()
        ..color = pColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center + p.offset, 2.5 * p.scale, paint);
      
      // Add a small inner glow to some particles
      if (alpha > 0.8) {
        canvas.drawCircle(center + p.offset, 1.0 * p.scale, Paint()..color = Colors.white.withValues(alpha: 0.5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpherePainter oldDelegate) => true;
}

class _ProjectedParticle {
  final Offset offset;
  final double z;
  final double scale;
  _ProjectedParticle(this.offset, this.z, this.scale);
}
