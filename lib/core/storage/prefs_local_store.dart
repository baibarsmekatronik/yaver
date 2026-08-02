import 'package:shared_preferences/shared_preferences.dart';

import 'local_store.dart';

/// `shared_preferences` tabanlı yerel depo.
///
/// Uygulama açılışında bir kez hazırlanır; okuma senkron olduğu için
/// arayüz veriyi beklemeden çizebilir (saha koşulunda hızlı açılış).
class PrefsLocalStore implements LocalStore {
  final SharedPreferences _prefs;

  PrefsLocalStore(this._prefs);

  static Future<PrefsLocalStore> open() async =>
      PrefsLocalStore(await SharedPreferences.getInstance());

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);
}
