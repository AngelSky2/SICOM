class TtsConfig {
  const TtsConfig({
    required this.language,
    this.rate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
  });

  final String language;
  final double rate; // 0.0 - 1.0
  final double pitch; // 0.5 - 2.0
  final double volume; // 0.0 - 1.0
}
