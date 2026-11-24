import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _languages = {
    'es-MX': 'Español (México)',
    'es-ES': 'Español (España)',
    'es-US': 'Español (EE. UU.)',
    'en-US': 'English (US)',
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final s = controller.settings;
    final theme = Theme.of(context);

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...children,
              ],
            ),
          ),
        );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Ajustes')),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              section('Voz (Text-to-Speech)', [
                DropdownButtonFormField<String>(
                  initialValue: _languages.containsKey(s.ttsLanguage) ? s.ttsLanguage : 'es-MX',
                  decoration: const InputDecoration(labelText: 'Idioma'),
                  items: [
                    for (final e in _languages.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.update((s) => s.copyWith(ttsLanguage: v));
                  },
                ),
                const SizedBox(height: 12),
                Text('Velocidad: ${s.speechRate.toStringAsFixed(2)}'),
                Slider(
                  value: s.speechRate,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) => controller.update((s) => s.copyWith(speechRate: v)),
                ),
                Text('Tono: ${s.pitch.toStringAsFixed(2)}'),
                Slider(
                  value: s.pitch,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) => controller.update((s) => s.copyWith(pitch: v)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: controller.testVoice,
                    icon: const Icon(Icons.record_voice_over_rounded),
                    label: const Text('Probar voz'),
                  ),
                ),
              ]),
              section('Reconocimiento', [
                Text('Confianza mínima: ${(s.confidenceThreshold * 100).round()}%'),
                Slider(
                  value: s.confidenceThreshold,
                  min: 0.5,
                  max: 0.99,
                  onChanged: (v) => controller.update((s) => s.copyWith(confidenceThreshold: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hablar automáticamente'),
                  value: s.autoSpeak,
                  onChanged: (v) => controller.update((s) => s.copyWith(autoSpeak: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mostrar puntos de la mano'),
                  value: s.showLandmarks,
                  onChanged: (v) => controller.update((s) => s.copyWith(showLandmarks: v)),
                ),
              ]),
              section('Acerca de', [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('${AppConstants.appName} v1.0.0'),
                  subtitle: Text(AppConstants.hasTrainedModel
                      ? 'MediaPipe Hands + LSTM (TFLite) en el dispositivo'
                      : 'MediaPipe Hands · modelo LSTM pendiente de entrenar'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
