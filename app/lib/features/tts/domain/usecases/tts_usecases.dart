import '../../../../core/utils/result.dart';
import '../entities/tts_config.dart';
import '../repositories/tts_repository.dart';

class InitTtsUseCase {
  const InitTtsUseCase(this._repo);
  final TtsRepository _repo;

  Future<Result<void>> call(TtsConfig config) => _repo.initialize(config);
}

class ConfigureTtsUseCase {
  const ConfigureTtsUseCase(this._repo);
  final TtsRepository _repo;

  Future<Result<void>> call(TtsConfig config) => _repo.configure(config);
}

class SpeakTextUseCase {
  const SpeakTextUseCase(this._repo);
  final TtsRepository _repo;

  Future<Result<void>> call(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return const Success(null);
    return _repo.speak(clean);
  }
}

class StopSpeakingUseCase {
  const StopSpeakingUseCase(this._repo);
  final TtsRepository _repo;

  Future<void> call() => _repo.stop();
}
