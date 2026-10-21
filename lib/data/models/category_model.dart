import 'model_helpers.dart';

/// A book category.
///
/// Mirrors `categories/{categoryId}`:
/// `name, image, description, createdAt`.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.image = '',
    this.description = '',
    this.createdAt,
    this.bookCount = 0,
  });

  final String id;
  final String name;
  final String image;
  final String description;
  final DateTime? createdAt;

  /// Denormalised count of books in this category (optional, for admin lists).
  final int bookCount;

  // ── Serialization ─────────────────────────

  factory CategoryModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return CategoryModel(
      id: parseString(m['id'] ?? id),
      name: parseString(m['name']),
      image: parseString(m['image']),
      description: parseString(m['description']),
      createdAt: parseDate(m['createdAt']),
      bookCount: parseInt(m['bookCount']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'image': image,
    'description': description,
    'created_at': createdAt?.toIso8601String(),
    'book_count': bookCount,
  };

  /// API write payload (id is the path segment, not a field).
  Map<String, dynamic> toApi() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
    DateTime? createdAt,
    int? bookCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      bookCount: bookCount ?? this.bookCount,
    );
  }

  @override
  bool operator ==(Object other) => other is CategoryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
