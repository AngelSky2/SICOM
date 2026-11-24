/// Constantes del modelo de ML.
///
/// DEBEN coincidir con `ml/src/config.py`. Si cambias uno, cambia el otro.
abstract final class MlConstants {
  static const int sequenceLength = 30;
  static const int landmarksPerHand = 21;
  static const int coordsPerLandmark = 3;
  static const int numHands = 2;
  static const int featuresPerHand = landmarksPerHand * coordsPerLandmark; // 63
  static const int numFeatures = numHands * featuresPerHand; // 126

  /// Cada cuántos frames nuevos se ejecuta la inferencia (ventana deslizante).
  static const int inferenceStride = 5;

  /// Cuántas predicciones iguales seguidas se necesitan para aceptar una seña.
  static const int stabilityWindow = 3;

  static const String modelAsset = 'assets/models/sign_lstm.tflite';
  static const String labelsAsset = 'assets/models/labels.txt';
}
