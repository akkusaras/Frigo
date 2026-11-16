import 'package:shared_preferences/shared_preferences.dart';

/// A tiny synchronous key-value abstraction the repositories persist
/// through. Hiding `shared_preferences` behind this lets every repository
/// stay fully synchronous (matching the original in-memory contracts)
/// while tests fall back to a throwaway in-memory store that needs no
/// platform setup at all.
abstract interface class LocalStore {
  String? getString(String key);
  void setString(String key, String value);
  void remove(String key);
}

/// Default store: lives only for the lifetime of the `ProviderContainer`
/// that created it. Used by every test unless a real device is involved,
/// so unit and widget tests never need to touch `shared_preferences`.
class InMemoryLocalStore implements LocalStore {
  final Map<String, String> _data = {};

  @override
  String? getString(String key) => _data[key];

  @override
  void setString(String key, String value) => _data[key] = value;

  @override
  void remove(String key) => _data.remove(key);
}

/// Backed by a loaded [SharedPreferences] instance so data survives app
/// restarts. Writes are fire-and-forget: `shared_preferences` updates its
/// in-memory cache synchronously and flushes to disk in the background, so
/// callers never need to await a save to keep the UI responsive.
class SharedPreferencesLocalStore implements LocalStore {
  SharedPreferencesLocalStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  void setString(String key, String value) {
    // ignore: discarded_futures
    _prefs.setString(key, value);
  }

  @override
  void remove(String key) {
    // ignore: discarded_futures
    _prefs.remove(key);
  }
}
