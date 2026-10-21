import 'model_helpers.dart';

/// A snapshot of a book at purchase time.
///
/// Stored inside `orders/{orderId}.items[]` as `{bookId, title, price, qty}`
/// (plus cover image for nicer history cards). Snapshotting means later price
/// or title changes never rewrite a past order.
class OrderItemModel {
  const OrderItemModel({
    required this.bookId,
    required this.title,
    required this.price,
    required this.qty,
    this.coverImage = '',
  });

  final String bookId;
  final String title;
  final double price;
  final int qty;
  final String coverImage;

  double get lineTotal => price * qty;
  double get subtotal => lineTotal;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return OrderItemModel(
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
}
