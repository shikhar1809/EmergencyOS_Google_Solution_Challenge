import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerGenerator {
  /// Flat, minimal pin — small circle + icon (matches dark UI, no 3D extrusion).
  ///
  /// When [withActiveSosGlow] is true, draws soft concentric halos so the pin
  /// reads as an active emergency on the map.
  static Future<BitmapDescriptor> getMinimalPin(
    IconData iconData,
    Color bgColor, {
    double size = 40,
    bool withActiveSosGlow = false,
  }) async {
    final double glowPad = withActiveSosGlow ? size * 0.68 : 0;
    final double total = size + glowPad * 2;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Offset c = Offset(total / 2, total / 2);

    if (withActiveSosGlow) {
      final halos = <(double radius, double alpha)>[
        (size * 0.95 + glowPad * 0.92, 0.07),
        (size * 0.78 + glowPad * 0.72, 0.11),
        (size * 0.62 + glowPad * 0.52, 0.15),
        (size * 0.52 + glowPad * 0.38, 0.20),
      ];
      for (final h in halos) {
        canvas.drawCircle(
          c,
          h.$1,
          Paint()
            ..color = bgColor.withValues(alpha: h.$2)
            ..style = PaintingStyle.fill,
        );
      }
      canvas.drawCircle(
        c,
        (size / 2) + 4,
        Paint()
          ..color = Colors.orangeAccent.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final double r = (size / 2) - 2;
    final Paint fill = Paint()
      ..color = bgColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final Paint border = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(c, r, fill);
    canvas.drawCircle(c, r, border);

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.48,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((total - textPainter.width) / 2, (total - textPainter.height) / 2),
    );

    final ui.Image image =
        await pictureRecorder.endRecording().toImage(total.ceil(), total.ceil());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> getCustomIcon(IconData iconData, Color bgColor) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 48.0;
    final double radius = (size / 2) - (size * 0.1);
    final double extrusionOffset = size * 0.08;

    // Draw 3D Extrusion (Bottom shadow layer)
    final Paint extrusionPaint = Paint()..color = bgColor.withValues(alpha: 0.6);
    // Extrude downwards
    canvas.drawCircle(Offset(size / 2, (size / 2) + extrusionOffset), radius, extrusionPaint);

    // Draw background circle (Top face)
    final Paint paint = Paint()
      ..color = bgColor
      ..shader = ui.Gradient.radial(
        Offset(size / 3, size / 3),
        size / 2,
        [Colors.white.withValues(alpha: 0.3), bgColor, bgColor.withValues(alpha: 0.8)],
        [0.0, 0.4, 1.0],
      );
    canvas.drawCircle(const Offset(size / 2, size / 2), radius, paint);

    // Draw white border for top face
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.06;
    canvas.drawCircle(const Offset(size / 2, size / 2), radius, borderPaint);

    // Draw Icon inside the circle
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  /// Loads a PNG asset and returns a [BitmapDescriptor] scaled to [width] logical pixels.
  /// Falls back to a coloured default marker on any error.
  static Future<BitmapDescriptor> getAssetMarker(
    String assetPath, {
    int width = 96,
    BitmapDescriptor? fallback,
  }) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: width,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? bitmapData =
          await fi.image.toByteData(format: ui.ImageByteFormat.png);
      fi.image.dispose();
      if (bitmapData == null) {
        return fallback ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }
      return BitmapDescriptor.fromBytes(bitmapData.buffer.asUint8List());
    } catch (_) {
      return fallback ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  static Future<BitmapDescriptor> getEmojiMarker(String emoji, {double size = 64.0}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: emoji,
      style: TextStyle(fontSize: size),
    );
    textPainter.layout();
    
    // Add a soft glow behind the emoji to make it incredibly visible against dark/light maps
    final Paint glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(Offset(textPainter.width / 2, textPainter.height / 2), size / 2, glowPaint);

    textPainter.paint(canvas, const Offset(0, 0));

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      textPainter.width.toInt() + 10, 
      textPainter.height.toInt() + 10
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }
}
