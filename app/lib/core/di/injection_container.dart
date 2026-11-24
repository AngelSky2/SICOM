import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/dictionary/data/datasources/dictionary_local_datasource.dart';
import '../../features/dictionary/data/repositories/dictionary_repository_impl.dart';
import '../../features/dictionary/domain/repositories/dictionary_repository.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/presentation/controllers/history_controller.dart';
import '../../features/recognition/data/datasources/hand_landmarker_datasource.dart';
import '../../features/recognition/data/datasources/sign_classifier_datasource.dart';
import '../../features/recognition/data/repositories/hand_tracking_repository_impl.dart';
import '../../features/recognition/data/repositories/sign_classifier_repository_impl.dart';
import '../../features/recognition/domain/repositories/hand_tracking_repository.dart';
import '../../features/recognition/domain/repositories/sign_classifier_repository.dart';
import '../../features/recognition/domain/usecases/hand_tracking_usecases.dart';
import '../../features/recognition/domain/usecases/load_sign_model_usecase.dart';
import '../../features/recognition/domain/usecases/recognize_sign_usecase.dart';
import '../../features/recognition/presentation/controllers/recognition_controller.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';
import '../../features/splash/presentation/controllers/splash_controller.dart';
import '../../features/tts/data/datasources/tts_datasource.dart';
import '../../features/tts/data/repositories/tts_repository_impl.dart';
import '../../features/tts/domain/repositories/tts_repository.dart';
import '../../features/tts/domain/usecases/tts_usecases.dart';
import '../constants/app_constants.dart';
import '../services/camera_service.dart';

/// Service locator global. Es el ÚNICO lugar que conoce las implementaciones
/// concretas; el resto de la app depende de interfaces.
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---------- Externos / core ----------
  sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
  sl.registerLazySingleton<CameraService>(CameraService.new);

  // ---------- TTS ----------
  sl.registerLazySingleton<TtsDataSource>(FlutterTtsDataSource.new);
  sl.registerLazySingleton<TtsRepository>(() => TtsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => InitTtsUseCase(sl()));
  sl.registerLazySingleton(() => ConfigureTtsUseCase(sl()));
  sl.registerLazySingleton(() => SpeakTextUseCase(sl()));
  sl.registerLazySingleton(() => StopSpeakingUseCase(sl()));

  // ---------- Reconocimiento (MediaPipe + LSTM) ----------
  sl.registerLazySingleton<HandLandmarkerDataSource>(
    () => AppConstants.useMediaPipe
        ? MediaPipeHandLandmarkerDataSource(sl())
        : MockHandLandmarkerDataSource(),
  );
  sl.registerLazySingleton<SignClassifierDataSource>(
    () => AppConstants.hasTrainedModel
        ? TfliteSignClassifierDataSource()
        : AppConstants.demoPredictions
            ? MockSignClassifierDataSource()
            : NoModelSignClassifierDataSource(),
  );
  sl.registerLazySingleton<HandTrackingRepository>(() => HandTrackingRepositoryImpl(sl()));
  sl.registerLazySingleton<SignClassifierRepository>(() => SignClassifierRepositoryImpl(sl()));
  sl.registerLazySingleton(() => StartHandTrackingUseCase(sl()));
  sl.registerLazySingleton(() => StopHandTrackingUseCase(sl()));
  sl.registerLazySingleton(() => WatchHandFramesUseCase(sl()));
  sl.registerLazySingleton(() => LoadSignModelUseCase(sl()));
  sl.registerFactory(() => RecognizeSignUseCase(sl())); // stateful → factory

  // ---------- Ajustes / Historial / Diccionario ----------
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()));
  sl.registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl(sl()));
  sl.registerLazySingleton(() => const DictionaryLocalDataSource());
  sl.registerLazySingleton<DictionaryRepository>(() => DictionaryRepositoryImpl(sl()));

  // ---------- Controllers (presentación) ----------
  sl.registerLazySingleton(() => SettingsController(sl(), sl(), sl()));
  sl.registerLazySingleton(() => HistoryController(sl()));
  sl.registerFactory(() => SplashController(
        settings: sl(),
        history: sl(),
        initTts: sl(),
        loadModel: sl(),
      ));
  sl.registerFactory(() => RecognitionController(
        camera: sl(),
        startTracking: sl(),
        stopTracking: sl(),
        watchFrames: sl(),
        recognize: sl(),
        model: sl(),
        speak: sl(),
        stopSpeaking: sl(),
        settings: sl(),
        history: sl(),
      ));
}
