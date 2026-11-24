import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF00D1B2);
  static const Color accent = Color(0xFFFFB547);
  static const Color danger = Color(0xFFFF5C7A);

  static const Color background = Color(0xFF0F1020);
  static const Color surface = Color(0xFF1A1B2E);
  static const Color surfaceLight = Color(0xFF26284A);

  static const Color textPrimary = Color(0xFFF5F6FF);
  static const Color textSecondary = Color(0xFFA3A6C8);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF15163A), background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
