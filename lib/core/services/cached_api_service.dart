import 'package:shared_preferences/shared_preferences.dart';

class CachedApiService {
  const CachedApiService(this._prefs);

  final SharedPreferences _prefs;

  static const Duration defaultCacheDuration = Duration(hours: 6);

  /// Invalid persisted payloads are cache misses, so retry can reach the server.
  Future<T?> getParsed<T>(String key, T Function(String) parse) async {
    final body = await getCached(key);
    if (body == null) return null;
    try {
      return parse(body);
    } on FormatException {
      await _remove(key);
    } on TypeError {
      await _remove(key);
    }
    return null;
  }

  Future<void> _remove(String key) async {
    await _prefs.remove(key);
    await _prefs.remove(_timestampKey(key));
  }

  Future<String?> getCached(
    String key, {
    Duration duration = defaultCacheDuration,
  }) async {
    final timestamp = _prefs.getInt(_timestampKey(key));
    if (timestamp == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cachedAt) > duration) {
      await _remove(key);
      return null;
    }

    return _prefs.getString(key);
  }

  Future<void> cache(String key, String data) async {
    await _prefs.setString(key, data);
    await _prefs.setInt(
      _timestampKey(key),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  String _timestampKey(String key) => '${key}_timestamp';
}
