import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/hand_frame.dart';
import 'hand_landmarks_painter.dart';

/// Preview de la cámara + overlay de landmarks.
///
/// El overlay va DENTRO del mismo `FittedBox` que el preview: así ambos se
/// escalan/recortan igual y los puntos quedan exactamente sobre la mano.
/// Si no hay cámara (emulador / permiso denegado) muestra un placeholder.
class CameraView extends StatelessWidget {
  const CameraView({
    super.key,
    required this.controller,
    required this.frame,
    required this.showLandmarks,
    this.cameraError,
  });

  final CameraController? controller;
  final HandFrame frame;
  final bool showLandmarks;
  final String? cameraError;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final overlay = showLandmarks
        ? RepaintBoundary(child: CustomPaint(painter: HandLandmarksPainter(frame: frame)))
        : const SizedBox.shrink();

    if (c == null || !c.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [_Placeholder(message: cameraError), overlay],
      );
    }

    // previewSize viene en orientación del sensor (horizontal): en vertical se invierte.
    final size = c.value.previewSize ?? const Size(640, 480);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: Stack(
            fit: StackFit.expand,
            children: [CameraPreview(c), overlay],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceLight, AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                message ?? 'Cámara no disponible',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
