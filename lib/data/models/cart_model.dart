import 'cart_item_model.dart';
import 'model_helpers.dart';

/// A user's shopping cart.
///
/// Mirrors `carts/{userId}` with an embedded `items[]` array and `updatedAt`.
class CartModel {
  const CartModel({this.userId = '', this.items = const [], this.updatedAt});

  final String userId;
  final List<CartItemModel> items;
  final DateTime? updatedAt;

  // ── Convenience ───────────────────────────

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Total number of units across all line items (used for the cart badge).
  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.qty);

  /// Number of distinct line items.
  int get lineCount => items.length;

  /// Sum of every line total (before shipping).
  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  /// True when [bookId] is already in the cart.
  bool contains(String bookId) => items.any((i) => i.bookId == bookId);

  /// Returns the quantity of [bookId] currently in the cart (0 if absent).
  int quantityOf(String bookId) {
    for (final item in items) {
      if (item.bookId == bookId) return item.qty;
    }
    return 0;
  }

  // ── Serialization ─────────────────────────

  factory CartModel.fromMap(Map<String, dynamic> map, {String? userId}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return CartModel(
      userId: parseString(m['userId'] ?? userId),
      items: parseList(m['items'], CartItemModel.fromMap),
      updatedAt: parseDate(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'items': items.map((i) => i.toMap()).toList(),
    'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
  };

  CartModel copyWith({
    String? userId,
    List<CartItemModel>? items,
    DateTime? updatedAt,
  }) {
    return CartModel(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// An empty cart for [userId].
  static CartModel empty(String userId) => CartModel(userId: userId);
}
