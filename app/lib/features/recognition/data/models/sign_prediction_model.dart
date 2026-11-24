import '../../domain/entities/sign_prediction.dart';

class SignPredictionModel extends SignPrediction {
  const SignPredictionModel({
    required super.label,
    required super.confidence,
    super.probabilities,
  });

  /// Construye la predicción a partir de la salida softmax del modelo.
  factory SignPredictionModel.fromProbabilities(List<double> probs, List<String> labels) {
    var best = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    return SignPredictionModel(
      label: best < labels.length ? labels[best] : 'clase_$best',
      confidence: probs.isEmpty ? 0 : probs[best],
      probabilities: probs,
    );
  }
}
