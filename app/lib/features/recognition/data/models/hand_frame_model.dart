import '../../domain/entities/hand_frame.dart';

/// DTO que sabe (de)serializar lo que llega del canal nativo de MediaPipe.
///
/// Formato esperado desde Kotlin/Swift:
/// ```json
/// { "timestamp": 123456789,
///   "hands": [ { "handedness": "Left", "score": 0.98,
///                "landmarks": [x0, y0, z0, x1, y1, z1, ... x20, y20, z20] } ] }
/// ```
class HandFrameModel extends HandFrame {
  const HandFrameModel({required super.hands, required super.timestamp});

  factory HandFrameModel.fromMap(Map<dynamic, dynamic> map) {
    final rawHands = (map['hands'] as List?) ?? const [];
    final hands = <HandLandmarks>[];

    for (final raw in rawHands.cast<Map<dynamic, dynamic>>()) {
      final flat = (raw['landmarks'] as List).cast<num>();
      final points = <Landmark>[
        for (var i = 0; i + 2 < flat.length; i += 3)
          Landmark(flat[i].toDouble(), flat[i + 1].toDouble(), flat[i + 2].toDouble()),
      ];
      hands.add(HandLandmarks(
        points: points,
        handedness: (raw['handedness'] as String).toLowerCase() == 'left'
            ? Handedness.left
            : Handedness.right,
        score: (raw['score'] as num?)?.toDouble() ?? 1.0,
      ));
    }

    final ts = map['timestamp'] as int?;
    return HandFrameModel(
      hands: hands,
      timestamp: ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.now(),
    );
  }
}
