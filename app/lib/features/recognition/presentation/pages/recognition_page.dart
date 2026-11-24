import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/modals/confirm_dialog.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/recognition_controller.dart';
import '../modals/recognition_settings_sheet.dart';
import '../widgets/camera_view.dart';
import '../widgets/prediction_overlay.dart';
import '../widgets/transcript_panel.dart';

class RecognitionPage extends StatefulWidget {
  const RecognitionPage({super.key});

  @override
  State<RecognitionPage> createState() => _RecognitionPageState();
}

class _RecognitionPageState extends State<RecognitionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<RecognitionController>().initialize(),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RecognitionController>();
    final threshold = context.select<SettingsController, double>((s) => s.settings.confidenceThreshold);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Traductor'),
        actions: [
          IconButton(
            tooltip: 'Cambiar cámara',
            onPressed: c.switchCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () => showRecognitionSettingsSheet(context),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraView(
                  controller: c.cameraController,
                  frame: c.frame,
                  showLandmarks: c.showLandmarks,
                  cameraError: c.cameraError,
                ),
                // Sombra superior para que el AppBar se lea sobre la cámara
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 8, 16, 0),
                    child: Column(
                      children: [
                        PredictionOverlay(
                          prediction: c.live,
                          bufferFill: c.bufferFill,
                          handsVisible: c.frame.hasHands,
                          threshold: threshold,
                          modelReady: c.modelReady,
                        ),
                        if (c.status == RecognitionStatus.error && c.error != null) ...[
                          const SizedBox(height: 12),
                          _ErrorBanner(message: c.error!),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    heroTag: 'pause',
                    backgroundColor: c.isRunning ? AppColors.danger : AppColors.secondary,
                    onPressed: c.status == RecognitionStatus.initializing ? null : c.togglePause,
                    child: c.status == RecognitionStatus.initializing
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Icon(c.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                ),
              ],
            ),
          ),
          TranscriptPanel(
            words: c.words,
            onSpeak: c.speakTranscript,
            onBackspace: c.removeLastWord,
            onClear: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Limpiar traducción',
                message: '¿Borrar todas las palabras reconocidas?',
                confirmText: 'Limpiar',
                destructive: true,
              );
              if (ok) c.clearTranscript();
            },
            onSave: () async {
              final saved = await c.saveTranscript();
              if (saved) _snack('Frase guardada en el historial');
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
