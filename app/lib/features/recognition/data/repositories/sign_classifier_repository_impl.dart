import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/sign_prediction.dart';
import '../../domain/repositories/sign_classifier_repository.dart';
import '../datasources/sign_classifier_datasource.dart';
import '../models/sign_prediction_model.dart';

class SignClassifierRepositoryImpl implements SignClassifierRepository {
  SignClassifierRepositoryImpl(this._dataSource);
  final SignClassifierDataSource _dataSource;
  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  List<String> get labels => _dataSource.labels;

  @override
  Future<Result<void>> load() async {
    try {
      await _dataSource.load();
      _loaded = true;
      return const Success(null);
    } catch (e) {
      return Error(ModelFailure('No se pudo cargar el modelo: $e'));
    }
  }

  @override
  Future<Result<SignPrediction>> classify(List<List<double>> sequence) async {
    if (!_loaded) return const Error(ModelFailure('Modelo no cargado'));
    try {
      final probs = await _dataSource.predict(sequence);
      return Success(SignPredictionModel.fromProbabilities(probs, labels));
    } catch (e) {
      return Error(ModelFailure(e.toString()));
    }
  }

  @override
  void dispose() {
    _dataSource.dispose();
    _loaded = false;
  }
}
