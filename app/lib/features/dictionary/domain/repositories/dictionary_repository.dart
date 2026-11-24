import '../entities/sign_entry.dart';

abstract interface class DictionaryRepository {
  List<SignEntry> getAll();
  List<SignEntry> search(String query);
}
