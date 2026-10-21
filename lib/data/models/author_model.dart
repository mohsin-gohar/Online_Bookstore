import 'package:characters/characters.dart';

import 'model_helpers.dart';

/// An author of one or more books in the catalogue.
///
/// Mirrors the `GET /authors` payload:
/// `id, name, bio, photo_url, book_count, created_at`.
class AuthorModel {
  const AuthorModel({
    required this.id,
    required this.name,
    this.bio = '',
    this.photoUrl = '',
    this.bookCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String bio;
  final String photoUrl;

  /// How many books in the catalogue belong to this author.
  final int bookCount;

  final DateTime? createdAt;

  /// The author's initials, used for the avatar fallback.
  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  // ── Serialization ─────────────────────────

  factory AuthorModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return AuthorModel(
      id: parseString(m['id'] ?? id),
      name: parseString(m['name']),
      bio: parseString(m['bio']),
      photoUrl: parseString(m['photoUrl']),
      bookCount: parseInt(m['bookCount']),
      createdAt: parseDate(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bio': bio,
    'photo_url': photoUrl,
    'book_count': bookCount,
    'created_at': createdAt?.toIso8601String(),
  };

  AuthorModel copyWith({
    String? id,
    String? name,
    String? bio,
    String? photoUrl,
    int? bookCount,
    DateTime? createdAt,
  }) {
    return AuthorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      bookCount: bookCount ?? this.bookCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is AuthorModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
