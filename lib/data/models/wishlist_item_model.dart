import 'model_helpers.dart';

/// A book saved to a user's wishlist.
///
/// Embedded in `wishlists/{userId}.items[]` as
/// `{bookId, title, price, coverImage, addedAt}`.
class WishlistItemModel {
  const WishlistItemModel({
    required this.bookId,
    required this.title,
    required this.price,
    this.coverImage = '',
    this.addedAt,
  });

  final String bookId;
  final String title;
  final double price;
  final String coverImage;
  final DateTime? addedAt;

  // ── Serialization ─────────────────────────

  factory WishlistItemModel.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return WishlistItemModel(
      bookId: parseString(m['bookId']),
      title: parseString(m['title']),
      price: parseDouble(m['price']),
      coverImage: parseString(m['coverImage']),
      addedAt: parseDate(m['addedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'book_id': bookId,
    'title': title,
    'price': price,
    'cover_image': coverImage,
    'added_at': (addedAt ?? DateTime.now()).toIso8601String(),
  };

  WishlistItemModel copyWith({
    String? bookId,
    String? title,
    double? price,
    String? coverImage,
    DateTime? addedAt,
  }) {
    return WishlistItemModel(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      price: price ?? this.price,
      coverImage: coverImage ?? this.coverImage,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WishlistItemModel && other.bookId == bookId;

  @override
  int get hashCode => bookId.hashCode;
}
