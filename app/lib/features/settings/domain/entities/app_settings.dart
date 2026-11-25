import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tts/domain/entities/tts_config.dart';

class AppSettings {
  const AppSettings({
    this.ttsLanguage = AppConstants.defaultTtsLanguage,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.autoSpeak = true,
    this.showLandmarks = true,
    this.confidenceThreshold = AppConstants.defaultConfidenceThreshold,
    this.themeColor = AppThemeColor.blue,
  });

  final String ttsLanguage;
  final double speechRate;
  final double pitch;
  final bool autoSpeak;
  final bool showLandmarks;
  final double confidenceThreshold;
  final AppThemeColor themeColor;

  TtsConfig get ttsConfig => TtsConfig(language: ttsLanguage, rate: speechRate, pitch: pitch);

  AppSettings copyWith({
    String? ttsLanguage,
    double? speechRate,
    double? pitch,
    bool? autoSpeak,
    bool? showLandmarks,
    double? confidenceThreshold,
    AppThemeColor? themeColor,
  }) {
    return AppSettings(
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      autoSpeak: autoSpeak ?? this.autoSpeak,
      showLandmarks: showLandmarks ?? this.showLandmarks,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}
