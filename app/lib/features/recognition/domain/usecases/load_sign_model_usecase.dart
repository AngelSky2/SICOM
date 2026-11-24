import '../../../../core/utils/result.dart';
import '../repositories/sign_classifier_repository.dart';

class LoadSignModelUseCase {
  const LoadSignModelUseCase(this._repo);
  final SignClassifierRepository _repo;

  bool get isReady => _repo.isLoaded;

  Future<Result<void>> call() async {
    if (_repo.isLoaded) return const Success(null);
    return _repo.load();
  }
}
