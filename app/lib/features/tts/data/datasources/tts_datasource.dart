import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/entities/tts_config.dart';

abstract interface class TtsDataSource {
  Future<void> initialize(TtsConfig config);
  Future<void> configure(TtsConfig config);
  Future<void> speak(String text);
  Future<void> stop();
}

/// Usa el motor TTS nativo del teléfono (gratis, offline en la mayoría de equipos).
class FlutterTtsDataSource implements TtsDataSource {
  FlutterTtsDataSource([FlutterTts? tts]) : _tts = tts ?? FlutterTts();
  final FlutterTts _tts;

  @override
  Future<void> initialize(TtsConfig config) async {
    await _tts.awaitSpeakCompletion(false);
    await configure(config);
  }

  @override
  Future<void> configure(TtsConfig config) async {
    final available = await _tts.isLanguageAvailable(config.language);
    await _tts.setLanguage(available == true ? config.language : 'es-ES');
    await _tts.setSpeechRate(config.rate);
    await _tts.setPitch(config.pitch);
    await _tts.setVolume(config.volume);
  }

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();
}
