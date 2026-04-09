import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Top-down **cartoon vehicle** sprites as PNG [BitmapDescriptor]s.
/// Used for **moving units** only — not hospital / station facility pins.
abstract final class FleetVehicleMarkerArt {
  static const double _size = 96;

  static Future<BitmapDescriptor> ambulance() => _build(_drawAmbulance);

  static Future<BitmapDescriptor> _build(void Function(Canvas c, double s) draw) async {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawColor(Colors.transparent, BlendMode.clear);
    draw(canvas, _size);
    final img = await rec.endRecording().toImage(_size.toInt(), _size.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    if (bd == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    return BitmapDescriptor.fromBytes(bd.buffer.asUint8List());
  }

  /// Body aligned so **top of image = forward (north)** for [Marker.rotation].
  static void _drawAmbulance(Canvas c, double s) {
    final cx = s / 2;
    final cy = s / 2;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: s * 0.38, height: s * 0.62),
      const Radius.circular(10),
    );
    c.drawRRect(
      body,
      Paint()..color = const Color(0xFFF5F5F5),
    );
    c.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFE53935),
    );
    // Red stripe
    c.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: s * 0.32, height: s * 0.12),
      Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.9),
    );
    // Cross
    final crossPaint = Paint()..color = Colors.white;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - s * 0.08), width: s * 0.14, height: s * 0.05),
        const Radius.circular(3),
      ),
      crossPaint,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - s * 0.08), width: s * 0.05, height: s * 0.14),
        const Radius.circular(3),
      ),
      crossPaint,
    );
    // Windshield (north)
    c.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - s * 0.18), width: s * 0.22, height: s * 0.16),
      math.pi * 1.15,
      math.pi * 0.7,
      true,
      Paint()..color = const Color(0xFF81D4FA),
    );
    // Wheels
    _wheels(c, cx, cy, s);
  }

  static void _wheels(Canvas c, double cx, double cy, double s) {
    final w = Paint()..color = const Color(0xFF263238);
    for (final o in [
      Offset(cx - s * 0.16, cy + s * 0.22),
      Offset(cx + s * 0.16, cy + s * 0.22),
      Offset(cx - s * 0.14, cy - s * 0.18),
      Offset(cx + s * 0.14, cy - s * 0.18),
    ]) {
      c.drawCircle(o, s * 0.065, w);
      c.drawCircle(o, s * 0.03, Paint()..color = Colors.white24);
    }
  }
}
