import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/tts_config.dart';
import '../../domain/repositories/tts_repository.dart';
import '../datasources/tts_datasource.dart';

class TtsRepositoryImpl implements TtsRepository {
  TtsRepositoryImpl(this._dataSource);
  final TtsDataSource _dataSource;

  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Success(null);
    } catch (e) {
      return Error(TtsFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> initialize(TtsConfig config) => _guard(() => _dataSource.initialize(config));

  @override
  Future<Result<void>> configure(TtsConfig config) => _guard(() => _dataSource.configure(config));

  @override
  Future<Result<void>> speak(String text) => _guard(() => _dataSource.speak(text));

  @override
  Future<void> stop() async {
    await _guard(_dataSource.stop);
  }
}
