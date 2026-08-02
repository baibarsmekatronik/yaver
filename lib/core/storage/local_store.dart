/// Basit anahtar–değer yerel deposu.
///
/// Uygulama katmanı doğrudan `shared_preferences`'a bağlanmasın diye
/// araya bu arayüz konuldu: ileride drift/sqflite'a veya Supabase yerel
/// önbelleğine geçilirken yalnızca bu arayüzün uygulaması değişir.
abstract interface class LocalStore {
  /// Anahtara karşılık gelen ham JSON metnini döndürür; yoksa null.
  String? read(String key);

  /// Anahtara ham JSON metnini yazar.
  Future<void> write(String key, String value);

  /// Anahtarı siler.
  Future<void> delete(String key);
}

/// Testler ve önizleme için bellekte tutan uygulama.
class InMemoryLocalStore implements LocalStore {
  final Map<String, String> _data;

  InMemoryLocalStore([Map<String, String>? seed]) : _data = {...?seed};

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}
