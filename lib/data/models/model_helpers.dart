/// Shared parsing helpers used by every model's `fromMap`.
///
/// The API returns dates as ISO-8601 strings, but a value may also arrive as a
/// ISO-8601 `String` (e.g. from `toMap()` round-trips) or a `DateTime` (from
/// tests). These helpers normalise all three so each model stays declarative.
library;

import 'package:characters/characters.dart';

/// Parses [value] into a [DateTime], or returns null when it can't.
///
/// Accepts a `DateTime`, an ISO-8601 `String`, or a `Timestamp`
/// (which exposes `toDate()`). Anything else yields null.
DateTime? parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  try {
    // Timestamp-like value — accessed dynamically so no timestamp type
    // has to be imported into pure model code, which keeps this file
    // testable.
    // ignore: avoid_dynamic_calls
    final dynamic d = (value as dynamic).toDate();
    if (d is DateTime) return d;
  } catch (_) {
    // Not a Timestamp — fall through.
  }
  return null;
}

/// Parses a list of maps (from the API or a JSON array) into a typed list
/// of [T].
///
/// Non-list values yield an empty list; non-map entries are skipped. Each
/// entry's keys are normalised from `snake_case` to `camelCase` first, so a
/// Laravel payload parses with the same [fromMap] as a local one.
List<T> parseList<T>(Object? raw, T Function(Map<String, dynamic>) fromMap) {
  if (raw is! List) return const [];
  final out = <T>[];
  for (final item in raw) {
    if (item is Map) {
      out.add(fromMap(normalizeKeys(item.cast<String, dynamic>())));
    }
  }
  return out;
}

/// Reads [key] from [map] as a `double`, accepting `int`, `double`, `num`, or a
/// numeric `String`. Falls back to [fallback] for anything else.
double parseDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Reads [value] as an `int`, accepting `num` or a numeric `String`.
int parseInt(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Reads [value] as a trimmed `String` (empty when null).
String parseString(Object? value) => (value ?? '').toString().trim();

/// Reads [value] as a `bool`, accepting common string forms.
bool parseBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) {
    final v = value.toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  if (value is num) return value != 0;
  return fallback;
}

/// Reads [value] as a `List<String>`, dropping non-string entries.
List<String> parseStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

/// Converts a JSON map's **top-level** keys from `snake_case` to `camelCase`.
///
/// Laravel serialises Eloquent models as `snake_case` (`cover_image`,
/// `created_at`, `is_blocked`, …) while the app's models are written in
/// `camelCase`. Normalising here keeps every `fromMap` implementation free of
/// per-field key juggling.
///
/// Keys that are already camelCase are returned untouched, so a payload that
/// mixes both conventions (or an already-normalised payload) still parses.
Map<String, dynamic> normalizeKeys(Map<String, dynamic> raw) {
  final Map<String, dynamic> out = <String, dynamic>{};
  raw.forEach((key, value) {
    out[_toCamelCase(key)] = value;
  });
  return out;
}

/// `cover_image` → `coverImage`; `id` → `id`.
String _toCamelCase(String key) {
  if (!key.contains('_')) return key;
  final List<String> parts = key.split('_').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return key;
  final StringBuffer buffer = StringBuffer(parts.first);
  for (int i = 1; i < parts.length; i++) {
    final String part = parts[i];
    buffer
      ..write(part.characters.first.toUpperCase())
      ..write(part.characters.skip(1).toString());
  }
  return buffer.toString();
}

/// Normalises [raw] when it is a JSON map, otherwise returns an empty map.
Map<String, dynamic> normalizeMap(Object? raw) {
  if (raw is! Map) return <String, dynamic>{};
  return normalizeKeys(raw.cast<String, dynamic>());
}

/// Reads a nested list of maps, normalising each entry's keys.
List<Map<String, dynamic>> normalizeMapList(Object? raw) {
  if (raw is! List) return const <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final Object? item in raw) {
    if (item is Map) out.add(normalizeKeys(item.cast<String, dynamic>()));
  }
  return out;
}
