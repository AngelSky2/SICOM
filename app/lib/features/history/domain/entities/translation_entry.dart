class TranslationEntry {
  const TranslationEntry({required this.text, required this.createdAt});

  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {'text': text, 'createdAt': createdAt.toIso8601String()};

  factory TranslationEntry.fromJson(Map<String, dynamic> json) => TranslationEntry(
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
