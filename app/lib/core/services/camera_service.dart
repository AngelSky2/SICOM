import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../error/failures.dart';
import '../utils/result.dart';

/// Único dueño del [CameraController]. La UI lo usa para el preview
/// y el datasource de MediaPipe para recibir los frames.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _lens = CameraLensDirection.front;

  CameraController? get controller => _controller;
  bool get isReady => _controller?.value.isInitialized ?? false;
  CameraLensDirection get lens => _lens;

  Future<Result<void>> initialize({CameraLensDirection? lens}) async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) return const Error(CameraFailure('No se encontraron cámaras'));

      _lens = lens ?? _lens;
      final description = _cameras.firstWhere(
        (c) => c.lensDirection == _lens,
        orElse: () => _cameras.first,
      );

      await _controller?.dispose();
      _controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      await _controller!.initialize();
      return const Success(null);
    } on CameraException catch (e) {
      return Error(CameraFailure(e.description ?? e.code));
    } catch (e) {
      return Error(CameraFailure(e.toString()));
    }
  }

  Future<Result<void>> switchCamera() {
    final next = _lens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    return initialize(lens: next);
  }

  Future<void> startImageStream(void Function(CameraImage image) onImage) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isStreamingImages) return;
    await c.startImageStream(onImage);
  }

  Future<void> stopImageStream() async {
    final c = _controller;
    if (c != null && c.value.isStreamingImages) await c.stopImageStream();
  }

  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
