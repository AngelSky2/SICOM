import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/hand_frame.dart';

/// Dibuja el esqueleto de la mano (21 puntos + conexiones de MediaPipe).
class HandLandmarksPainter extends CustomPainter {
  HandLandmarksPainter({required this.frame, this.mirror = false});

  final HandFrame frame;
  final bool mirror;

  static const List<(int, int)> _connections = [
    (0, 1), (1, 2), (2, 3), (3, 4), // pulgar
    (0, 5), (5, 6), (6, 7), (7, 8), // índice
    (5, 9), (9, 10), (10, 11), (11, 12), // medio
    (9, 13), (13, 14), (14, 15), (15, 16), // anular
    (13, 17), (0, 17), (17, 18), (18, 19), (19, 20), // meñique + palma
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final hand in frame.hands) {
      final color = hand.handedness == Handedness.left ? AppColors.accent : AppColors.secondary;
      final line = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final dot = Paint()..color = Colors.white;
      final glow = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      Offset at(int i) {
        final p = hand.points[i];
        final x = mirror ? 1 - p.x : p.x;
        return Offset(x * size.width, p.y * size.height);
      }

      if (hand.points.length < 21) continue;
      for (final (a, b) in _connections) {
        canvas.drawLine(at(a), at(b), line);
      }
      for (var i = 0; i < hand.points.length; i++) {
        final o = at(i);
        canvas.drawCircle(o, 7, glow);
        canvas.drawCircle(o, i == 0 ? 5 : 3.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(HandLandmarksPainter old) => old.frame != frame || old.mirror != mirror;
}
