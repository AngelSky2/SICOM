import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../settings/presentation/controllers/settings_controller.dart';

/// Bottom sheet con ajustes rápidos de reconocimiento.
Future<void> showRecognitionSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _RecognitionSettingsSheet(),
  );
}

class _RecognitionSettingsSheet extends StatelessWidget {
  const _RecognitionSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final s = controller.settings;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajustes de reconocimiento', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Confianza mínima: ${(s.confidenceThreshold * 100).round()}%',
                style: theme.textTheme.titleMedium),
            Slider(
              value: s.confidenceThreshold,
              min: 0.5,
              max: 0.99,
              divisions: 49,
              onChanged: (v) => controller.update((s) => s.copyWith(confidenceThreshold: v)),
            ),
            Text('Más alto = menos errores, pero puede ignorar señas poco claras.',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hablar automáticamente'),
              subtitle: const Text('Lee en voz alta cada seña reconocida'),
              value: s.autoSpeak,
              onChanged: (v) => controller.update((s) => s.copyWith(autoSpeak: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar puntos de la mano'),
              subtitle: const Text('Overlay de landmarks de MediaPipe'),
              value: s.showLandmarks,
              onChanged: (v) => controller.update((s) => s.copyWith(showLandmarks: v)),
            ),
          ],
        ),
      ),
    );
  }
}
