class SignEntry {
  const SignEntry({
    required this.label,
    required this.title,
    required this.emoji,
    required this.category,
    required this.description,
    required this.steps,
  });

  /// Debe coincidir con una etiqueta del modelo (`labels.txt`).
  final String label;
  final String title;
  final String emoji;
  final String category;
  final String description;
  final List<String> steps;
}
