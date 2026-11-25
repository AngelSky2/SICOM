import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../history/presentation/controllers/history_controller.dart';
import '../../../recognition/domain/usecases/load_sign_model_usecase.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../tts/domain/usecases/tts_usecases.dart';

enum SplashStatus { loading, ready }

/// Orquesta la carga inicial mostrando el progreso en la pantalla de carga.
/// Los errores no son fatales: se registran como advertencias y la app sigue.
class SplashController extends ChangeNotifier {
  SplashController({
    required SettingsController settings,
    required HistoryController history,
    required InitTtsUseCase initTts,
    required LoadSignModelUseCase loadModel,
  })  : _settings = settings,
        _history = history,
        _initTts = initTts,
        _loadModel = loadModel;

  final SettingsController _settings;
  final HistoryController _history;
  final InitTtsUseCase _initTts;
  final LoadSignModelUseCase _loadModel;

  SplashStatus _status = SplashStatus.loading;
  double _progress = 0;
  String _message = 'Iniciando…';
  final List<String> _warnings = [];
  bool _started = false;

  SplashStatus get status => _status;
  double get progress => _progress;
  String get message => _message;
  List<String> get warnings => List.unmodifiable(_warnings);

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final stopwatch = Stopwatch()..start();

    final steps = <(String, Future<void> Function())>[
      ('Cargando preferencias…', () async {
        await _settings.load();
        await _history.load();
      }),
      ('Preparando la voz…', () async {
        final r = await _initTts(_settings.settings.ttsConfig);
        r.fold((f) => _warnings.add(f.message), (_) {});
      }),
      (
        'Cargando modelo de reconocimiento…',
        () async {
          final r = await _loadModel();
          r.fold((f) => _warnings.add(f.message), (_) {});
        }
      ),
      ('Preparando detector de manos…', () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }),
    ];

    for (var i = 0; i < steps.length; i++) {
      final (label, action) = steps[i];
      _message = label;
      notifyListeners();
      try {
        await action();
      } catch (e) {
        _warnings.add(e.toString());
      }
      _progress = (i + 1) / steps.length;
      notifyListeners();
    }

    final remaining = AppConstants.splashMinDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);

    _message = '¡Listo!';
    _status = SplashStatus.ready;
    notifyListeners();
  }
}
