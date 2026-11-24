import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/dictionary/presentation/pages/dictionary_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/recognition/presentation/controllers/recognition_controller.dart';
import '../../features/recognition/presentation/pages/recognition_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/controllers/splash_controller.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../di/injection_container.dart';
import 'app_routes.dart';

/// Router centralizado. Los controllers con ciclo de vida de pantalla
/// se crean aquí (scoped) para que se destruyan al salir.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.splash => ChangeNotifierProvider(
          create: (_) => sl<SplashController>(),
          child: const SplashPage(),
        ),
      AppRoutes.home => const HomePage(),
      AppRoutes.recognition => ChangeNotifierProvider(
          create: (_) => sl<RecognitionController>(),
          child: const RecognitionPage(),
        ),
      AppRoutes.dictionary => const DictionaryPage(),
      AppRoutes.history => const HistoryPage(),
      AppRoutes.settings => const SettingsPage(),
      _ => const HomePage(),
    };

    if (settings.name == AppRoutes.home) {
      return PageRouteBuilder(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      );
    }
    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }
}
