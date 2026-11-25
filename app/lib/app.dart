import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/history/presentation/controllers/history_controller.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

class SicomApp extends StatelessWidget {
  const SicomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Estado global (vive toda la app). Se usa .value porque get_it es el dueño.
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: sl<SettingsController>()),
        ChangeNotifierProvider<HistoryController>.value(value: sl<HistoryController>()),
      ],
      // Solo se reconstruye cuando cambia el tema de color.
      child: Selector<SettingsController, AppThemeColor>(
        selector: (_, s) => s.settings.themeColor,
        builder: (_, themeColor, _) {
          _applyTheme(themeColor);
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }

  static AppThemeColor? _current;

  /// Cambia la paleta de [AppColors]. Como muchos widgets leen AppColors
  /// directamente (no vía Theme.of), tras el cambio se fuerza a repintar
  /// todas las pantallas abiertas, incluidas las que están detrás en la pila.
  static void _applyTheme(AppThemeColor theme) {
    if (_current == theme) return;
    final firstTime = _current == null;
    _current = theme;
    AppColors.apply(theme);
    if (firstTime) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void rebuild(Element e) {
        e.markNeedsBuild();
        e.visitChildren(rebuild);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
    });
  }
}
