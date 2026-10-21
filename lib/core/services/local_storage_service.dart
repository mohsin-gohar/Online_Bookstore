import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for simple key/value persistence.
///
/// Used for things that must survive app restarts but don't belong in
/// the onboarding-completed flag, the chosen theme mode, and a cache
/// of the last signed-in user id.
class LocalStorageService {
  LocalStorageService._(this._prefs);

  final SharedPreferences _prefs;

  // ── Keys ───────────────────────────────
  static const String _kOnboardingDone = 'onboarding_done';
  static const String _kThemeMode = 'theme_mode';
  static const String _kLastUserId = 'last_user_id';
  static const String _kRecentSearches = 'recent_searches';

  /// Creates (or returns the cached) instance. Call once in `main()`.
  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService._(prefs);
  }

  // ── Onboarding ─────────────────────────
  bool get isOnboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_kOnboardingDone, value);

  // ── Theme mode ─────────────────────────
  /// Stored as a string: 'system' | 'light' | 'dark'.
  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';

  Future<void> setThemeMode(String value) =>
      _prefs.setString(_kThemeMode, value);

  // ── Last user ──────────────────────────
  String? get lastUserId => _prefs.getString(_kLastUserId);

  Future<void> setLastUserId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kLastUserId);
    } else {
      await _prefs.setString(_kLastUserId, id);
    }
  }

  // ── Recent searches ────────────────────
  List<String> get recentSearches {
    final raw = _prefs.getStringList(_kRecentSearches);
    return raw ?? const <String>[];
  }

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final list = [...recentSearches]..removeWhere((e) => e == trimmed);
    list.insert(0, trimmed);
    // Keep only the 10 most recent searches.
    await _prefs.setStringList(
      _kRecentSearches,
      list.take(10).toList(growable: false),
    );
  }

  Future<void> clearRecentSearches() => _prefs.remove(_kRecentSearches);

  // ── Debug helper ───────────────────────
  /// Dumps all stored values (useful while testing).
  Map<String, Object?> dump() {
    final map = <String, Object?>{};
    for (final key in _prefs.getKeys()) {
      map[key] = _prefs.get(key);
    }
    return map;
  }

  /// Pretty JSON of [dump] — handy to print in a dev screen.
  String dumpJson() => const JsonEncoder.withIndent('  ').convert(dump());
}
