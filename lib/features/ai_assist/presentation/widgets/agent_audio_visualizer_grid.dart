import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Flutter port of a LiveKit-style grid visualizer.
class AgentAudioVisualizerGrid extends StatefulWidget {
  const AgentAudioVisualizerGrid({
    super.key,
    this.size = 220,
    this.rowCount = 15,
    this.columnCount = 15,
    this.radius = 60,
    this.barCount = 5,
    this.color = const Color(0xff00fff7),
    this.active = false,
    this.level = 0.4,
  });

  final double size;
  final int rowCount;
  final int columnCount;
  final double radius;
  final int barCount;
  final Color color;
  final bool active;
  final double level;

  @override
  State<AgentAudioVisualizerGrid> createState() => _AgentAudioVisualizerGridState();
}

class _AgentAudioVisualizerGridState extends State<AgentAudioVisualizerGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _GridPainter(
            time: _controller.value,
            rowCount: widget.rowCount,
            columnCount: widget.columnCount,
            radius: widget.radius,
            barCount: widget.barCount,
            color: widget.color,
            active: widget.active,
            level: widget.level.clamp(0.0, 1.0),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.time,
    required this.rowCount,
    required this.columnCount,
    required this.radius,
    required this.barCount,
    required this.color,
    required this.active,
    required this.level,
  });

  final double time;
  final int rowCount;
  final int columnCount;
  final double radius;
  final int barCount;
  final Color color;
  final bool active;
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final totalW = size.width * 0.82;
    final totalH = size.height * 0.82;
    final cellW = totalW / columnCount;
    final cellH = totalH / rowCount;
    final startX = center.dx - totalW / 2;
    final startY = center.dy - totalH / 2;
    final t = time * math.pi * 2;

    for (var r = 0; r < rowCount; r++) {
      for (var c = 0; c < columnCount; c++) {
        final cx = startX + (c + 0.5) * cellW;
        final cy = startY + (r + 0.5) * cellH;
        final dx = cx - center.dx;
        final dy = cy - center.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        final falloff = (1 - (dist / radius).clamp(0.0, 1.0));
        final pulse = 0.5 + 0.5 * math.sin(t * 2.4 + (r + c) * 0.28);
        final amp = (active ? 0.2 : 0.08) + level * 0.75 * falloff * pulse;

        final barSpacing = (cellW * 0.66) / math.max(1, barCount);
        final barWidth = math.max(1.2, barSpacing * 0.42);
        final barBase = math.min(cellH * 0.6, 8.0);
        final left = cx - (barCount - 1) * barSpacing / 2;

        for (var i = 0; i < barCount; i++) {
          final phase = i * 0.55 + r * 0.08 + c * 0.06;
          final wave = 0.55 + 0.45 * math.sin(t * 3.4 + phase);
          final h = barBase * (0.35 + amp * wave);
          final rect = Rect.fromLTWH(
            left + i * barSpacing - barWidth / 2,
            cy - h / 2,
            barWidth,
            h,
          );
          final p = Paint()
            ..color = color.withValues(alpha: (0.14 + amp * 0.9).clamp(0.12, 0.95));
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            p,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.level != level ||
        oldDelegate.active != active ||
        oldDelegate.color != color;
  }
}
