/// Un punto 3D normalizado (0..1 en x/y respecto a la imagen) de MediaPipe.
class Landmark {
  const Landmark(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

enum Handedness { left, right }

/// Una mano detectada: 21 landmarks + lateralidad.
class HandLandmarks {
  const HandLandmarks({
    required this.points,
    required this.handedness,
    this.score = 1.0,
  });

  final List<Landmark> points;
  final Handedness handedness;
  final double score;
}

/// Resultado de MediaPipe para un frame de cámara (0, 1 o 2 manos).
class HandFrame {
  const HandFrame({required this.hands, required this.timestamp});

  final List<HandLandmarks> hands;
  final DateTime timestamp;

  bool get hasHands => hands.isNotEmpty;

  static HandFrame empty() => HandFrame(hands: const [], timestamp: DateTime.now());
}
