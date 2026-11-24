import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/history/presentation/controllers/history_controller.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

class SenaVozApp extends StatelessWidget {
  const SenaVozApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Estado global (vive toda la app). Se usa .value porque get_it es el dueño.
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: sl<SettingsController>()),
        ChangeNotifierProvider<HistoryController>.value(value: sl<HistoryController>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
