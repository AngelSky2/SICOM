import 'package:flutter/material.dart';

/// Temas de color disponibles (se eligen en Ajustes → Apariencia).
enum AppThemeColor {
  blue('Azul'),
  green('Verde');

  const AppThemeColor(this.label);
  final String label;

  static AppThemeColor fromName(String? name) =>
      AppThemeColor.values.firstWhere((t) => t.name == name, orElse: () => AppThemeColor.blue);
}

/// Paleta completa de un tema (todos son oscuros).
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.textSecondary,
    required this.backgroundTop,
  });

  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color textSecondary;

  /// Color superior del degradado de fondo.
  final Color backgroundTop;

  static const blue = AppPalette(
    primary: Color(0xFF6C63FF),
    secondary: Color(0xFF00D1B2),
    background: Color(0xFF0F1020),
    surface: Color(0xFF1A1B2E),
    surfaceLight: Color(0xFF26284A),
    textSecondary: Color(0xFFA3A6C8),
    backgroundTop: Color(0xFF15163A),
  );

  /// Verde suave tipo menta/esmeralda sobre fondo verde muy oscuro.
  static const green = AppPalette(
    primary: Color(0xFF3DBE8B),
    secondary: Color(0xFF9BE15D),
    background: Color(0xFF0B1611),
    surface: Color(0xFF14231C),
    surfaceLight: Color(0xFF1F3A2D),
    textSecondary: Color(0xFFA2C2B3),
    backgroundTop: Color(0xFF12301F),
  );

  static AppPalette of(AppThemeColor t) => switch (t) {
        AppThemeColor.blue => blue,
        AppThemeColor.green => green,
      };
}

/// Colores de la app. Dependen del tema activo ([apply]), por eso son
/// getters y NO constantes: no se pueden usar dentro de expresiones `const`.
abstract final class AppColors {
  static AppPalette _p = AppPalette.blue;

  static void apply(AppThemeColor theme) => _p = AppPalette.of(theme);

  static Color get primary => _p.primary;
  static Color get secondary => _p.secondary;
  static const Color accent = Color(0xFFFFB547);
  static const Color danger = Color(0xFFFF5C7A);

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceLight => _p.surfaceLight;

  static const Color textPrimary = Color(0xFFF5F6FF);
  static Color get textSecondary => _p.textSecondary;

  static LinearGradient get brandGradient => LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get backgroundGradient => LinearGradient(
        colors: [_p.backgroundTop, background],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
