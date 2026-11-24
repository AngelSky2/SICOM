abstract final class AppConstants {
  static const String appName = 'SeñaVoz';
  static const String appTagline = 'Tus manos tienen voz';

  /// `true` = detecta tus manos reales con MediaPipe (código nativo en Kotlin).
  /// `false` = dibuja una mano animada simulada (útil sin cámara / emulador).
  static const bool useMediaPipe = true;

  /// Pásalo a `true` cuando copies `sign_lstm.tflite` y `labels.txt` a
  /// `assets/models/` (lo hace `ml/src/export_tflite.py --copy-to-app`).
  static const bool hasTrainedModel = false;

  /// Solo para ver la UI: inventa palabras aunque no haya modelo.
  /// ¡No reconoce nada de verdad! Mantener en `false`.
  static const bool demoPredictions = false;

  static const Duration splashMinDuration = Duration(milliseconds: 2200);

  static const String defaultTtsLanguage = 'es-MX';
  static const double defaultConfidenceThreshold = 0.80;
}
