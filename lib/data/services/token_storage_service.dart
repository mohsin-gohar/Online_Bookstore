import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the Laravel API token in the platform keystore.
///
/// Uses `flutter_secure_storage` (Android Keystore / iOS Keychain / Windows
/// Credential Locker) so the bearer token is never written to plain
/// `SharedPreferences` and never appears in a crash log.
///
/// Every keystore call is wrapped in a timeout. A wedged keystore must never
/// freeze the splash screen: when the call does not answer in time the
/// service falls back to an in-memory map, so the app keeps working (the user
/// is treated as signed out until the token can be read).
class TokenStorageService {
  TokenStorageService({
    FlutterSecureStorage? storage,
    this.timeout = const Duration(seconds: 2),
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _usePlugin = true;

  /// A store that never touches the platform keystore.
  ///
  /// Used by the test suite (where no keystore exists) and as the automatic
  /// fallback when the plugin is unavailable.
  TokenStorageService.inMemory()
    : _storage = null,
      timeout = const Duration(seconds: 2),
      _usePlugin = false;

  final FlutterSecureStorage? _storage;
  final Duration timeout;
  final bool _usePlugin;

  /// In-memory fallback used when the platform keystore is not available.
  final Map<String, String> _fallback = <String, String>{};

  static const String _tokenKey = 'book_store_api_token';

  /// Reads the stored bearer token, or null when there is none.
  Future<String?> readToken() async {
    if (!_usePlugin) return _fallback[_tokenKey];
    try {
      final String? value = await _storage!
          .read(key: _tokenKey)
          .timeout(timeout);
      return value ?? _fallback[_tokenKey];
    } catch (_) {
      return _fallback[_tokenKey];
    }
  }

  /// Persists (or replaces) the bearer token.
  Future<void> writeToken(String token) async {
    _fallback[_tokenKey] = token;
    if (!_usePlugin) return;
    try {
      await _storage!.write(key: _tokenKey, value: token).timeout(timeout);
    } catch (_) {
      // The in-memory copy above is the fallback.
    }
  }

  /// Removes the stored token. Safe to call when no token exists.
  Future<void> clear() async {
    _fallback.remove(_tokenKey);
    if (!_usePlugin) return;
    try {
      await _storage!.delete(key: _tokenKey).timeout(timeout);
    } catch (_) {
      // Ignore — the in-memory copy is already gone.
    }
  }
}
