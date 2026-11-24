import '../entities/sign_prediction.dart';

/// Estabiliza las predicciones: una seña solo se acepta si aparece
/// [window] veces seguidas sobre el umbral, y no se repite hasta que cambie.
class PredictionSmoother {
  PredictionSmoother({required this.window});

  final int window;
  final List<String> _recent = [];
  String? _lastAccepted;

  SignPrediction? push(SignPrediction p, {required double threshold}) {
    if (p.confidence < threshold) {
      _recent.clear();
      return null;
    }
    _recent.add(p.label);
    if (_recent.length > window) _recent.removeAt(0);

    final stable = _recent.length == window && _recent.every((l) => l == p.label);
    if (stable && p.label != _lastAccepted) {
      _lastAccepted = p.label;
      return p;
    }
    return null;
  }

  /// Llamar cuando las manos salen de cuadro: permite repetir la misma seña.
  void reset() {
    _recent.clear();
    _lastAccepted = null;
  }
}
