import 'dart:math';

import 'package:bookstore_app/data/models/address_model.dart';
import 'package:bookstore_app/data/models/book_model.dart';
import 'package:bookstore_app/data/models/cart_item_model.dart';
import 'package:bookstore_app/data/models/cart_model.dart';
import 'package:bookstore_app/data/models/category_model.dart';
import 'package:bookstore_app/data/models/notification_model.dart';
import 'package:bookstore_app/data/models/order_item_model.dart';
import 'package:bookstore_app/data/models/order_model.dart';
import 'package:bookstore_app/data/models/order_status.dart';
import 'package:bookstore_app/data/models/order_status_event.dart';
import 'package:bookstore_app/data/models/payment_method_model.dart';
import 'package:bookstore_app/data/models/review_model.dart';
import 'package:bookstore_app/data/models/user_model.dart';
import 'package:bookstore_app/data/models/wishlist_item_model.dart';
import 'package:bookstore_app/data/models/wishlist_model.dart';

/// A deterministic fake-data factory for tests.
///
/// Every method returns a fully-populated model with realistic values so
/// tests never have to hand-craft fixtures. Callers can override any field
/// via named parameters.
///
/// Example:
/// ```dart
/// final book = FakeDataFactory.book(title: 'Override', price: 9.99);
/// final user = FakeDataFactory.user(role: UserRole.admin);
/// ```
class FakeDataFactory {
  FakeDataFactory._();

  static final _random = Random(42);

  static const _firstNames = [
    'Jane',
    'John',
    'Alice',
    'Bob',
    'Charlie',
    'Diana',
    'Eve',
    'Frank',
    'Grace',
    'Hassan',
    'Ivy',
    'Kamran',
    'Lara',
    'Mohsin',
    'Nadia',
    'Omar',
  ];

  static const _lastNames = [
    'Doe',
    'Smith',
    'Johnson',
    'Williams',
    'Brown',
    'Akhtar',
    'Khan',
    'Ahmed',
    'Rizvi',
    'Malik',
    'Siddiqui',
    'Chaudhry',
  ];

  static const _titles = [
    'Clean Code',
    'The Pragmatic Programmer',
    'Design Patterns',
    'Refactoring',
    'Domain-Driven Design',
    'Atomic Habits',
    'Deep Work',
    'The Lean Startup',
    'Sapiens',
    'Educated',
    'Becoming',
    'The Alchemist',
    '1984',
    'To Kill a Mockingbird',
    'The Great Gatsby',
    'Dune',
    'Neuromancer',
    'Snow Crash',
  ];

  static const _writerNames = [
    'Robert C. Martin',
    'Andrew Hunt',
    'Erich Gamma',
    'Martin Fowler',
    'Eric Evans',
    'James Clear',
    'Cal Newport',
    'Eric Ries',
    'Yuval Noah Harari',
    'Tara Westover',
    'Michelle Obama',
    'Paulo Coelho',
    'George Orwell',
    'Harper Lee',
    'F. Scott Fitzgerald',
    'Frank Herbert',
    'William Gibson',
    'Neal Stephenson',
  ];

  static const _catNames = [
    'Fiction',
    'Non-Fiction',
    'Academic',
    'Comics',
    'Science Fiction',
    'Biography',
    'Self-Help',
    'History',
  ];

  static const _cityList = [
    'New York',
    'London',
    'Karachi',
    'Lahore',
    'Islamabad',
    'Berlin',
    'Toronto',
    'Sydney',
  ];

  static const _streetList = [
    '123 Main St',
    '456 Oak Ave',
    '789 Pine Rd',
    '10 Elm Blvd',
    '22 Maple Lane',
    '55 Cedar Court',
  ];

  static const _reviewTexts = [
    'Absolutely loved it!',
    'Great read, highly recommend.',
    'Good but not great.',
    'Could not put it down.',
    'A masterpiece of modern literature.',
    'Very insightful and well-written.',
    'Decent book, fast delivery.',
    'Exceeded my expectations.',
  ];

  static int _seq = 0;

  static String _nextId(String p) => '${p}_${++_seq}';

  static String _randName() =>
      '${_firstNames[_random.nextInt(_firstNames.length)]} '
      '${_lastNames[_random.nextInt(_lastNames.length)]}';

  static String _randEmail(String name) {
    final p = name.toLowerCase().split(' ');
    return '${p.first}.${p.last}@example.com';
  }

  static DateTime _randDate({int yearsBack = 2}) {
    final now = DateTime.now();
    final days = _random.nextInt(365 * yearsBack);
    return now.subtract(Duration(days: days));
  }

  static String _randIsbn() {
    final base = 9780000000000 + _random.nextInt(999999999);
    return base.toString().padLeft(13, '0').substring(0, 13);
  }

  static BookModel book({
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
    DateTime? releaseDate,
    DateTime? createdAt,
    List<String>? images,
    String? language,
    int? pages,
    String? publisher,
  }) {
    final idx = _random.nextInt(_titles.length);
    final isbnVal = _randIsbn();
    return BookModel(
      id: id ?? _nextId('book'),
      title: title ?? _titles[idx],
      author: author ?? _writerNames[idx],
      isbn: isbn ?? isbnVal,
      description: description ?? 'A compelling read.',
      price: price ?? ((_random.nextInt(50) + 10) + 0.99),
      stock: stock ?? (_random.nextInt(100) + 1),
      coverImage:
          coverImage ?? 'https://covers.openlibrary.org/b/isbn/$isbnVal-L.jpg',
      categoryId:
          categoryId ??
          'cat_${_catNames[_random.nextInt(_catNames.length)].toLowerCase().replaceAll(' ', '_')}',
      categoryName:
          categoryName ?? _catNames[_random.nextInt(_catNames.length)],
      rating: rating ?? ((_random.nextDouble() * 2 + 3)),
      reviewCount: reviewCount ?? _random.nextInt(500),
      isBestseller: isBestseller ?? _random.nextBool(),
      isNewArrival: isNewArrival ?? _random.nextBool(),
      releaseDate: releaseDate ?? _randDate(),
      createdAt: createdAt ?? _randDate(),
      images: images ?? [],
      language: language ?? 'English',
      pages: pages ?? (_random.nextInt(400) + 100),
      publisher: publisher ?? 'Penguin Random House',
    );
  }

  static List<BookModel> books({int count = 10}) =>
      List.generate(count, (_) => book());

  // ── Category ──────────────────────────────────

  static CategoryModel category({
    String? id,
    String? name,
    String? image,
    String? description,
    DateTime? createdAt,
    int? bookCount,
  }) {
    final idx = _random.nextInt(_catNames.length);
    final n = _catNames[idx];
    return CategoryModel(
      id: id ?? 'cat_${n.toLowerCase().replaceAll(' ', '_')}',
      name: name ?? n,
      image:
          image ??
          'https://example.com/categories/${n.toLowerCase().replaceAll(' ', '_')}.png',
      description: description ?? 'All books in the $n category.',
      createdAt: createdAt ?? _randDate(),
      bookCount: bookCount ?? _random.nextInt(200),
    );
  }

  static List<CategoryModel> categories({int count = 6}) =>
      List.generate(count, (_) => category());

  // ── Address ───────────────────────────────────

  static AddressModel address({
    String? id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? zip,
    String? phone,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? _nextId('addr'),
      label: label ?? 'Home',
      line1: line1 ?? _streetList[_random.nextInt(_streetList.length)],
      line2: line2 ?? '',
      city: city ?? _cityList[_random.nextInt(_cityList.length)],
      zip: zip ?? '${_random.nextInt(90000) + 10000}',
      phone: phone ?? _randPhone(),
      isDefault: isDefault ?? true,
    );
  }

  static String _randPhone() =>
      '+1${_random.nextInt(900) + 100}${_random.nextInt(900) + 100}${_random.nextInt(9000) + 1000}';

  // ── Payment Method ────────────────────────────

  static PaymentMethodModel paymentMethod({
    String? id,
    String? type,
    String? last4,
    String? holderName,
    String? expiry,
    bool? isDefault,
  }) {
    const types = ['Visa', 'Mastercard', 'Amex', 'Cash on Delivery'];
    final t = type ?? types[_random.nextInt(types.length)];
    final isCod = t.toLowerCase().contains('cash');
    final month = _random.nextInt(12) + 1;
    final year = _random.nextInt(6) + 27;
    return PaymentMethodModel(
      id: id ?? _nextId('pay'),
      type: t,
      last4: last4 ?? '${_random.nextInt(9000) + 1000}',
      holderName: holderName ?? _randName(),
      expiry: expiry ?? (isCod ? '' : '$month/$year'),
      isDefault: isDefault ?? true,
    );
  }

  // ── User ──────────────────────────────────────

  static UserModel user({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    List<AddressModel>? addresses,
    List<PaymentMethodModel>? paymentMethods,
    bool? isBlocked,
  }) {
    final resolvedName = name ?? _randName();
    return UserModel(
      uid: uid ?? _nextId('user'),
      name: resolvedName,
      email: email ?? _randEmail(resolvedName),
      phone: phone ?? _randPhone(),
      photoUrl:
          photoUrl ??
          'https://i.pravatar.cc/150?u=${resolvedName.split(' ').first.toLowerCase()}',
      role: role ?? UserRole.customer,
      createdAt: createdAt ?? _randDate(),
      addresses: addresses ?? [address()],
      paymentMethods: paymentMethods ?? [paymentMethod()],
      isBlocked: isBlocked ?? false,
    );
  }

  static List<UserModel> users({int count = 5}) =>
      List.generate(count, (_) => user());

  static UserModel admin({String? uid, String? name, String? email}) => user(
    uid: uid ?? _nextId('admin'),
    name: name,
    email: email,
    role: UserRole.admin,
  );

  // ── Cart ──────────────────────────────────────

  static CartItemModel cartItem({
    String? bookId,
    String? title,
    double? price,
    String? coverImage,
    int? qty,
  }) {
    final idx = _random.nextInt(_titles.length);
    final isbnVal = _randIsbn();
    return CartItemModel(
      bookId: bookId ?? _nextId('book'),
      title: title ?? _titles[idx],
      price: price ?? ((_random.nextInt(50) + 10) + 0.99),
      coverImage:
          coverImage ?? 'https://covers.openlibrary.org/b/isbn/$isbnVal-L.jpg',
      qty: qty ?? (_random.nextInt(5) + 1),
    );
  }

  static List<CartItemModel> cartItems({int count = 3}) =>
      List.generate(count, (_) => cartItem());

  static CartModel cart({
    String? userId,
    List<CartItemModel>? items,
    DateTime? updatedAt,
  }) {
    final resolvedItems = items ?? cartItems();
    return CartModel(
      userId: userId ?? _nextId('user'),
      items: resolvedItems,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ── Order ─────────────────────────────────────

  static OrderItemModel orderItem({
    String? bookId,
    String? title,
    double? price,
    int? qty,
    String? coverImage,
  }) {
    final idx = _random.nextInt(_titles.length);
    return OrderItemModel(
      bookId: bookId ?? _nextId('book'),
      title: title ?? _titles[idx],
      price: price ?? ((_random.nextInt(50) + 10) + 0.99),
      qty: qty ?? (_random.nextInt(4) + 1),
      coverImage: coverImage ?? '',
    );
  }

  static OrderStatusEvent statusEvent({
    OrderStatus? status,
    DateTime? at,
    String note = '',
  }) {
    final resolved =
        status ??
        OrderStatus.timeline[_random.nextInt(OrderStatus.timeline.length)];
    return OrderStatusEvent(
      status: resolved.value,
      at: at ?? _randDate(),
      note: note,
    );
  }

  /// Default tracking timeline covering the happy path up to [status];
  /// a cancelled order gets the full happy path plus a final cancel event
  /// (so the timeline is never empty).
  static List<OrderStatusEvent> _defaultTimeline(
    OrderStatus status,
    DateTime start,
  ) {
    final happy = OrderStatus.timeline;
    final idx = status.timelineIndex;
    final events = <OrderStatusEvent>[
      for (var i = 0; i <= (idx < 0 ? happy.length - 1 : idx); i++)
        OrderStatusEvent(
          status: happy[i].value,
          at: start.add(Duration(days: i)),
        ),
    ];
    if (status == OrderStatus.cancelled) {
      events.add(
        OrderStatusEvent(
          status: OrderStatus.cancelled.value,
          at: start.add(Duration(days: happy.length)),
          note: 'Cancelled by customer',
        ),
      );
    }
    return events;
  }

  /// Builds an order with a consistent money breakdown:
  /// [subtotal] defaults to the sum of item line totals, [shipping] follows
  /// [OrderModel.computeShipping], and `total = subtotal + shipping`.
  /// Delivered orders automatically get a [deliveryDate] and a non-empty
  /// tracking [timeline].
  static OrderModel order({
    String? id,
    String? userId,
    String? userName,
    List<OrderItemModel>? items,
    double? subtotal,
    double? shipping,
    OrderStatus? status,
    List<OrderStatusEvent>? timeline,
    String? address,
    String? paymentMethod,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? cancelledReason,
  }) {
    final resolvedItems = items ?? [orderItem(), orderItem()];
    final resolvedStatus =
        status ??
        OrderStatus.values[_random.nextInt(OrderStatus.values.length)];
    final resolvedSubtotal =
        subtotal ??
        resolvedItems.fold<double>(0, (s, i) => s + i.price * i.qty);
    final resolvedShipping =
        shipping ?? OrderModel.computeShipping(resolvedSubtotal);
    final resolvedOrderDate = orderDate ?? _randDate();
    final resolvedDelivery =
        deliveryDate ??
        (resolvedStatus == OrderStatus.delivered
            ? resolvedOrderDate.add(const Duration(days: 5))
            : null);
    return OrderModel(
      id: id ?? _nextId('order'),
      userId: userId ?? _nextId('user'),
      userName: userName ?? _randName(),
      items: resolvedItems,
      subtotal: resolvedSubtotal,
      shipping: resolvedShipping,
      total: resolvedSubtotal + resolvedShipping,
      status: resolvedStatus,
      address: address ?? _streetList[_random.nextInt(_streetList.length)],
      paymentMethod: paymentMethod ?? 'Visa •••• 4242',
      orderDate: resolvedOrderDate,
      deliveryDate: resolvedDelivery,
      timeline: timeline ?? _defaultTimeline(resolvedStatus, resolvedOrderDate),
      cancelledReason: cancelledReason ?? '',
    );
  }

  static List<OrderModel> orders({int count = 5}) =>
      List.generate(count, (_) => order());

  // ── Review ────────────────────────────────────

  static ReviewModel review({
    String? id,
    String? bookId,
    String? userId,
    String? userName,
    String? userPhoto,
    double? rating,
    String? comment,
    int? likes,
    List<String>? likedBy,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? _nextId('review'),
      bookId: bookId ?? _nextId('book'),
      userId: userId ?? _nextId('user'),
      userName: userName ?? _randName(),
      userPhoto:
          userPhoto ?? 'https://i.pravatar.cc/150?u=${_random.nextInt(100)}',
      rating: rating ?? (_random.nextInt(5) + 1).toDouble(),
      comment: comment ?? _reviewTexts[_random.nextInt(_reviewTexts.length)],
      likes: likes ?? _random.nextInt(50),
      likedBy: likedBy ?? [],
      createdAt: createdAt ?? _randDate(),
    );
  }

  static List<ReviewModel> reviews({int count = 8}) =>
      List.generate(count, (_) => review());

  // ── Wishlist ──────────────────────────────────

  static WishlistItemModel wishlistItem({
    String? bookId,
    String? title,
    double? price,
    String? coverImage,
    DateTime? addedAt,
  }) {
    final idx = _random.nextInt(_titles.length);
    final isbnVal = _randIsbn();
    return WishlistItemModel(
      bookId: bookId ?? _nextId('book'),
      title: title ?? _titles[idx],
      price: price ?? ((_random.nextInt(50) + 10) + 0.99),
      coverImage:
          coverImage ?? 'https://covers.openlibrary.org/b/isbn/$isbnVal-L.jpg',
      addedAt: addedAt ?? _randDate(),
    );
  }

  static WishlistModel wishlist({
    String? userId,
    List<WishlistItemModel>? items,
  }) {
    return WishlistModel(
      userId: userId ?? _nextId('user'),
      items: items ?? [wishlistItem(), wishlistItem(), wishlistItem()],
    );
  }

  // ── Notification ──────────────────────────────

  static NotificationModel notification({
    String? id,
    String? title,
    String? message,
    bool? read,
    DateTime? createdAt,
    String? type,
    String? orderId,
  }) {
    const types = ['general', 'order', 'promo', 'account'];
    final resolvedType = type ?? types[_random.nextInt(types.length)];
    return NotificationModel(
      id: id ?? _nextId('notif'),
      title: title ?? 'Order Update',
      message: message ?? 'Your order status has been updated.',
      read: read ?? _random.nextBool(),
      createdAt: createdAt ?? _randDate(),
      type: resolvedType,
      orderId: orderId ?? (resolvedType == 'order' ? _nextId('order') : ''),
    );
  }

  static List<NotificationModel> notifications({int count = 6}) =>
      List.generate(count, (_) => notification());

  // ── Full dataset ──────────────────────────────

  /// Returns a complete, consistent, cross-referencing dataset:
  /// books reference real categories, orders reference real users,
  /// reviews reference real books and users.
  static FakeDataSet dataset() {
    final cats = categories(count: 4);
    final bookList = List.generate(12, (i) {
      final cat = cats[i % cats.length];
      return book(
        categoryId: cat.id,
        categoryName: cat.name,
        title: _titles[i % _titles.length],
        author: _writerNames[i % _writerNames.length],
      );
    });
    final customerList = users(count: 3);
    final adminUser = admin(
      uid: 'admin_1',
      name: 'Admin User',
      email: 'admin@bookstore.com',
    );
    final allUsers = [adminUser, ...customerList];

    final orderList = List.generate(5, (i) {
      final usr = allUsers[i % allUsers.length];
      final b = bookList[i % bookList.length];
      return order(
        userId: usr.uid,
        userName: usr.name,
        items: [orderItem(bookId: b.id, title: b.title, price: b.price)],
        status: OrderStatus.values[i % OrderStatus.values.length],
      );
    });

    final reviewList = List.generate(8, (i) {
      final b = bookList[i % bookList.length];
      final usr = allUsers[i % allUsers.length];
      return review(bookId: b.id, userId: usr.uid, userName: usr.name);
    });

    final notifList = List.generate(6, (i) {
      final isOrder = i % 2 == 0;
      return notification(
        type: isOrder ? 'order' : 'promo',
        orderId: isOrder ? orderList[i % orderList.length].id : '',
      );
    });

    return FakeDataSet(
      categories: cats,
      books: bookList,
      users: allUsers,
      orders: orderList,
      reviews: reviewList,
      notifications: notifList,
    );
  }
}

/// A complete, cross-referencing fake dataset.
class FakeDataSet {
  const FakeDataSet({
    required this.categories,
    required this.books,
    required this.users,
    required this.orders,
    required this.reviews,
    required this.notifications,
  });

  final List<CategoryModel> categories;
  final List<BookModel> books;
  final List<UserModel> users;
  final List<OrderModel> orders;
  final List<ReviewModel> reviews;
  final List<NotificationModel> notifications;

  UserModel get admin => users.firstWhere((u) => u.isAdmin);
  List<UserModel> get customers =>
      users.where((u) => u.role.isCustomer).toList();
}
