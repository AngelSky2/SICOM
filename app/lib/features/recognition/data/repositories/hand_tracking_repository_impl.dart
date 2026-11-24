import 'package:flutter/services.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/hand_frame.dart';
import '../../domain/repositories/hand_tracking_repository.dart';
import '../datasources/hand_landmarker_datasource.dart';

class HandTrackingRepositoryImpl implements HandTrackingRepository {
  HandTrackingRepositoryImpl(this._dataSource);
  final HandLandmarkerDataSource _dataSource;

  @override
  Stream<HandFrame> get frames => _dataSource.frames;

  @override
  Future<Result<void>> start() async {
    try {
      await _dataSource.start();
      return const Success(null);
    } on MissingPluginException {
      return const Error(HandTrackingFailure(
        'El módulo nativo de MediaPipe aún no está implementado. Activa el modo demo.',
      ));
    } on PlatformException catch (e) {
      return Error(HandTrackingFailure(e.message ?? e.code));
    } catch (e) {
      return Error(HandTrackingFailure(e.toString()));
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _dataSource.stop();
    } catch (_) {
      // Detener nunca debe romper la UI.
    }
  }

  @override
  Future<void> dispose() => _dataSource.dispose();
}
