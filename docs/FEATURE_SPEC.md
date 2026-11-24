# Especificación de features (contrato Python ⇄ Flutter)

El modelo solo funciona si la app genera **exactamente** los mismos números que se usaron para entrenar.
Implementaciones espejo:

- Python: `ml/src/keypoints.py` → `normalize_hand()` / `extract_keypoints()`
- Dart: `app/lib/features/recognition/domain/services/keypoint_normalizer.dart`

## Entrada del modelo

| Dimensión | Valor | Constante |
|-----------|-------|-----------|
| batch | 1 | — |
| frames por secuencia | 30 | `SEQUENCE_LENGTH` / `MlConstants.sequenceLength` |
| features por frame | 126 | `NUM_FEATURES` / `MlConstants.numFeatures` |

Tensor: `float32[1, 30, 126]` → salida `float32[1, N_CLASES]` (softmax).

## Vector por frame (126)

```
[ mano_izquierda (63) | mano_derecha (63) ]
mano = [x0,y0,z0, x1,y1,z1, ..., x20,y20,z20]
```

Por cada mano detectada:
1. `rel = p - p[0]` (se resta la muñeca → invariante a la posición)
2. `scale = max(|rel.x|, |rel.y|)` sobre los 21 puntos
3. si `scale > 1e-6`: `rel = rel / scale` (invariante a la distancia de la cámara)

Mano no detectada → 63 ceros.

## Lateralidad (¡ojo!)

MediaPipe etiqueta "Left"/"Right" asumiendo imagen **espejada** (selfie).
En `collect_data.py` se hace `cv2.flip(frame, 1)` antes de procesar.
En el móvil, el lado nativo debe entregar la imagen de la cámara frontal **también espejada**
(o invertir la etiqueta) para que coincida con el entrenamiento.

## Etiquetas

`labels.txt`, una por línea, en el mismo orden que `ACTIONS` en `ml/src/config.py`.
