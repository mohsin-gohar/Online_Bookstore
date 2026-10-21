import 'model_helpers.dart';
import 'wishlist_item_model.dart';

/// A user's wishlist.
///
/// Mirrors `wishlists/{userId}` with an embedded `items[]` array.
class WishlistModel {
  const WishlistModel({this.userId = '', this.items = const []});

  final String userId;
  final List<WishlistItemModel> items;

  // ── Convenience ───────────────────────────

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get count => items.length;

  /// True when [bookId] is saved in the wishlist.
  bool contains(String bookId) => items.any((e) => e.bookId == bookId);

  // ── Serialization ─────────────────────────

  factory WishlistModel.fromMap(Map<String, dynamic> map, {String? userId}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return WishlistModel(
      userId: parseString(m['userId'] ?? userId),
      items: parseList(m['items'], WishlistItemModel.fromMap),
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'items': items.map((e) => e.toMap()).toList(),
  };

  WishlistModel copyWith({String? userId, List<WishlistItemModel>? items}) {
    return WishlistModel(
      userId: userId ?? this.userId,
      items: items ?? this.items,
    );
  }

  /// An empty wishlist for [userId].
  static WishlistModel empty(String userId) => WishlistModel(userId: userId);
}
