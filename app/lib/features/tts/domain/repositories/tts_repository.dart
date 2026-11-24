import '../../../../core/utils/result.dart';
import '../entities/tts_config.dart';

abstract interface class TtsRepository {
  Future<Result<void>> initialize(TtsConfig config);
  Future<Result<void>> configure(TtsConfig config);
  Future<Result<void>> speak(String text);
  Future<void> stop();
}
