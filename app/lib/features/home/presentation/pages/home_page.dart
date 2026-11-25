import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../widgets/feature_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyCount = context.watch<HistoryController>().entries.length;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const AppLogo(size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppConstants.appName, style: theme.textTheme.titleLarge),
                        Text(AppConstants.appTagline, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ajustes',
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('¿Qué quieres decir hoy?', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Haz señas frente a la cámara y tu teléfono hablará por ti.',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              _StartCard(onTap: () => Navigator.pushNamed(context, AppRoutes.recognition)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  FeatureTile(
                    icon: Icons.menu_book_rounded,
                    title: 'Diccionario',
                    subtitle: 'Aprende las señas soportadas',
                    color: AppColors.secondary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.dictionary),
                  ),
                  FeatureTile(
                    icon: Icons.history_rounded,
                    title: 'Historial',
                    subtitle: '$historyCount frases guardadas',
                    color: AppColors.accent,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.history),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: AppColors.brandGradient),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Traducir en tiempo real',
                          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('Cámara + IA + voz',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Comenzar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.videocam_rounded, size: 72, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
