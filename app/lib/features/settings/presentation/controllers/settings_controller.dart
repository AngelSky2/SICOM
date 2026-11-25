import 'package:flutter/foundation.dart';

import '../../../tts/domain/usecases/tts_usecases.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Estado global de ajustes. Persiste en disco y re-configura el TTS al cambiar.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repo, this._configureTts, this._speak);

  final SettingsRepository _repo;
  final ConfigureTtsUseCase _configureTts;
  final SpeakTextUseCase _speak;

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  Future<void> load() async {
    _settings = await _repo.load();
    notifyListeners();
  }

  Future<void> update(AppSettings Function(AppSettings s) change) async {
    final previous = _settings;
    _settings = change(_settings);
    notifyListeners();
    await _repo.save(_settings);

    final ttsChanged = previous.ttsLanguage != _settings.ttsLanguage ||
        previous.speechRate != _settings.speechRate ||
        previous.pitch != _settings.pitch;
    if (ttsChanged) await _configureTts(_settings.ttsConfig);
  }

  Future<void> testVoice() => _speak('Hola, esta es la voz de SICOM');
}
