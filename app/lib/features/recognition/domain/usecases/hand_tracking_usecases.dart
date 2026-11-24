import '../../../../core/utils/result.dart';
import '../entities/hand_frame.dart';
import '../repositories/hand_tracking_repository.dart';

class StartHandTrackingUseCase {
  const StartHandTrackingUseCase(this._repo);
  final HandTrackingRepository _repo;

  Future<Result<void>> call() => _repo.start();
}

class StopHandTrackingUseCase {
  const StopHandTrackingUseCase(this._repo);
  final HandTrackingRepository _repo;

  Future<void> call() => _repo.stop();
}

class WatchHandFramesUseCase {
  const WatchHandFramesUseCase(this._repo);
  final HandTrackingRepository _repo;

  Stream<HandFrame> call() => _repo.frames;
}
