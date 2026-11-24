import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;

  static const _kLang = 'settings.ttsLanguage';
  static const _kRate = 'settings.speechRate';
  static const _kPitch = 'settings.pitch';
  static const _kAuto = 'settings.autoSpeak';
  static const _kLandmarks = 'settings.showLandmarks';
  static const _kThreshold = 'settings.confidenceThreshold';

  @override
  Future<AppSettings> load() async {
    const d = AppSettings();
    return AppSettings(
      ttsLanguage: _prefs.getString(_kLang) ?? d.ttsLanguage,
      speechRate: _prefs.getDouble(_kRate) ?? d.speechRate,
      pitch: _prefs.getDouble(_kPitch) ?? d.pitch,
      autoSpeak: _prefs.getBool(_kAuto) ?? d.autoSpeak,
      showLandmarks: _prefs.getBool(_kLandmarks) ?? d.showLandmarks,
      confidenceThreshold: _prefs.getDouble(_kThreshold) ?? d.confidenceThreshold,
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    await Future.wait([
      _prefs.setString(_kLang, s.ttsLanguage),
      _prefs.setDouble(_kRate, s.speechRate),
      _prefs.setDouble(_kPitch, s.pitch),
      _prefs.setBool(_kAuto, s.autoSpeak),
      _prefs.setBool(_kLandmarks, s.showLandmarks),
      _prefs.setDouble(_kThreshold, s.confidenceThreshold),
    ]);
  }
}
