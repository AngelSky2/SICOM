# Pipeline de ML — MediaPipe Hands + LSTM

Todo gratuito y open source (MediaPipe, TensorFlow, OpenCV).

```bash
cd ml
python3.11 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 1. Grabar dataset con la webcam (40 secuencias × 30 frames por seña)
python src/collect_data.py
#    o una sola seña:  python src/collect_data.py --action hola

# 2. Entrenar la LSTM
python src/train_lstm.py          # → models/sign_lstm.keras + models/labels.txt

# 3. Probar en el PC con la webcam
python src/realtime_test.py

# 4. Exportar a TFLite y copiarlo a la app Flutter
python src/export_tflite.py --copy-to-app   # → app/assets/models/
```

Después, en `app/lib/core/constants/app_constants.dart` pon `useMockMl = false`.

## Consejos para un buen modelo
- Graba con distintas luces, fondos, ropa y distancias; idealmente varias personas.
- 40–100 secuencias por seña es un buen inicio.
- Añade una clase `nada` (manos quietas / sin seña) para reducir falsos positivos.
- Si cambias `SEQUENCE_LENGTH` o las features, actualiza también `MlConstants` en Flutter
  y `docs/FEATURE_SPEC.md`.
