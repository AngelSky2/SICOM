import 'dart:math' as math;

import '../../../../core/constants/ml_constants.dart';
import '../entities/hand_frame.dart';

/// Convierte un [HandFrame] en el vector de 126 features que espera la LSTM.
///
/// Es un espejo EXACTO de `normalize_hand` / `extract_keypoints` en
/// `ml/src/keypoints.py`. Ver `docs/FEATURE_SPEC.md`.
class KeypointNormalizer {
  const KeypointNormalizer();

  List<double> call(HandFrame frame) {
    var left = List<double>.filled(MlConstants.featuresPerHand, 0);
    var right = List<double>.filled(MlConstants.featuresPerHand, 0);

    for (final hand in frame.hands) {
      if (hand.points.length != MlConstants.landmarksPerHand) continue;
      final vec = _normalizeHand(hand.points);
      if (hand.handedness == Handedness.left) {
        left = vec;
      } else {
        right = vec;
      }
    }
    return [...left, ...right];
  }

  List<double> _normalizeHand(List<Landmark> pts) {
    final wrist = pts.first;
    double scale = 0;
    for (final p in pts) {
      scale = math.max(scale, (p.x - wrist.x).abs());
      scale = math.max(scale, (p.y - wrist.y).abs());
    }
    final s = scale > 1e-6 ? scale : 1.0;

    return [
      for (final p in pts) ...[
        (p.x - wrist.x) / s,
        (p.y - wrist.y) / s,
        (p.z - wrist.z) / s,
      ],
    ];
  }
}
