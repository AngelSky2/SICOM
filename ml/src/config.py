"""Configuración compartida del pipeline de ML.

IMPORTANTE: estos valores DEBEN coincidir con los de la app Flutter
(lib/core/constants/ml_constants.dart). Si cambias uno, cambia el otro.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "data"
MODELS_DIR = ROOT / "models"

# Señas que el modelo aprenderá. El índice de cada una es su clase.
# Añade/quita señas aquí y vuelve a recolectar + entrenar.
ACTIONS = [
    "hola",
    "gracias",
    "por_favor",
    "si",
    "no",
    "ayuda",
    "agua",
    "te_quiero",
]

# Cuántos frames forman una seña (≈1 s a 30 fps)
SEQUENCE_LENGTH = 30
# Cuántas secuencias grabar por seña en la recolección
SEQUENCES_PER_ACTION = 40

# 2 manos x 21 landmarks x (x, y, z)
LANDMARKS_PER_HAND = 21
COORDS_PER_LANDMARK = 3
NUM_HANDS = 2
NUM_FEATURES = NUM_HANDS * LANDMARKS_PER_HAND * COORDS_PER_LANDMARK  # 126

# Entrenamiento
EPOCHS = 200
BATCH_SIZE = 32
TEST_SIZE = 0.15
SEED = 42

KERAS_MODEL_PATH = MODELS_DIR / "sign_lstm.keras"
TFLITE_MODEL_PATH = MODELS_DIR / "sign_lstm.tflite"
LABELS_PATH = MODELS_DIR / "labels.txt"
