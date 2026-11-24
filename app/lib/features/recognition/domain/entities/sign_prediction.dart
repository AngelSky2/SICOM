/// Salida del clasificador LSTM para una ventana de frames.
class SignPrediction {
  const SignPrediction({
    required this.label,
    required this.confidence,
    this.probabilities = const [],
  });

  /// Etiqueta cruda del modelo, ej: `por_favor`.
  final String label;
  final double confidence;
  final List<double> probabilities;

  /// Texto legible para mostrar/hablar, ej: `Por favor`.
  String get displayText {
    final text = label.replaceAll('_', ' ');
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }
}

/// Lo que devuelve el pipeline de reconocimiento por cada frame procesado.
class RecognitionStep {
  const RecognitionStep({
    this.live,
    this.accepted,
    required this.bufferFill,
  });

  /// Última predicción cruda (puede fluctuar).
  final SignPrediction? live;

  /// Seña confirmada (estable y sobre el umbral). Solo se emite una vez por seña.
  final SignPrediction? accepted;

  /// 0..1: qué tan lleno está el buffer de la secuencia.
  final double bufferFill;
}
