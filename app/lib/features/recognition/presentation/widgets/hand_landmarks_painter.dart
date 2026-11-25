import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/hand_frame.dart';

/// Overlay de los puntos de la mano, dibujado a la tasa de refresco de la
/// pantalla (60 fps o más).
///
/// MediaPipe entrega resultados a ~15-25 fps. Si solo se dibujara cada
/// resultado, los puntos "saltarían". Aquí cada punto se desliza hacia su
/// última posición conocida con un suavizado exponencial en cada frame de
/// pantalla, así el movimiento se ve continuo y además se reduce el temblor.
class HandLandmarksOverlay extends StatefulWidget {
  const HandLandmarksOverlay({super.key, required this.frame});

  final HandFrame frame;

  @override
  State<HandLandmarksOverlay> createState() => _HandLandmarksOverlayState();
}

class _HandLandmarksOverlayState extends State<HandLandmarksOverlay>
    with SingleTickerProviderStateMixin {
  /// Constante de tiempo del suavizado: más baja = sigue más pegado a la
  /// mano; más alta = más suave pero con más retraso.
  static const double _tauMs = 45;

  final _hands = SmoothedHands();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  List<HandLandmarks> _target = const [];

  @override
  void initState() {
    super.initState();
    _setTarget(widget.frame);
  }

  @override
  void didUpdateWidget(HandLandmarksOverlay old) {
    super.didUpdateWidget(old);
    if (!identical(old.frame, widget.frame)) _setTarget(widget.frame);
  }

  void _setTarget(HandFrame frame) {
    _target = [for (final h in frame.hands) if (h.points.length >= 21) h];
    _hands.sync(_target);
    if (_target.isEmpty) {
      _ticker.stop();
      _hands.refresh();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dtMs = _last == Duration.zero ? 16.0 : (elapsed - _last).inMicroseconds / 1000.0;
    _last = elapsed;
    _hands.stepToward(_target, 1 - math.exp(-dtMs / _tauMs));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hands.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: HandLandmarksPainter(hands: _hands), size: Size.infinite),
    );
  }
}

/// Posición mostrada (suavizada) de una mano: 21 puntos como x0,y0,x1,y1…
class SmoothedHand {
  SmoothedHand(this.handedness, this.xy);
  final Handedness handedness;
  final Float64List xy;
}

/// Estado de los puntos que se dibujan. Avisa al painter en cada frame sin
/// reconstruir ningún widget.
class SmoothedHands extends ChangeNotifier {
  final List<SmoothedHand> hands = [];

  /// Empareja las manos nuevas con las que ya se mostraban (por lateralidad).
  /// Una mano que aparece se coloca directamente, sin animación.
  void sync(List<HandLandmarks> target) {
    final next = <SmoothedHand>[];
    for (final t in target) {
      SmoothedHand? match;
      for (final h in hands) {
        if (h.handedness == t.handedness && !next.contains(h)) {
          match = h;
          break;
        }
      }
      next.add(match ?? SmoothedHand(t.handedness, _toXy(t)));
    }
    hands
      ..clear()
      ..addAll(next);
  }

  /// Acerca cada punto una fracción [a] (0..1) hacia su objetivo.
  void stepToward(List<HandLandmarks> target, double a) {
    for (var i = 0; i < hands.length && i < target.length; i++) {
      final xy = hands[i].xy;
      final pts = target[i].points;
      for (var j = 0; j < 21; j++) {
        xy[2 * j] += (pts[j].x - xy[2 * j]) * a;
        xy[2 * j + 1] += (pts[j].y - xy[2 * j + 1]) * a;
      }
    }
    notifyListeners();
  }

  void refresh() => notifyListeners();

  static Float64List _toXy(HandLandmarks h) {
    final xy = Float64List(42);
    for (var j = 0; j < 21; j++) {
      xy[2 * j] = h.points[j].x;
      xy[2 * j + 1] = h.points[j].y;
    }
    return xy;
  }
}

/// Dibuja el esqueleto de la mano (21 puntos + conexiones de MediaPipe).
class HandLandmarksPainter extends CustomPainter {
  HandLandmarksPainter({required this.hands}) : super(repaint: hands);

  final SmoothedHands hands;

  static const List<(int, int)> _connections = [
    (0, 1), (1, 2), (2, 3), (3, 4), // pulgar
    (0, 5), (5, 6), (6, 7), (7, 8), // índice
    (5, 9), (9, 10), (10, 11), (11, 12), // medio
    (9, 13), (13, 14), (14, 15), (15, 16), // anular
    (13, 17), (0, 17), (17, 18), (18, 19), (19, 20), // meñique + palma
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white;
    for (final hand in hands.hands) {
      final color = hand.handedness == Handedness.left ? AppColors.accent : AppColors.secondary;
      final line = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final halo = Paint()..color = color.withValues(alpha: 0.35);

      final xy = hand.xy;
      Offset at(int i) => Offset(xy[2 * i] * size.width, xy[2 * i + 1] * size.height);

      for (final (a, b) in _connections) {
        canvas.drawLine(at(a), at(b), line);
      }
      for (var i = 0; i < 21; i++) {
        final o = at(i);
        // Halo sólido en vez de blur: el blur por punto es caro de pintar.
        canvas.drawCircle(o, 7, halo);
        canvas.drawCircle(o, i == 0 ? 5 : 3.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(HandLandmarksPainter old) => old.hands != hands;
}
