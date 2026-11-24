import '../../../../core/utils/result.dart';
import '../entities/sign_prediction.dart';

/// Contrato del clasificador de señas (LSTM en TFLite, mock o API remota).
abstract interface class SignClassifierRepository {
  bool get isLoaded;
  List<String> get labels;

  Future<Result<void>> load();

  /// [sequence]: `sequenceLength` vectores de `numFeatures` floats ya normalizados.
  Future<Result<SignPrediction>> classify(List<List<double>> sequence);

  void dispose();
}
