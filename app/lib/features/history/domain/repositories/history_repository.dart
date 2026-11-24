import '../entities/translation_entry.dart';

abstract interface class HistoryRepository {
  Future<List<TranslationEntry>> getAll();
  Future<void> add(TranslationEntry entry);
  Future<void> remove(TranslationEntry entry);
  Future<void> clear();
}
