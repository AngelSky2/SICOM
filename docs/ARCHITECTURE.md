# Arquitectura de SeñaVoz

## 1. Visión general

```
 ┌──────────────┐   frames    ┌────────────────────┐  landmarks  ┌──────────────────┐
 │  Cámara      │ ──────────► │ MediaPipe Hands    │ ──────────► │ KeypointNormalizer│
 │ (camera pkg) │             │ (nativo, on-device)│  21×3×2     │  → vector 126     │
 └──────────────┘             └────────────────────┘             └────────┬─────────┘
                                                                          │
                                                                ventana deslizante 30
                                                                          ▼
 ┌──────────────┐   texto     ┌────────────────────┐  softmax    ┌──────────────────┐
 │ flutter_tts  │ ◄────────── │ PredictionSmoother │ ◄────────── │ LSTM (.tflite)   │
 │  (voz)       │             │ estabilidad+umbral │             │ tflite_flutter   │
 └──────────────┘             └────────────────────┘             └──────────────────┘
```

Todo ocurre **en el dispositivo**: no hay latencia de red, funciona sin internet y es gratis.

## 2. Clean Architecture por features

```
lib/
├── main.dart                 # arranque: bindings, orientación, DI
├── app.dart                  # MaterialApp + providers globales
├── core/                     # transversal, sin lógica de negocio de una feature
│   ├── constants/            # AppConstants, MlConstants (espejo de ml/src/config.py)
│   ├── di/                   # injection_container.dart (get_it) ← único que conoce implementaciones
│   ├── error/                # Failure (sealed): CameraFailure, ModelFailure…
│   ├── router/               # rutas con nombre + creación de controllers por pantalla
│   ├── services/             # CameraService (dueño único del CameraController)
│   ├── theme/                # colores y ThemeData
│   └── utils/                # Result<T> (Success | Error)
├── shared/
│   ├── widgets/              # GlassCard, AppLogo, GradientBackground
│   └── modals/               # showConfirmDialog
└── features/
    ├── splash/               # pantalla de carga: ajustes → TTS → modelo → detector
    ├── home/                 # menú principal
    ├── recognition/          # ★ núcleo: cámara + MediaPipe + LSTM
    │   ├── domain/
    │   │   ├── entities/     # HandFrame, Landmark, SignPrediction, RecognitionStep
    │   │   ├── repositories/ # HandTrackingRepository, SignClassifierRepository (interfaces)
    │   │   ├── services/     # KeypointNormalizer, SequenceBuffer, PredictionSmoother (Dart puro)
    │   │   └── usecases/     # Start/Stop/WatchHandTracking, LoadSignModel, RecognizeSign
    │   ├── data/
    │   │   ├── models/       # HandFrameModel.fromMap, SignPredictionModel.fromProbabilities
    │   │   ├── datasources/  # MediaPipe (MethodChannel) | Mock · TFLite | Mock
    │   │   └── repositories/ # *_impl: traducen excepciones → Failure
    │   └── presentation/
    │       ├── controllers/  # RecognitionController (ChangeNotifier)
    │       ├── pages/        # RecognitionPage
    │       ├── widgets/      # CameraView, HandLandmarksPainter, PredictionOverlay, TranscriptPanel
    │       └── modals/       # RecognitionSettingsSheet
    ├── tts/                  # domain + data (flutter_tts), sin UI propia
    ├── dictionary/           # catálogo de señas + SignDetailSheet
    ├── history/              # frases guardadas (shared_preferences)
    └── settings/             # voz, umbral, overlay (shared_preferences)
```

### Regla de dependencias
```
presentation ──► domain ◄── data
```
- **domain**: Dart puro. No importa Flutter, camera, tflite ni MediaPipe. Testeable al 100 %.
- **data**: implementa las interfaces del dominio. Aquí viven los paquetes externos.
- **presentation**: widgets + controllers. Solo llaman casos de uso.
- **Modelos vs entidades**: `HandFrameModel extends HandFrame` sabe parsear el mapa del canal nativo;
  el dominio solo ve `HandFrame`.
- **Modales**: cada feature tiene su carpeta `presentation/modals/`; los genéricos van en `shared/modals/`.

### Estado e inyección
- **get_it** (`sl`) construye todo el grafo. Cambiar *mock ↔ real* es una sola línea:
  `AppConstants.useMockMl`.
- **provider** expone los `ChangeNotifier` a la UI:
  - Globales (`SettingsController`, `HistoryController`): lazySingleton + `ChangeNotifierProvider.value`.
  - Por pantalla (`SplashController`, `RecognitionController`): factory, creados en `AppRouter`
    y destruidos al salir (libera cámara y detector).
- `RecognizeSignUseCase` es *stateful* (buffer de 30 frames) → `registerFactory`.

## 3. Flujo de reconocimiento por frame
1. `CameraService` entrega `CameraImage` (YUV420 en Android).
2. `MediaPipeHandLandmarkerDataSource` lo manda por `MethodChannel('sena_voz/hand_landmarker')`.
3. Nativo responde `{hands:[{handedness, score, landmarks:[63 floats]}], timestamp}`.
4. `RecognizeSignUseCase`: normaliza → buffer → cada 5 frames llama a la LSTM → suaviza.
5. `RecognitionController` añade la palabra a la transcripción y, si `autoSpeak`, llama a `SpeakTextUseCase`.

## 4. Contrato del canal nativo (pendiente de implementar)

| Método  | Argumentos | Respuesta |
|---------|-----------|-----------|
| `init`  | `{maxHands:int, minConfidence:double}` | `null` |
| `detect`| `{width, height, format, rotation, planes:[Uint8List], rowStrides:[int], pixelStrides:[int]}` | `{timestamp:int, hands:[{handedness:"Left"\|"Right", score:double, landmarks:[x,y,z ×21]}]}` |
| `close` | — | `null` |

Android: `com.google.mediapipe:tasks-vision` + `hand_landmarker.task` en `android/app/src/main/assets/`,
`HandLandmarker` en `RunningMode.VIDEO` (o `LIVE_STREAM`). iOS: pod `MediaPipeTasksVision`.

## 5. ¿Backend aparte?
**No hace falta.** MediaPipe y la LSTM en TFLite corren en el celular a 30 fps.
Un backend solo tendría sentido para:
- Entrenar/servir modelos grandes (Transformers sobre video completo).
- Sincronizar historial entre dispositivos o recolectar datos de usuarios (con consentimiento).
- Distribuir modelos nuevos sin publicar otra versión de la app.

Si en el futuro se agrega, basta con otra implementación de `SignClassifierRepository`
(p. ej. `RemoteSignClassifierDataSource` con FastAPI) sin tocar dominio ni UI.
