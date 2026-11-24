/// Errores de dominio. La capa de datos traduce excepciones técnicas
/// (PlatformException, IOException, etc.) a estos tipos.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

class ModelFailure extends Failure {
  const ModelFailure(super.message);
}

class HandTrackingFailure extends Failure {
  const HandTrackingFailure(super.message);
}

class TtsFailure extends Failure {
  const TtsFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
