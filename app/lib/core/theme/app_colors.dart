import 'package:flutter/material.dart';

/// MedStock brand palette — medical / corporate blue.
class AppColors {
  const AppColors._();

  // Brand blues
  static const Color primary = Color(0xFF1E63D0);
  static const Color primaryDark = Color(0xFF14459A);
  static const Color primaryLight = Color(0xFF4C8DF0);

  // Accent (availability / success)
  static const Color accent = Color(0xFF16B6A0);

  // Semantic
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF2A33C);

  // Neutrals
  static const Color ink = Color(0xFF0F1E3D); // headings / primary text
  static const Color muted = Color(0xFF64748B); // secondary text
  static const Color border = Color(0xFFE2E8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F7FC);

  // Dark mode
  static const Color darkBackground = Color(0xFF0C1526);
  static const Color darkSurface = Color(0xFF13203A);
}
