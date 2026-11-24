import 'package:flutter/foundation.dart';

import '../../domain/entities/translation_entry.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryController extends ChangeNotifier {
  HistoryController(this._repo);
  final HistoryRepository _repo;

  List<TranslationEntry> _entries = const [];
  List<TranslationEntry> get entries => _entries;

  Future<void> load() async {
    _entries = await _repo.getAll();
    notifyListeners();
  }

  Future<void> save(String text) async {
    if (text.trim().isEmpty) return;
    await _repo.add(TranslationEntry(text: text.trim(), createdAt: DateTime.now()));
    await load();
  }

  Future<void> remove(TranslationEntry entry) async {
    await _repo.remove(entry);
    await load();
  }

  Future<void> clear() async {
    await _repo.clear();
    await load();
  }
}
