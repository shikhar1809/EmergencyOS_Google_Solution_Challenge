import 'package:flutter/material.dart';

class AppColors {
  // Primary semantic colors
  static const Color primaryDanger = Color(0xFFFF1744); // Emergency Red
  static const Color primarySafe = Color(0xFF00E676);   // Safe Green
  static const Color primaryWarning = Color(0xFFFF9100); // Warning Amber
  static const Color primaryInfo = Color(0xFF2979FF);    // Info Blue

  // Dark Mode Surfaces
  static const Color background = Color(0xFF0B1220); // Deeper slate for true-dark
  static const Color surface = Color(0xFF121C2E);    // Primary surface
  static const Color surfaceHighlight = Color(0xFF1B2A44); // Elevated surface

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF0F172A); // For text on light backgrounds

  // Hairline borders/dividers
  static const Color stroke = Color(0x1FFFFFFF);

  /// Staff / admin console (slate surfaces + blue accent)
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color accentBlue = primaryInfo;

  // Gradients
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFD50000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
