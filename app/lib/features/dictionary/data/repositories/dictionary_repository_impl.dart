import '../../domain/entities/sign_entry.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../datasources/dictionary_local_datasource.dart';

class DictionaryRepositoryImpl implements DictionaryRepository {
  DictionaryRepositoryImpl(this._local);
  final DictionaryLocalDataSource _local;

  @override
  List<SignEntry> getAll() => _local.getAll();

  @override
  List<SignEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return getAll()
        .where((s) => s.title.toLowerCase().contains(q) || s.category.toLowerCase().contains(q))
        .toList();
  }
}
