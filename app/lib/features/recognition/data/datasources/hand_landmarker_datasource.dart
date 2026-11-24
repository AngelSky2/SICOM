import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/camera_service.dart';
import '../models/hand_frame_model.dart';
import '../../domain/entities/hand_frame.dart';

/// Fuente de landmarks de manos.
abstract interface class HandLandmarkerDataSource {
  Stream<HandFrameModel> get frames;
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

/// Implementación REAL: envía cada frame de la cámara al MediaPipe
/// HandLandmarker nativo (Android: `com.google.mediapipe:tasks-vision`,
/// iOS: `MediaPipeTasksVision`) a través de un MethodChannel.
///
/// El lado nativo (Kotlin/Swift) se implementa en la siguiente fase;
/// el contrato del canal está documentado en `docs/ARCHITECTURE.md`.
class MediaPipeHandLandmarkerDataSource implements HandLandmarkerDataSource {
  MediaPipeHandLandmarkerDataSource(this._camera);

  static const _channel = MethodChannel('sena_voz/hand_landmarker');

  final CameraService _camera;
  final _controller = StreamController<HandFrameModel>.broadcast();
  bool _processing = false;

  @override
  Stream<HandFrameModel> get frames => _controller.stream;

  @override
  Future<void> start() async {
    await _channel.invokeMethod<void>('init', {'maxHands': 2, 'minConfidence': 0.6});
    await _camera.startImageStream(_onImage);
  }

  Future<void> _onImage(CameraImage image) async {
    if (_processing) return; // descarta frames si el anterior sigue en proceso
    _processing = true;
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>('detect', {
        'width': image.width,
        'height': image.height,
        'format': image.format.group.name,
        'rotation': _camera.controller?.description.sensorOrientation ?? 0,
        // Cámara frontal: se espeja para coincidir con el preview y el entrenamiento.
        'mirror': _camera.lens == CameraLensDirection.front,
        'planes': [for (final p in image.planes) p.bytes],
        'rowStrides': [for (final p in image.planes) p.bytesPerRow],
        'pixelStrides': [for (final p in image.planes) p.bytesPerPixel ?? 1],
      });
      if (result != null && !_controller.isClosed) {
        _controller.add(HandFrameModel.fromMap(result));
      }
    } on PlatformException catch (e) {
      _controller.addError(e);
    } finally {
      _processing = false;
    }
  }

  @override
  Future<void> stop() async {
    await _camera.stopImageStream();
    await _channel.invokeMethod<void>('close');
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}

/// Implementación SIMULADA: genera una mano animada a ~30 fps.
/// Permite desarrollar y probar toda la UI sin MediaPipe ni dispositivo real.
class MockHandLandmarkerDataSource implements HandLandmarkerDataSource {
  final _controller = StreamController<HandFrameModel>.broadcast();
  Timer? _timer;
  final _stopwatch = Stopwatch();

  /// Mano abierta "plantilla" (offsets relativos a la muñeca, coords de imagen).
  static const List<(double, double)> _template = [
    (0, 0), // muñeca
    (-0.06, -0.04), (-0.10, -0.09), (-0.13, -0.13), (-0.16, -0.16), // pulgar
    (-0.04, -0.15), (-0.045, -0.22), (-0.05, -0.27), (-0.055, -0.31), // índice
    (0, -0.16), (0, -0.24), (0, -0.29), (0, -0.33), // medio
    (0.04, -0.15), (0.045, -0.22), (0.05, -0.26), (0.055, -0.30), // anular
    (0.075, -0.13), (0.085, -0.18), (0.09, -0.21), (0.095, -0.24), // meñique
  ];

  @override
  Stream<HandFrameModel> get frames => _controller.stream;

  @override
  Future<void> start() async {
    _stopwatch.start();
    _timer ??= Timer.periodic(const Duration(milliseconds: 33), (_) => _emit());
  }

  void _emit() {
    final t = _stopwatch.elapsedMilliseconds / 1000.0;
    // Cada ~6 s la mano "sale de cuadro" 1 s para simular pausas entre señas.
    final visible = (t % 6) < 5;
    final hands = visible ? [_hand(t)] : const <HandLandmarks>[];
    _controller.add(HandFrameModel(hands: hands, timestamp: DateTime.now()));
  }

  HandLandmarks _hand(double t) {
    final cx = 0.5 + 0.08 * math.sin(t * 0.9);
    final cy = 0.72 + 0.04 * math.cos(t * 1.3);
    final curl = (math.sin(t * 2.2) + 1) / 2; // 0 = abierta, 1 = cerrada
    final points = <Landmark>[];

    for (var i = 0; i < _template.length; i++) {
      var (dx, dy) = _template[i];
      if (i > 0) {
        final finger = (i - 1) ~/ 4;
        final joint = (i - 1) % 4; // 0 = base del dedo
        final base = _template[finger * 4 + 1];
        final k = joint == 0 ? 0.0 : curl * 0.55 * (finger == 0 ? 0.5 : 1);
        dx = dx - (dx - base.$1) * k;
        dy = dy - (dy - base.$2) * k;
      }
      points.add(Landmark(cx + dx, cy + dy, -0.02 * (i % 4)));
    }
    return HandLandmarks(points: points, handedness: Handedness.right, score: 0.97);
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
