import '../../../../core/utils/result.dart';
import '../entities/hand_frame.dart';

/// Contrato para obtener landmarks de manos (MediaPipe u otro proveedor).
/// El dominio no sabe si viene de un canal nativo, un mock o un video.
abstract interface class HandTrackingRepository {
  Stream<HandFrame> get frames;
  Future<Result<void>> start();
  Future<void> stop();
  Future<void> dispose();
}
