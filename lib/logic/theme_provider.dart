import 'package:flutter/material.dart';

import '../core/services/local_storage_service.dart';

/// Owns the app-wide [ThemeMode] and persists it via [LocalStorageService].
///
/// Consumers (e.g. the root `MaterialApp.router` and the profile screen's
/// dark-mode switch) listen to this via `context.watch<ThemeProvider>()`.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._storage) {
    _load();
  }

  final LocalStorageService _storage;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Reads the persisted mode on startup and notifies listeners.
  void _load() {
    _themeMode = _fromString(_storage.themeMode);
    notifyListeners();
  }

  /// Sets and persists the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.setThemeMode(_toString(mode));
  }

  /// Toggles between light and dark (ignores system).
  Future<void> toggleDarkMode(bool enabled) =>
      setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);

  // ── Serialization ──────────────────────
  static ThemeMode _fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
