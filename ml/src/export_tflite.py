"""Convierte el modelo Keras a TFLite para usarlo en Flutter (tflite_flutter).

Uso:
    python src/export_tflite.py --copy-to-app

Se fija el batch a 1 para que el LSTM se convierta en el op nativo
UNIDIRECTIONAL_SEQUENCE_LSTM y NO necesite Flex/SELECT_TF_OPS en el móvil.
(Por eso el modelo NO usa capa Masking: rompe la fusión del LSTM.)
"""
import argparse
import shutil
from pathlib import Path

import tensorflow as tf

from config import KERAS_MODEL_PATH, TFLITE_MODEL_PATH, LABELS_PATH, SEQUENCE_LENGTH, NUM_FEATURES

APP_ASSETS = Path(__file__).resolve().parents[2] / "app" / "assets" / "models"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--copy-to-app", action="store_true", help="Copiar a app/assets/models")
    parser.add_argument("--fp16", action="store_true", help="Cuantización float16 (modelo más ligero)")
    args = parser.parse_args()

    model = tf.keras.models.load_model(KERAS_MODEL_PATH)

    run = tf.function(lambda x: model(x))
    concrete = run.get_concrete_function(
        tf.TensorSpec([1, SEQUENCE_LENGTH, NUM_FEATURES], tf.float32)
    )

    converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete], model)
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
    if args.fp16:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]

    tflite_model = converter.convert()
    TFLITE_MODEL_PATH.write_bytes(tflite_model)
    print(f"TFLite guardado en {TFLITE_MODEL_PATH} ({len(tflite_model) / 1024:.1f} KB)")

    if args.copy_to_app:
        APP_ASSETS.mkdir(parents=True, exist_ok=True)
        shutil.copy(TFLITE_MODEL_PATH, APP_ASSETS / TFLITE_MODEL_PATH.name)
        shutil.copy(LABELS_PATH, APP_ASSETS / LABELS_PATH.name)
        print(f"Copiado a {APP_ASSETS}")


if __name__ == "__main__":
    main()
