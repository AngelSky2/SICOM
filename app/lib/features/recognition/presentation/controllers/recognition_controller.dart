import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/camera_service.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../tts/domain/usecases/tts_usecases.dart';
import '../../domain/entities/hand_frame.dart';
import '../../domain/entities/sign_prediction.dart';
import '../../domain/usecases/hand_tracking_usecases.dart';
import '../../domain/usecases/load_sign_model_usecase.dart';
import '../../domain/usecases/recognize_sign_usecase.dart';

enum RecognitionStatus { initializing, running, paused, error }

/// Estado de la pantalla de traducción. No conoce MediaPipe ni TFLite:
/// solo habla con casos de uso del dominio.
class RecognitionController extends ChangeNotifier {
  RecognitionController({
    required CameraService camera,
    required StartHandTrackingUseCase startTracking,
    required StopHandTrackingUseCase stopTracking,
    required WatchHandFramesUseCase watchFrames,
    required RecognizeSignUseCase recognize,
    required LoadSignModelUseCase model,
    required SpeakTextUseCase speak,
    required StopSpeakingUseCase stopSpeaking,
    required SettingsController settings,
    required HistoryController history,
  })  : _camera = camera,
        _startTracking = startTracking,
        _stopTracking = stopTracking,
        _watchFrames = watchFrames,
        _recognize = recognize,
        _model = model,
        _speak = speak,
        _stopSpeaking = stopSpeaking,
        _settings = settings,
        _history = history;

  final CameraService _camera;
  final StartHandTrackingUseCase _startTracking;
  final StopHandTrackingUseCase _stopTracking;
  final WatchHandFramesUseCase _watchFrames;
  final RecognizeSignUseCase _recognize;
  final LoadSignModelUseCase _model;
  final SpeakTextUseCase _speak;
  final StopSpeakingUseCase _stopSpeaking;
  final SettingsController _settings;
  final HistoryController _history;

  StreamSubscription<HandFrame>? _sub;
  bool _disposed = false;

  RecognitionStatus _status = RecognitionStatus.initializing;
  String? _error;
  String? _cameraError;
  HandFrame _frame = HandFrame.empty();
  SignPrediction? _live;
  double _bufferFill = 0;
  final List<String> _words = [];
  SignPrediction? _lastAccepted;

  // ---- Getters de estado para la UI ----
  RecognitionStatus get status => _status;
  String? get error => _error;
  String? get cameraError => _cameraError;
  HandFrame get frame => _frame;
  SignPrediction? get live => _live;
  SignPrediction? get lastAccepted => _lastAccepted;
  double get bufferFill => _bufferFill;
  List<String> get words => List.unmodifiable(_words);
  String get transcript => _words.join(' ');
  bool get isRunning => _status == RecognitionStatus.running;
  CameraController? get cameraController => _camera.isReady ? _camera.controller : null;
  bool get isFrontCamera => _camera.lens == CameraLensDirection.front;
  bool get showLandmarks => _settings.settings.showLandmarks;
  bool get modelReady => _model.isReady;

  Future<void> initialize() async {
    final cam = await _camera.initialize();
    cam.fold((f) => _cameraError = f.message, (_) => _cameraError = null);
    _notify();
    await _start();
  }

  Future<void> _start() async {
    _status = RecognitionStatus.initializing;
    _notify();

    final result = await _startTracking();
    result.fold(
      (failure) {
        _status = RecognitionStatus.error;
        _error = failure.message;
      },
      (_) {
        _sub ??= _watchFrames().listen(_onFrame, onError: (Object e) {
          _error = e.toString();
          _notify();
        });
        _status = RecognitionStatus.running;
        _error = null;
      },
    );
    _notify();
  }

  Future<void> _onFrame(HandFrame frame) async {
    if (_status != RecognitionStatus.running) return;
    _frame = frame;

    final s = _settings.settings;
    final step = await _recognize(frame, threshold: s.confidenceThreshold);
    _live = step.live;
    _bufferFill = step.bufferFill;

    final accepted = step.accepted;
    if (accepted != null) {
      _lastAccepted = accepted;
      _words.add(accepted.displayText);
      if (s.autoSpeak) unawaited(_speak(accepted.displayText));
    }
    _notify();
  }

  Future<void> togglePause() async {
    if (_status == RecognitionStatus.running) {
      await _stopTracking();
      _recognize.reset();
      _status = RecognitionStatus.paused;
      _frame = HandFrame.empty();
      _live = null;
      _bufferFill = 0;
      _notify();
    } else {
      await _start();
    }
  }

  Future<void> switchCamera() async {
    final wasRunning = isRunning;
    if (wasRunning) await _stopTracking();
    final r = await _camera.switchCamera();
    r.fold((f) => _cameraError = f.message, (_) => _cameraError = null);
    if (wasRunning) await _start();
    _notify();
  }

  // ---- Acciones sobre la transcripción ----
  Future<void> speakTranscript() => _speak(transcript);

  void removeLastWord() {
    if (_words.isEmpty) return;
    _words.removeLast();
    _notify();
  }

  void clearTranscript() {
    _words.clear();
    _lastAccepted = null;
    _notify();
  }

  Future<bool> saveTranscript() async {
    if (_words.isEmpty) return false;
    await _history.save(transcript);
    return true;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    unawaited(_stopTracking());
    unawaited(_stopSpeaking());
    unawaited(_camera.dispose());
    super.dispose();
  }
}
