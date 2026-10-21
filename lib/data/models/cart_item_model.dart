import 'model_helpers.dart';

/// A single line item inside a user's cart.
///
/// Embedded in `carts/{userId}.items[]` as
/// `{bookId, title, price, qty, coverImage}`.
class CartItemModel {
  const CartItemModel({
    required this.bookId,
    required this.title,
    required this.price,
    required this.qty,
    this.coverImage = '',
  });

  final String bookId;
  final String title;

  /// Unit price captured at add-to-cart time (so price changes don't silently
  /// alter an existing cart without the user's knowledge).
  final double price;

  final int qty;
  final String coverImage;

  /// Line total for this item.
  double get lineTotal => price * qty;

  // ── Serialization ─────────────────────────

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return CartItemModel(
      bookId: parseString(m['bookId']),
      title: parseString(m['title']),
      price: parseDouble(m['price']),
      qty: parseInt(m['qty'], fallback: 1),
      coverImage: parseString(m['coverImage']),
    );
  }

  Map<String, dynamic> toMap() => {
    'book_id': bookId,
    'title': title,
    'price': price,
    'qty': qty,
    'cover_image': coverImage,
  };

  CartItemModel copyWith({
    String? bookId,
    String? title,
    double? price,
    int? qty,
    String? coverImage,
  }) {
    return CartItemModel(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      price: price ?? this.price,
      qty: qty ?? this.qty,
      coverImage: coverImage ?? this.coverImage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CartItemModel && other.bookId == bookId;

  @override
  int get hashCode => bookId.hashCode;
}
