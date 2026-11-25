import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tts/domain/usecases/tts_usecases.dart';
import '../../domain/entities/sign_entry.dart';

Future<void> showSignDetailSheet(BuildContext context, SignEntry sign) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SignDetailSheet(sign: sign),
  );
}

class _SignDetailSheet extends StatelessWidget {
  const _SignDetailSheet({required this.sign});
  final SignEntry sign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.sign_language_rounded, size: 38, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sign.title, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(sign.category),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Escuchar',
                  onPressed: () => sl<SpeakTextUseCase>()(sign.title),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(sign.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            Text('Cómo hacerla', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            for (var i = 0; i < sign.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(sign.steps[i], style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Aquí irá el video/GIF de la seña',
                  style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
