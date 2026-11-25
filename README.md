# SICOM — Traductor de lengua de señas en tiempo real

> **Tus manos tienen voz.** App móvil que reconoce lengua de señas con la cámara del celular
> y la convierte en voz, pensada para personas sordas o con dificultades del habla.

SICOM usa **MediaPipe Hands** para detectar los 21 puntos de cada mano, una red **LSTM**
(TensorFlow Lite) para clasificar la secuencia de movimientos como una seña, y **flutter_tts**
para decir la palabra en voz alta. **Todo corre dentro del teléfono**: sin servidor, sin internet
y con herramientas 100 % gratuitas y open source.

---

## Índice

1. [Estado actual del proyecto](#1-estado-actual-del-proyecto)
2. [Tecnologías](#2-tecnologías)
3. [Cómo funciona (visión general)](#3-cómo-funciona-visión-general)
4. [Estructura del repositorio](#4-estructura-del-repositorio)
5. [La app Flutter en detalle](#5-la-app-flutter-en-detalle)
6. [El código nativo de Android (MediaPipe)](#6-el-código-nativo-de-android-mediapipe)
7. [El pipeline de Machine Learning (Python)](#7-el-pipeline-de-machine-learning-python)
8. [Contrato de datos Python ⇄ Flutter](#8-contrato-de-datos-python--flutter)
9. [Configuración (interruptores)](#9-configuración-interruptores)
10. [Instalación y ejecución](#10-instalación-y-ejecución)
11. [Entrenar el modelo LSTM](#11-entrenar-el-modelo-lstm)
12. [Solución de problemas](#12-solución-de-problemas)
13. [¿Hace falta un backend?](#13-hace-falta-un-backend)
14. [Hoja de ruta](#14-hoja-de-ruta)

---

## 1. Estado actual del proyecto

| Parte | Estado |
|-------|--------|
| App Flutter (pantalla de carga, menú, traductor, diccionario, historial, ajustes) | ✅ Hecha |
| Arquitectura limpia (domain / data / presentation) + inyección de dependencias | ✅ Hecha |
| Texto a voz (flutter_tts) | ✅ Funciona |
| Detección de manos real con MediaPipe (Android, Kotlin) | ✅ Implementada |
| Dibujo de los 21 puntos sobre la mano en la cámara | ✅ Implementado |
| Scripts para grabar dataset, entrenar LSTM y exportar a TFLite | ✅ Listos |
| **Modelo LSTM entrenado** | ❌ **Pendiente**: hay que grabar el dataset y entrenar |
| iOS (lado nativo de MediaPipe) | ❌ Pendiente |

> Mientras no exista el modelo entrenado, la app **detecta y dibuja tus manos**, pero **no traduce
> señas a palabras**. En pantalla aparece *"Mano detectada · falta entrenar la LSTM"*.

---

## 2. Tecnologías

| Área | Herramienta | Para qué |
|------|-------------|----------|
| App móvil | **Flutter / Dart** | Interfaz multiplataforma |
| Estado | **provider** (`ChangeNotifier`) | Exponer el estado a los widgets |
| Inyección de dependencias | **get_it** | Construir y conectar todas las clases |
| Cámara | **camera** | Vista previa y frames en tiempo real |
| Detección de manos | **MediaPipe Tasks Vision** (`HandLandmarker`) | 21 puntos 3D por mano |
| Clasificación | **TensorFlow Lite** (`tflite_flutter`) | Ejecutar la LSTM en el celular |
| Voz | **flutter_tts** | Motor TTS nativo del teléfono |
| Persistencia | **shared_preferences** | Ajustes e historial |
| Entrenamiento | **Python + TensorFlow/Keras + MediaPipe + OpenCV** | Dataset y modelo |

---

## 3. Cómo funciona (visión general)

```
 ┌─────────────┐  imagen YUV  ┌──────────────────────┐  21 pts × 2 manos  ┌────────────────────┐
 │  Cámara     │ ───────────► │ MediaPipe (Kotlin)   │ ─────────────────► │ KeypointNormalizer │
 │ (Flutter)   │ MethodChannel│ HandLandmarker       │   (x, y, z)        │ → vector de 126    │
 └─────────────┘              └──────────────────────┘                    └─────────┬──────────┘
                                                                                    │
                                                                   ventana de los últimos 30 frames
                                                                                    ▼
 ┌─────────────┐   palabra    ┌──────────────────────┐   probabilidades   ┌────────────────────┐
 │ flutter_tts │ ◄─────────── │ PredictionSmoother   │ ◄───────────────── │ LSTM (.tflite)     │
 │  (voz)      │              │ estable + umbral     │     (softmax)      │ cada 5 frames      │
 └─────────────┘              └──────────────────────┘                    └────────────────────┘
```

Paso a paso, en cada frame de la cámara:

1. **Cámara**: `CameraService` entrega la imagen (formato YUV420 en Android).
2. **MediaPipe**: la imagen viaja por un `MethodChannel` al código Kotlin, que la gira a vertical,
   la espeja si es la cámara frontal y devuelve los **21 puntos (x, y, z)** de cada mano detectada.
3. **Normalización**: cada mano se convierte en 63 números independientes de la posición y la
   distancia a la cámara. Con dos manos son **126 números por frame**.
4. **Ventana deslizante**: se guardan los **últimos 30 frames** (≈ 1 segundo).
5. **LSTM**: cada 5 frames nuevos, la secuencia `[30 × 126]` entra al modelo, que devuelve una
   probabilidad para cada seña.
6. **Suavizado**: una seña solo se acepta si sale **3 veces seguidas** por encima del umbral de
   confianza (80 % por defecto) y no se repite hasta que cambie.
7. **Resultado**: la palabra se agrega a la frase en pantalla y, si está activado, **se dice en voz alta**.

---

## 4. Estructura del repositorio

```
SICOM/
├── README.md                ← este archivo
├── .gitignore
├── app/                     ← App Flutter (Android / iOS)
├── ml/                      ← Entrenamiento del modelo (Python)
└── docs/
    ├── ARCHITECTURE.md      ← Arquitectura resumida y contrato del canal nativo
    └── FEATURE_SPEC.md      ← Cómo se calculan los 126 números (Python ⇄ Dart)
```

### 4.1 `app/` — App Flutter

```
app/
├── pubspec.yaml                         Dependencias y assets de Flutter
├── assets/models/
│   └── labels.txt                       Nombres de las señas (aquí también irá sign_lstm.tflite)
├── test/widget_test.dart                Pruebas unitarias del dominio
├── android/
│   ├── gradle.properties                Memoria de Gradle (ajustada a PCs de ~4 GB) y opciones
│   └── app/
│       ├── build.gradle.kts             minSdk 26, dependencia de MediaPipe, noCompress "task"
│       └── src/main/
│           ├── AndroidManifest.xml      Permiso de cámara
│           ├── assets/hand_landmarker.task   Modelo de manos de Google (7,8 MB)
│           └── kotlin/com/senavoz/sena_voz/
│               ├── MainActivity.kt           Registra el canal nativo
│               └── HandLandmarkerChannel.kt  MediaPipe: imagen → 21 puntos por mano
├── ios/Runner/Info.plist                Texto del permiso de cámara (iOS)
└── lib/                                 ← Código Dart (detallado abajo)
```

### 4.2 `app/lib/` — Código Dart

```
lib/
├── main.dart                     Arranque: orientación vertical, barra de estado, DI, runApp
├── app.dart                      MaterialApp + providers globales (ajustes, historial)
│
├── core/                         Código transversal (no pertenece a una sola pantalla)
│   ├── constants/
│   │   ├── app_constants.dart    Nombre de la app e INTERRUPTORES (MediaPipe, modelo, demo)
│   │   └── ml_constants.dart     30 frames, 126 features, umbrales… (espejo de ml/src/config.py)
│   ├── di/
│   │   └── injection_container.dart   Crea y conecta TODAS las clases (get_it)
│   ├── error/
│   │   └── failures.dart         Tipos de error: CameraFailure, ModelFailure, TtsFailure…
│   ├── router/
│   │   ├── app_routes.dart       Nombres de las rutas ('/', '/home', '/recognition'…)
│   │   └── app_router.dart       Qué pantalla abre cada ruta y qué controller le inyecta
│   ├── services/
│   │   └── camera_service.dart   Único dueño del CameraController (abrir, cambiar, cerrar)
│   ├── theme/
│   │   ├── app_colors.dart       Temas de color (Azul / Verde), paletas y degradados
│   │   └── app_theme.dart        Tema oscuro de Material 3
│   └── utils/
│       └── result.dart           Result<T> = Success(valor) | Error(Failure)
│
├── shared/                       Piezas visuales reutilizables
│   ├── widgets/
│   │   ├── app_logo.dart         Logo con degradado
│   │   ├── glass_card.dart       Tarjeta translúcida con desenfoque
│   │   └── gradient_background.dart   Fondo con degradado y manchas de color
│   └── modals/
│       └── confirm_dialog.dart   Diálogo "¿Estás seguro?" genérico
│
└── features/                     Una carpeta por funcionalidad
    ├── splash/                   PANTALLA DE CARGA
    ├── home/                     MENÚ PRINCIPAL
    ├── recognition/              ★ TRADUCTOR (cámara + MediaPipe + LSTM)
    ├── tts/                      VOZ
    ├── dictionary/               DICCIONARIO DE SEÑAS
    ├── history/                  HISTORIAL DE FRASES
    └── settings/                 AJUSTES
```

### 4.3 `ml/` — Machine Learning

```
ml/
├── README.md                Guía rápida de entrenamiento
├── requirements.txt         mediapipe, tensorflow, opencv, numpy, scikit-learn
├── data/                    Dataset grabado: data/<seña>/<n>.npy  (cada uno 30 × 126)
├── models/                  Salidas: sign_lstm.keras, sign_lstm.tflite, labels.txt
└── src/
    ├── config.py            Lista de señas, 30 frames, 126 features, epochs, rutas
    ├── keypoints.py         MediaPipe en Python + normalización (idéntica a la de Dart)
    ├── collect_data.py      Graba el dataset con la webcam
    ├── train_lstm.py        Entrena la LSTM y muestra métricas
    ├── realtime_test.py     Prueba el modelo en vivo con la webcam del PC
    └── export_tflite.py     Convierte a .tflite y lo copia a app/assets/models/
```

---

## 5. La app Flutter en detalle

### 5.1 Arquitectura limpia (Clean Architecture)

Cada funcionalidad (`features/<nombre>/`) se divide en **tres capas**:

```
            ┌──────────────────────────────┐
            │        presentation          │  Pantallas, widgets, modales y controllers
            │  (Flutter, provider)         │
            └──────────────┬───────────────┘
                           │ usa
                           ▼
            ┌──────────────────────────────┐
            │           domain             │  Entidades, interfaces y casos de uso
            │  (Dart puro, sin paquetes)   │  ← el "corazón": no sabe nada de Flutter
            └──────────────▲───────────────┘
                           │ implementa
            ┌──────────────┴───────────────┐
            │            data              │  Modelos (DTO), datasources y repositorios
            │ (MediaPipe, TFLite, TTS, …)  │
            └──────────────────────────────┘
```

| Capa | Qué contiene | Regla |
|------|--------------|-------|
| **domain** | `entities/` (datos del negocio), `repositories/` (interfaces), `usecases/` (acciones), `services/` (lógica pura) | No importa Flutter ni paquetes externos. Se puede probar sin celular. |
| **data** | `models/` (convierten datos externos en entidades), `datasources/` (hablan con MediaPipe, TFLite, TTS, disco), `repositories/` (implementan las interfaces y convierten excepciones en `Failure`) | Es la única capa que conoce las librerías externas. |
| **presentation** | `controllers/` (estado con `ChangeNotifier`), `pages/`, `widgets/`, `modals/` | Solo llama a casos de uso; nunca toca MediaPipe ni TFLite directamente. |

**Ventaja:** para cambiar de "mano simulada" a "MediaPipe real", o de "sin modelo" a "LSTM
real", solo se cambia **una línea** en `injection_container.dart` (vía `app_constants.dart`).
Las pantallas no se enteran.

**Modelos vs. entidades:** `HandFrameModel extends HandFrame`. El *model* sabe leer el mapa que
llega de Kotlin (`fromMap`); el resto de la app solo trabaja con la *entidad* `HandFrame`.

**Manejo de errores:** las capas no se lanzan excepciones entre sí. Los repositorios devuelven
`Result<T>`, que es `Success(valor)` o `Error(Failure)`, y la UI decide qué mostrar.

### 5.2 Inyección de dependencias y estado

- `core/di/injection_container.dart` registra todo en `get_it` (`sl`):
  - **lazySingleton**: una sola instancia para toda la app (repositorios, TTS, ajustes, historial).
  - **factory**: una instancia nueva cada vez (`RecognizeSignUseCase`, que guarda su propio
    buffer de frames, y los controllers de pantalla).
- `provider` entrega los controllers a los widgets:
  - **Globales** (`SettingsController`, `HistoryController`): en `app.dart`, viven toda la app.
  - **Por pantalla** (`SplashController`, `RecognitionController`): se crean en `app_router.dart`
    al abrir la pantalla y se destruyen al salir, liberando la cámara y el detector.

### 5.3 Funcionalidades

#### `features/splash/` — Pantalla de carga
| Archivo | Qué hace |
|---------|----------|
| `presentation/controllers/splash_controller.dart` | Ejecuta la carga en pasos: **preferencias → voz → modelo LSTM → detector**, con progreso de 0 a 100 %. Si un paso falla, lo guarda como advertencia y la app sigue. Espera un mínimo de 2,2 s para que se vea la animación. |
| `presentation/pages/splash_page.dart` | Logo con animación elástica, nombre con degradado, barra de progreso y mensaje del paso actual. Al terminar, navega a `/home`. |

#### `features/home/` — Menú principal
| Archivo | Qué hace |
|---------|----------|
| `presentation/pages/home_page.dart` | Encabezado con logo, tarjeta grande **"Traducir en tiempo real"**, accesos a Diccionario e Historial (con el número de frases guardadas), botón de ajustes y aviso si aún no hay modelo entrenado. |
| `presentation/widgets/feature_tile.dart` | Tarjeta cuadrada con icono, título y subtítulo. |

#### `features/recognition/` — Traductor ★
**Dominio**
| Archivo | Qué hace |
|---------|----------|
| `domain/entities/hand_frame.dart` | `Landmark` (x, y, z), `HandLandmarks` (21 puntos + mano izquierda/derecha), `HandFrame` (las manos de un frame). |
| `domain/entities/sign_prediction.dart` | `SignPrediction` (etiqueta, confianza, `displayText` legible: `por_favor` → "Por favor") y `RecognitionStep` (predicción en vivo, seña aceptada y llenado del buffer). |
| `domain/repositories/hand_tracking_repository.dart` | Interfaz: `start()`, `stop()`, `frames` (stream de manos). |
| `domain/repositories/sign_classifier_repository.dart` | Interfaz: `load()`, `classify(secuencia)`, `labels`, `isLoaded`. |
| `domain/services/keypoint_normalizer.dart` | Convierte un `HandFrame` en **126 números** (resta la muñeca y escala). Es copia exacta de la versión de Python. |
| `domain/services/sequence_buffer.dart` | Cola de tamaño fijo con los **últimos 30 frames**. |
| `domain/services/prediction_smoother.dart` | Acepta una seña solo si sale **3 veces seguidas** sobre el umbral y no la repite hasta que cambie. |
| `domain/usecases/hand_tracking_usecases.dart` | `StartHandTracking`, `StopHandTracking`, `WatchHandFrames`. |
| `domain/usecases/load_sign_model_usecase.dart` | Carga el modelo y expone `isReady`. |
| `domain/usecases/recognize_sign_usecase.dart` | **El pipeline completo por frame**: normalizar → buffer → cada 5 frames LSTM → suavizar. Si no hay manos durante 10 frames, reinicia. |

**Datos**
| Archivo | Qué hace |
|---------|----------|
| `data/models/hand_frame_model.dart` | Lee el JSON que devuelve Kotlin y lo convierte en `HandFrame`. |
| `data/models/sign_prediction_model.dart` | Toma las probabilidades del modelo y elige la seña más probable. |
| `data/datasources/hand_landmarker_datasource.dart` | **`MediaPipeHandLandmarkerDataSource`**: envía cada imagen de la cámara a Kotlin por el canal `sena_voz/hand_landmarker`. Descarta frames si el anterior sigue en proceso, para no acumular retraso. **`MockHandLandmarkerDataSource`**: mano animada simulada a 30 fps (sin cámara). |
| `data/datasources/sign_classifier_datasource.dart` | **`TfliteSignClassifierDataSource`**: carga `sign_lstm.tflite` y lo ejecuta en un *isolate* aparte para no trabar la interfaz. **`NoModelSignClassifierDataSource`**: se usa mientras no hay modelo; no inventa resultados. **`MockSignClassifierDataSource`**: palabras falsas, solo para ver la interfaz. |
| `data/repositories/*_impl.dart` | Implementan las interfaces y convierten errores técnicos (`PlatformException`, etc.) en `Failure` con mensajes claros. |

**Presentación**
| Archivo | Qué hace |
|---------|----------|
| `presentation/controllers/recognition_controller.dart` | Estado de la pantalla: abre la cámara, inicia la detección, recibe cada frame, agrega palabras a la frase, habla automáticamente, pausa/reanuda, cambia de cámara, borra y guarda en el historial. |
| `presentation/pages/recognition_page.dart` | Cámara a pantalla completa, tarjeta superior con la predicción, botón de pausa y panel inferior con la traducción. |
| `presentation/widgets/camera_view.dart` | Vista de la cámara con los puntos de la mano **dentro del mismo recuadro**, para que coincidan exactamente aunque la imagen se recorte. |
| `presentation/widgets/hand_landmarks_painter.dart` | Dibuja las 21 articulaciones y sus conexiones (verde: mano derecha, naranja: izquierda). |
| `presentation/widgets/prediction_overlay.dart` | Anillo de llenado del buffer, seña detectada, barra y porcentaje de confianza. |
| `presentation/widgets/transcript_panel.dart` | Palabras como chips animados y botones **Borrar última, Limpiar, Guardar y Hablar**. |
| `presentation/modals/recognition_settings_sheet.dart` | Hoja inferior para ajustar la confianza mínima, la voz automática y los puntos de la mano. |

#### `features/tts/` — Voz
| Archivo | Qué hace |
|---------|----------|
| `domain/entities/tts_config.dart` | Idioma, velocidad, tono y volumen. |
| `domain/repositories/tts_repository.dart` | Interfaz: `initialize`, `configure`, `speak`, `stop`. |
| `domain/usecases/tts_usecases.dart` | `InitTts`, `ConfigureTts`, `SpeakText` (ignora texto vacío) y `StopSpeaking`. |
| `data/datasources/tts_datasource.dart` | Usa `flutter_tts`. Si el idioma elegido no existe en el teléfono, usa `es-ES`. |
| `data/repositories/tts_repository_impl.dart` | Convierte errores en `TtsFailure`. |

#### `features/dictionary/` — Diccionario
| Archivo | Qué hace |
|---------|----------|
| `domain/entities/sign_entry.dart` | Seña: etiqueta, título, categoría, descripción y pasos. |
| `data/datasources/dictionary_local_datasource.dart` | Catálogo de las 8 señas iniciales (hola, gracias, por favor, sí, no, ayuda, agua, te quiero). |
| `data/repositories/dictionary_repository_impl.dart` | Lista completa y búsqueda por nombre o categoría. |
| `presentation/pages/dictionary_page.dart` | Buscador y cuadrícula de señas. |
| `presentation/modals/sign_detail_sheet.dart` | Detalle de la seña: pasos, botón para escucharla y espacio para un video o GIF. |

#### `features/history/` — Historial
| Archivo | Qué hace |
|---------|----------|
| `domain/entities/translation_entry.dart` | Frase y fecha (con conversión a JSON). |
| `data/repositories/history_repository_impl.dart` | Guarda hasta 200 frases en `shared_preferences`. |
| `presentation/controllers/history_controller.dart` | Cargar, guardar, eliminar y vaciar. |
| `presentation/pages/history_page.dart` | Lista de frases: desliza para borrar, botón para reproducirla y "Borrar todo" con confirmación. |

#### `features/settings/` — Ajustes
| Archivo | Qué hace |
|---------|----------|
| `domain/entities/app_settings.dart` | Idioma, velocidad, tono, voz automática, mostrar puntos, confianza mínima y tema de color. |
| `data/repositories/settings_repository_impl.dart` | Lee y guarda los ajustes en `shared_preferences`. |
| `presentation/controllers/settings_controller.dart` | Cambia ajustes, los guarda y reconfigura la voz al instante. Tiene "Probar voz". |
| `presentation/pages/settings_page.dart` | Pantalla de ajustes por secciones: Apariencia (tema Azul o Verde), Voz, Reconocimiento y Acerca de. |

**Cambio de tema:** `AppColors` (en `core/theme/app_colors.dart`) lee la paleta activa. Al elegir un tema, `SettingsController` lo guarda, `app.dart` llama a `AppColors.apply()`, reconstruye el `ThemeData` y repinta todas las pantallas abiertas. Los ajustes se cargan en `main.dart` antes de dibujar, para que el splash ya salga con el tema elegido.

### 5.4 Rutas

| Ruta | Pantalla |
|------|----------|
| `/` | Pantalla de carga |
| `/home` | Menú principal (entra con transición de desvanecimiento) |
| `/recognition` | Traductor |
| `/dictionary` | Diccionario |
| `/history` | Historial |
| `/settings` | Ajustes |

---

## 6. El código nativo de Android (MediaPipe)

MediaPipe no tiene un paquete oficial para Flutter, así que la detección de manos se hace en
**Kotlin** y se comunica con Dart por un `MethodChannel` llamado `sena_voz/hand_landmarker`.

**Archivos**
- `android/app/src/main/kotlin/com/senavoz/sena_voz/HandLandmarkerChannel.kt`
- `android/app/src/main/kotlin/com/senavoz/sena_voz/MainActivity.kt` (registra el canal)
- `android/app/src/main/assets/hand_landmarker.task` (modelo de Google)
- `android/app/build.gradle.kts` → `implementation("com.google.mediapipe:tasks-vision:0.10.35")`

**Qué hace `HandLandmarkerChannel.kt` con cada imagen**
1. Recibe los planos Y, U y V de la cámara.
2. Los convierte a una imagen RGB (a la mitad de resolución si supera 640 px, sin perder precisión).
3. La **gira** según la orientación del sensor y la **espeja** si es la cámara frontal.
4. Ejecuta `HandLandmarker.detectForVideo()` (intenta GPU y, si no hay, usa CPU).
5. Devuelve las manos a Dart.

Todo se procesa en un **hilo aparte** para no congelar la interfaz.

**Contrato del canal**

| Método | Envía (Dart → Kotlin) | Responde (Kotlin → Dart) |
|--------|-----------------------|--------------------------|
| `init` | `{maxHands: 2, minConfidence: 0.6}` | `null` |
| `detect` | `{width, height, rotation, mirror, planes, rowStrides, pixelStrides}` | `{timestamp, hands: [{handedness: "Left"/"Right", score, landmarks: [x0,y0,z0, …, x20,y20,z20]}]}` |
| `close` | — | `null` |

---

## 7. El pipeline de Machine Learning (Python)

### 7.1 Señas configuradas
En `ml/src/config.py` → `ACTIONS`:
`hola`, `gracias`, `por_favor`, `si`, `no`, `ayuda`, `agua`, `te_quiero`.
Puedes agregar o quitar señas ahí; el número de salidas del modelo se ajusta solo.

### 7.2 Scripts

| Script | Qué hace |
|--------|----------|
| `collect_data.py` | Abre la webcam. Por cada seña te da una pausa para prepararte y luego graba **30 frames**. Repite 40 veces por seña y guarda cada secuencia como `data/<seña>/<n>.npy`. Con `--action hola` graba solo una seña. Si ya existen archivos, continúa la numeración. |
| `keypoints.py` | Configura MediaPipe Hands en Python y convierte cada frame en los 126 números. **Tiene que coincidir exactamente** con `keypoint_normalizer.dart`. |
| `train_lstm.py` | Carga el dataset, separa 15 % para prueba, aumenta los datos (ruido y escala), entrena y muestra *classification report* y matriz de confusión. Guarda `sign_lstm.keras` y `labels.txt`. |
| `realtime_test.py` | Prueba el modelo con la webcam del PC antes de pasarlo al celular. |
| `export_tflite.py` | Convierte a `.tflite` con batch fijo de 1 para que la LSTM use operaciones nativas de TFLite (sin Flex). Con `--copy-to-app` lo copia a `app/assets/models/`. Con `--fp16` lo hace más liviano. |

### 7.3 Arquitectura de la LSTM

```
Entrada  [30 frames × 126 features]
   │
LSTM(64, return_sequences=True) → Dropout(0.3)
   │
LSTM(128)                       → Dropout(0.3)
   │
Dense(64, relu)
   │
Dense(N señas, softmax)         → probabilidad de cada seña
```
Optimizador Adam (1e-3), *early stopping* (paciencia 25) y reducción automática del
*learning rate*. **No se usa capa `Masking`** porque impide convertir la LSTM a TFLite nativo.

---

## 8. Contrato de datos Python ⇄ Flutter

El modelo solo funciona si la app calcula **exactamente los mismos números** que se usaron
al entrenar. Detalle completo en [`docs/FEATURE_SPEC.md`](docs/FEATURE_SPEC.md).

- Entrada del modelo: `float32[1, 30, 126]` → salida `float32[1, N]`.
- Frame = `[mano izquierda (63) | mano derecha (63)]`; si falta una mano, van 63 ceros.
- Por cada mano: se **resta la muñeca** a los 21 puntos y se **divide** por el mayor valor
  absoluto de x/y.
- La imagen se procesa **espejada** (como un selfie) tanto al grabar como en el celular, para
  que "izquierda" y "derecha" coincidan.

| Constante | Python (`ml/src/config.py`) | Dart (`lib/core/constants/ml_constants.dart`) |
|-----------|-----------------------------|-----------------------------------------------|
| Frames por secuencia | `SEQUENCE_LENGTH = 30` | `sequenceLength = 30` |
| Features por frame | `NUM_FEATURES = 126` | `numFeatures = 126` |
| Etiquetas | `ACTIONS` → `labels.txt` | `assets/models/labels.txt` |

> ⚠️ Si cambias cualquiera de estos valores en un lado, cámbialo también en el otro.

---

## 9. Configuración (interruptores)

Archivo: `app/lib/core/constants/app_constants.dart`

| Interruptor | Valor actual | Efecto |
|-------------|--------------|--------|
| `useMediaPipe` | `true` | `true`: detecta tus manos reales con MediaPipe. `false`: mano animada simulada. |
| `hasTrainedModel` | `false` | Ponlo en `true` cuando `sign_lstm.tflite` esté en `assets/models/`. |
| `demoPredictions` | `false` | `true`: inventa palabras para ver la interfaz. **No reconoce nada.** |
| `defaultConfidenceThreshold` | `0.80` | Confianza mínima inicial (también se cambia desde Ajustes). |
| `defaultTtsLanguage` | `es-MX` | Idioma inicial de la voz. |

Otros parámetros del reconocimiento en `ml_constants.dart`: `inferenceStride = 5` (cada cuántos
frames se ejecuta el modelo) y `stabilityWindow = 3` (repeticiones necesarias para aceptar una seña).

---

## 10. Instalación y ejecución

### Requisitos
- Flutter SDK (Dart ≥ 3.13)
- Android SDK y un **celular Android 8.0+ (API 26)** con depuración USB
- **Java 17** (Java 21 o superior da errores con las herramientas de Android)

### Pasos
```bash
git clone https://github.com/AngelSky2/SICOM.git
cd SICOM/app

# Indicarle a Flutter que use Java 17 (solo la primera vez)
flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk

flutter pub get
adb devices          # tu celular debe aparecer como "device"
flutter run
```
La **primera compilación tarda bastante** (descarga NDK, Gradle y MediaPipe). Las siguientes
son mucho más rápidas. Con la app abierta: `r` recarga cambios de Dart, `R` reinicia la app y
`q` sale. **Si cambias código Kotlin, sal con `q` y vuelve a ejecutar `flutter run`.**

### Activar la depuración USB (ejemplo: Tecno / HiOS)
1. **Ajustes → Mi teléfono** → toca 7 veces **Número de compilación**.
2. **Ajustes → Sistema → Opciones de desarrollador** → activa **Depuración USB** (y
   **Instalar vía USB** si aparece).
3. Conecta el cable y acepta **"¿Permitir depuración USB?"**.

---

## 11. Entrenar el modelo LSTM

```bash
cd ml
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

python src/collect_data.py                 # 1. grabar (40 secuencias por seña)
python src/train_lstm.py                   # 2. entrenar
python src/realtime_test.py                # 3. probar en el PC (opcional)
python src/export_tflite.py --copy-to-app  # 4. exportar a la app
```
Después pon `hasTrainedModel = true` en `app_constants.dart` y ejecuta `flutter run`.

**Consejos para un buen modelo**
- Graba con distintas luces, fondos, ropa y distancias; si puedes, con varias personas.
- Empieza con 40 a 100 secuencias por seña.
- Agrega una clase `nada` (manos quietas o sin seña) para reducir los falsos positivos.
- Usa Python 3.10 o 3.11: MediaPipe y TensorFlow aún no soportan bien versiones más nuevas.

---

## 12. Solución de problemas

| Síntoma | Causa | Solución |
|---------|-------|----------|
| `No supported devices connected` | No hay celular ni emulador | Conecta el celular con depuración USB y revisa `adb devices`. |
| `adb devices` vacío o `no permissions` (Linux) | Faltan reglas USB | `sudo pacman -S android-udev` (Arch), reconecta el cable o prueba con otro. |
| `Error while executing process .../java-26.../jlink` | Java demasiado nuevo | `flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk` y `cd android && ./gradlew --stop`. |
| `Inconsistent JVM-target compatibility … (11) and (17)` | `tflite_flutter` mezcla Java 11 y Kotlin 17 | Ya resuelto en `android/gradle.properties` con `kotlin.jvm.target.validation.mode=warning`. |
| `Gradle build daemon disappeared unexpectedly` | Sin RAM (Linux mató el proceso) | Ya ajustado en `gradle.properties` (1,5 GB). Cierra el navegador y otros programas al compilar. |
| `WARNING: … Kotlin Gradle Plugin (KGP): flutter_tts` | Aviso del plugin | Se puede ignorar. |
| Muchos `I/flutter (xxxxx)` de otras apps | `flutter run` muestra los registros de todo el celular | Se pueden ignorar. |
| "Mano detectada · falta entrenar la LSTM" | No hay modelo entrenado | Sigue la [sección 11](#11-entrenar-el-modelo-lstm). |

---

## 13. ¿Hace falta un backend?

**No.** MediaPipe y una LSTM pequeña en TFLite funcionan en el celular a 30 fps. Hacerlo en el
dispositivo tiene ventajas claras: **sin latencia de red, funciona sin internet, es gratis y
protege la privacidad** (el video nunca sale del teléfono).

Un backend (por ejemplo, FastAPI) solo tendría sentido más adelante para:
- Modelos mucho más grandes (Transformers sobre video completo).
- Sincronizar el historial entre dispositivos.
- Recolectar datos de usuarios, siempre con su consentimiento, para mejorar el modelo.
- Actualizar el modelo sin publicar una versión nueva de la app.

Gracias a la arquitectura, bastaría con crear un `RemoteSignClassifierDataSource` que
implemente la misma interfaz, **sin tocar el dominio ni las pantallas**.

---

## 14. Hoja de ruta

- [x] Interfaz completa con pantalla de carga
- [x] Arquitectura limpia + inyección de dependencias
- [x] Texto a voz
- [x] MediaPipe nativo en Android y dibujo de puntos
- [x] Scripts de dataset, entrenamiento y exportación
- [ ] Grabar el dataset y entrenar la primera LSTM
- [ ] Clase `nada` para evitar falsos positivos
- [ ] Videos o GIFs de cada seña en el diccionario
- [ ] Lado nativo de MediaPipe para iOS
- [ ] Más señas y frases completas
