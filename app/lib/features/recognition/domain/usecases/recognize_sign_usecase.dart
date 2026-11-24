import '../../../../core/constants/ml_constants.dart';
import '../entities/hand_frame.dart';
import '../entities/sign_prediction.dart';
import '../repositories/sign_classifier_repository.dart';
import '../services/keypoint_normalizer.dart';
import '../services/prediction_smoother.dart';
import '../services/sequence_buffer.dart';

/// Pipeline completo por frame:
/// HandFrame → normalizar (126) → buffer (30) → cada N frames LSTM → suavizado.
///
/// Es "stateful" (tiene buffer), así que se registra como factory en DI:
/// una instancia por sesión de reconocimiento.
class RecognizeSignUseCase {
  RecognizeSignUseCase(
    this._classifier, {
    KeypointNormalizer normalizer = const KeypointNormalizer(),
  })  : _normalizer = normalizer,
        _buffer = SequenceBuffer(MlConstants.sequenceLength),
        _smoother = PredictionSmoother(window: MlConstants.stabilityWindow);

  final SignClassifierRepository _classifier;
  final KeypointNormalizer _normalizer;
  final SequenceBuffer _buffer;
  final PredictionSmoother _smoother;

  static const int _maxEmptyFrames = 10;
  int _framesSinceInference = 0;
  int _emptyFrames = 0;
  bool _busy = false;
  SignPrediction? _lastLive;

  Future<RecognitionStep> call(HandFrame frame, {required double threshold}) async {
    if (!frame.hasHands) {
      if (++_emptyFrames >= _maxEmptyFrames) {
        reset();
        return const RecognitionStep(bufferFill: 0);
      }
    } else {
      _emptyFrames = 0;
    }

    _buffer.add(_normalizer(frame));
    _framesSinceInference++;

    final shouldInfer = _buffer.isFull &&
        _framesSinceInference >= MlConstants.inferenceStride &&
        !_busy;
    if (!shouldInfer) {
      return RecognitionStep(live: _lastLive, bufferFill: _buffer.fill);
    }

    _busy = true;
    _framesSinceInference = 0;
    try {
      final result = await _classifier.classify(_buffer.snapshot());
      return result.fold(
        (_) => RecognitionStep(live: _lastLive, bufferFill: _buffer.fill),
        (prediction) {
          _lastLive = prediction;
          final accepted = _smoother.push(prediction, threshold: threshold);
          return RecognitionStep(
            live: prediction,
            accepted: accepted,
            bufferFill: _buffer.fill,
          );
        },
      );
    } finally {
      _busy = false;
    }
  }

  void reset() {
    _buffer.clear();
    _smoother.reset();
    _framesSinceInference = 0;
    _lastLive = null;
  }
}
