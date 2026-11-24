import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/translation_entry.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'history.entries';
  static const _maxEntries = 200;

  @override
  Future<List<TranslationEntry>> getAll() async {
    final raw = _prefs.getStringList(_key) ?? const [];
    return raw
        .map((e) => TranslationEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<TranslationEntry> entries) =>
      _prefs.setStringList(_key, entries.map((e) => jsonEncode(e.toJson())).toList());

  @override
  Future<void> add(TranslationEntry entry) async {
    final all = [entry, ...await getAll()];
    await _saveAll(all.take(_maxEntries).toList());
  }

  @override
  Future<void> remove(TranslationEntry entry) async {
    final all = await getAll();
    all.removeWhere((e) => e.createdAt == entry.createdAt && e.text == entry.text);
    await _saveAll(all);
  }

  @override
  Future<void> clear() => _prefs.remove(_key);
}
