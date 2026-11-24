import 'package:flutter_test/flutter_test.dart';
import 'package:sena_voz/core/constants/ml_constants.dart';
import 'package:sena_voz/features/recognition/domain/entities/hand_frame.dart';
import 'package:sena_voz/features/recognition/domain/entities/sign_prediction.dart';
import 'package:sena_voz/features/recognition/domain/services/keypoint_normalizer.dart';
import 'package:sena_voz/features/recognition/domain/services/prediction_smoother.dart';
import 'package:sena_voz/features/recognition/domain/services/sequence_buffer.dart';

HandLandmarks _hand(Handedness h, {double offset = 0, double scale = 1}) => HandLandmarks(
      handedness: h,
      points: [
        for (var i = 0; i < 21; i++) Landmark(offset + 0.01 * i * scale, offset + 0.02 * i * scale, 0.001 * i),
      ],
    );

void main() {
  group('KeypointNormalizer', () {
    const normalizer = KeypointNormalizer();

    test('produce 126 features con ceros para manos ausentes', () {
      final v = normalizer(HandFrame(hands: [_hand(Handedness.right)], timestamp: DateTime(2026)));
      expect(v.length, MlConstants.numFeatures);
      expect(v.take(63).every((x) => x == 0), isTrue); // izquierda vacía
      expect(v.skip(63).any((x) => x != 0), isTrue);
    });

    test('es invariante a traslación y escala', () {
      final a = normalizer(HandFrame(hands: [_hand(Handedness.left)], timestamp: DateTime(2026)));
      final b = normalizer(HandFrame(
          hands: [_hand(Handedness.left, offset: 0.3, scale: 2)], timestamp: DateTime(2026)));
      for (var i = 0; i < 63; i++) {
        // z no se escala igual en el fixture; comparamos x/y
        if (i % 3 == 2) continue;
        expect(a[i], closeTo(b[i], 1e-9));
      }
    });
  });

  test('SequenceBuffer mantiene solo los últimos N', () {
    final buf = SequenceBuffer(3);
    for (var i = 0; i < 5; i++) {
      buf.add([i.toDouble()]);
    }
    expect(buf.isFull, isTrue);
    expect(buf.snapshot().map((e) => e.first), [2, 3, 4]);
  });

  test('PredictionSmoother acepta solo predicciones estables y no repite', () {
    final s = PredictionSmoother(window: 3);
    const p = SignPrediction(label: 'hola', confidence: 0.9);
    expect(s.push(p, threshold: 0.8), isNull);
    expect(s.push(p, threshold: 0.8), isNull);
    expect(s.push(p, threshold: 0.8)?.label, 'hola');
    expect(s.push(p, threshold: 0.8), isNull); // no repite
    s.reset();
    for (var i = 0; i < 2; i++) {
      s.push(p, threshold: 0.8);
    }
    expect(s.push(p, threshold: 0.8)?.label, 'hola'); // tras reset sí
  });
}
