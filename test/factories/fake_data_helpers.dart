/// Map-based helpers mirroring [FakeDataFactory] — useful for tests that go
/// through the `fromMap`/`toApi` serialization path instead of the
/// typed constructors.
///
/// All maps are mutable copies, so tests may add or override extra keys
/// without affecting other calls.
class FakeDataHelpers {
  FakeDataHelpers._();

  /// An API-shaped book payload map. Every [FakeDataFactory.book]
  /// field is present, with optional overrides.
  static Map<String, dynamic> bookMap({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? description,
    double? price,
    int? stock,
    String? coverImage,
    String? categoryId,
    String? categoryName,
    double? rating,
    int? reviewCount,
    bool? isBestseller,
    bool? isNewArrival,
    List<String>? images,
    String? language,
    int? pages,
    String? publisher,
  }) {
    return <String, dynamic>{
      'id': id ?? 'book_1',
      'title': title ?? 'The Test Book',
      'author': author ?? 'Jane Doe',
      'isbn': isbn ?? '9780000000001',
      'description': description ?? 'A compelling read.',
      'price': price ?? 19.99,
      'stock': stock ?? 10,
      'coverImage': coverImage ?? 'https://example.com/covers/book_1.jpg',
      'categoryId': categoryId ?? 'cat_fiction',
      'categoryName': categoryName ?? 'Fiction',
      'rating': rating ?? 4.5,
      'reviewCount': reviewCount ?? 12,
      'isBestseller': isBestseller ?? false,
      'isNewArrival': isNewArrival ?? false,
      'images': images ?? <String>[],
      'language': language ?? 'English',
      'pages': pages ?? 320,
      'publisher': publisher ?? 'Test Press',
    };
  }

  /// [bookMap] repeated [count] times, each with a unique id and title.
  static List<Map<String, dynamic>> bookMaps({int count = 5}) => List.generate(
    count,
    (i) => bookMap(id: 'book_${i + 1}', title: 'Test Book ${i + 1}'),
  );

  /// An API-shaped category payload map.
  static Map<String, dynamic> categoryMap({
    String? id,
    String? name,
    String? image,
    String? description,
    int? bookCount,
  }) {
    return <String, dynamic>{
      'id': id ?? 'cat_fiction',
      'name': name ?? 'Fiction',
      'image': image ?? 'https://example.com/categories/fiction.png',
      'description': description ?? 'All books in the Fiction category.',
      'bookCount': bookCount ?? 25,
    };
  }

  /// An API-shaped user payload map (customer by default).
  static Map<String, dynamic> userMap({
    String? uid,
    String? name,
    String? email,
    String? role,
    bool? isBlocked,
  }) {
    final resolvedName = name ?? 'Jane Doe';
    return <String, dynamic>{
      'uid': uid ?? 'user_1',
      'name': resolvedName,
      'email': email ?? 'jane.doe@example.com',
      'phone': '+15551234567',
      'photoUrl': '',
      'role': role ?? 'customer',
      'addresses': <Map<String, dynamic>>[addressMap()],
      'paymentMethods': <Map<String, dynamic>>[
        paymentMethodMap(holderName: resolvedName),
      ],
      'isBlocked': isBlocked ?? false,
    };
  }

  /// An API-shaped address map (as embedded inside a user payload).
  static Map<String, dynamic> addressMap({
    String? id,
    String? label,
    String? line1,
    String? city,
    String? zip,
    bool? isDefault,
  }) {
    return <String, dynamic>{
      'id': id ?? 'addr_1',
      'label': label ?? 'Home',
      'line1': line1 ?? '123 Main St',
      'line2': '',
      'city': city ?? 'New York',
      'zip': zip ?? '10001',
      'phone': '+15551234567',
      'isDefault': isDefault ?? true,
    };
  }

  /// An API-shaped payment method map (as embedded inside a user payload).
  static Map<String, dynamic> paymentMethodMap({
    String? id,
    String? type,
    String? last4,
    String? holderName,
    String? expiry,
    bool? isDefault,
  }) {
    return <String, dynamic>{
      'id': id ?? 'pay_1',
      'type': type ?? 'Visa',
      'last4': last4 ?? '4242',
      'holderName': holderName ?? 'Jane Doe',
      'expiry': expiry ?? '12/29',
      'isDefault': isDefault ?? true,
    };
  }

  /// An API-shaped cart payload map.
  static Map<String, dynamic> cartMap({
    String? userId,
    List<Map<String, dynamic>>? items,
  }) {
    return <String, dynamic>{
      'userId': userId ?? 'user_1',
      'items': items ?? <Map<String, dynamic>>[cartItemMap()],
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// An API-shaped cart line item map.
  static Map<String, dynamic> cartItemMap({
    String? bookId,
    String? title,
    double? price,
    int? qty,
  }) {
    return <String, dynamic>{
      'bookId': bookId ?? 'book_1',
      'title': title ?? 'The Test Book',
      'price': price ?? 19.99,
      'qty': qty ?? 1,
      'coverImage': '',
    };
  }

  /// An API-shaped order payload map (money fields pre-computed).
  static Map<String, dynamic> orderMap({
    String? id,
    String? userId,
    List<Map<String, dynamic>>? items,
    double? subtotal,
    double? shipping,
    String? status,
  }) {
    final resolvedItems = items ?? <Map<String, dynamic>>[orderItemMap()];
    final resolvedSubtotal = subtotal ?? 19.99;
    final resolvedShipping = shipping ?? 0.0;
    return <String, dynamic>{
      'id': id ?? 'order_1',
      'userId': userId ?? 'user_1',
      'userName': 'Jane Doe',
      'items': resolvedItems,
      'subtotal': resolvedSubtotal,
      'shipping': resolvedShipping,
      'total': resolvedSubtotal + resolvedShipping,
      'status': status ?? 'pending',
      'address': '123 Main St, New York, 10001',
      'paymentMethod': 'Visa •••• 4242',
      'orderDate': DateTime.now().toIso8601String(),
      'timeline': <Map<String, dynamic>>[
        {'status': status ?? 'pending', 'at': DateTime.now().toIso8601String()},
      ],
      'cancelledReason': '',
    };
  }

  /// An API-shaped order line item map.
  static Map<String, dynamic> orderItemMap({
    String? bookId,
    String? title,
    double? price,
    int? qty,
  }) {
    return <String, dynamic>{
      'bookId': bookId ?? 'book_1',
      'title': title ?? 'The Test Book',
      'price': price ?? 19.99,
      'qty': qty ?? 1,
      'coverImage': '',
    };
  }
}
