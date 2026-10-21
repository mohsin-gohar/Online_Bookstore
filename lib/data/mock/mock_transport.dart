import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';
import '../services/token_storage_service.dart';
import 'demo_catalog.dart';

/// Credentials of the demo **customer** account created by the mock backend.
const String demoCustomerEmail = 'reader@folio.app';
const String demoCustomerPassword = 'password123';
const String demoCustomerUid = 'user_demo_customer';

/// Credentials of the demo **admin** account created by the mock backend.
const String demoAdminEmail = 'admin@folio.app';
const String demoAdminPassword = 'admin123';
const String demoAdminUid = 'user_demo_admin';

/// An **in-memory Laravel server**.
///
/// It answers exactly the endpoints the app calls, with exactly the envelope
/// the app expects, so the whole application can be demonstrated without a
/// running backend:
///
/// ```bash
/// flutter run --dart-define=API_MODE=mock
/// ```
///
/// The mock is deliberately a *faithful* stand-in, not a shortcut:
///
///  * responses use `snake_case` keys, like a real Eloquent serialisation,
///  * pagination uses Laravel's `meta.current_page` / `last_page` /
///    `per_page` / `total`,
///  * validation failures use HTTP-422 semantics with a field → messages map,
///  * the session is a bearer token, and every request must present it.
class MockApiTransport implements ApiTransport {
  MockApiTransport({required this.tokenStorage}) {
    _seed();
  }

  /// Where the bearer token lives (shared with the live transport).
  final TokenStorageService tokenStorage;

  // ── In-memory data ────────────────────────

  final List<Map<String, dynamic>> _books = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _authors = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _faqs = <Map<String, dynamic>>[];

  /// uid → user record.
  final Map<String, Map<String, dynamic>> _users =
      <String, Map<String, dynamic>>{};

  /// email → password (never leaves the mock).
  final Map<String, String> _passwords = <String, String>{};

  /// bearer token → uid.
  final Map<String, String> _sessions = <String, String>{};

  /// uid → cart lines.
  final Map<String, List<Map<String, dynamic>>> _carts =
      <String, List<Map<String, dynamic>>>{};

  /// uid → wishlist lines.
  final Map<String, List<Map<String, dynamic>>> _wishlists =
      <String, List<Map<String, dynamic>>>{};

  /// uid → orders.
  final Map<String, List<Map<String, dynamic>>> _orders =
      <String, List<Map<String, dynamic>>>{};

  /// bookId → reviews.
  final Map<String, List<Map<String, dynamic>>> _reviews =
      <String, List<Map<String, dynamic>>>{};

  /// uid → notifications.
  final Map<String, List<Map<String, dynamic>>> _notifications =
      <String, List<Map<String, dynamic>>>{};

  /// email → six-digit reset code.
  final Map<String, String> _resetCodes = <String, String>{};

  final Random _random = Random();

  /// The user id of the current request (resolved from the bearer token).
  String? _sessionUid;

  // ── Seeding ───────────────────────────────

  void _seed() {
    final DateTime now = DateTime.now();
    for (final Map<String, dynamic> row in demoCategories) {
      _categories.add(<String, dynamic>{
        ...row,
        'createdAt': now.toIso8601String(),
      });
    }
    for (final Map<String, dynamic> row in demoAuthors) {
      _authors.add(<String, dynamic>{
        ...row,
        'bookCount': 0,
        'createdAt': now.toIso8601String(),
      });
    }
    for (final Map<String, dynamic> row in demoBooks) {
      _books.add(<String, dynamic>{
        ...row,
        'images': <String>[],
        'language': 'English',
        'releaseDate': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
      });
    }
    // Recompute the per-author book counts.
    for (final Map<String, dynamic> author in _authors) {
      final String id = author['id'] as String;
      author['bookCount'] = _books.where((b) => b['authorId'] == id).length;
    }
    for (final Map<String, dynamic> faq in demoFaqs) {
      _faqs.add(<String, dynamic>{...faq, 'sortOrder': _faqs.length});
    }
    // A couple of seed reviews so the reviews UI is not empty.
    _addReview(
      bookId: 'book_1',
      userId: 'demo_reader',
      userName: 'Priya R.',
      rating: 5,
      comment:
          'An absorbing read — the silence in this book is louder than the '
          'noise in most thrillers.',
    );
    _addReview(
      bookId: 'book_1',
      userId: 'demo_reader_2',
      userName: 'Daniel K.',
      rating: 4,
      comment: 'Great pacing. The ending divided my book club, in a good way.',
    );

    _seedAccounts();
  }

  /// Creates the two demo accounts the mock backend always starts with.
  ///
  /// A customer and an admin, so the mock mode behaves like a real server
  /// that already has accounts, addresses and orders — and so the app can be
  /// demonstrated (and smoke-tested) without registering first.
  void _seedAccounts() {
    final DateTime now = DateTime.now();

    _users[demoCustomerUid] = <String, dynamic>{
      'uid': demoCustomerUid,
      'name': 'Priya Raman',
      'email': demoCustomerEmail,
      'phone': '+92 300 1234567',
      'photoUrl': '',
      'role': 'customer',
      'createdAt': now.toIso8601String(),
      'addresses': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'addr_demo_1',
          'label': 'Home',
          'name': 'Priya Raman',
          'phone': '+92 300 1234567',
          'line1': '221B Baker Street',
          'line2': 'Marylebone',
          'city': 'London',
          'state': 'Greater London',
          'zip': 'W1U 7SA',
          'country': 'United Kingdom',
          'isDefault': true,
        },
      ],
      'paymentMethods': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'pm_demo_1',
          'type': 'card',
          'brand': 'visa',
          'last4': '4242',
          'expiryMonth': 12,
          'expiryYear': 2030,
          'isDefault': true,
        },
      ],
      'isBlocked': false,
    };
    _passwords[demoCustomerEmail] = demoCustomerPassword;

    _users[demoAdminUid] = <String, dynamic>{
      'uid': demoAdminUid,
      'name': 'Ada Whitfield',
      'email': demoAdminEmail,
      'phone': '+92 300 7654321',
      'photoUrl': '',
      'role': 'admin',
      'createdAt': now.toIso8601String(),
      'addresses': <Map<String, dynamic>>[],
      'paymentMethods': <Map<String, dynamic>>[],
      'isBlocked': false,
    };
    _passwords[demoAdminEmail] = demoAdminPassword;
  }

  void _addReview({
    required String bookId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
  }) {
    final List<Map<String, dynamic>> list = _reviews.putIfAbsent(
      bookId,
      () => <Map<String, dynamic>>[],
    );
    list.insert(0, <String, dynamic>{
      'id': 'review_${list.length + 1}_$bookId',
      'bookId': bookId,
      'userId': userId,
      'userName': userName,
      'userPhoto': '',
      'rating': rating,
      'comment': comment,
      'likes': 0,
      'likedBy': <String>[],
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // ── Transport ─────────────────────────────

  @override
  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) async {
    return _route('GET', path, query: query, body: null);
  }

  @override
  Future<ApiResponse> post(String path, {Object? body}) async {
    return _route('POST', path, query: null, body: body);
  }

  @override
  Future<ApiResponse> put(String path, {Object? body}) async {
    return _route('PUT', path, query: null, body: body);
  }

  @override
  Future<ApiResponse> patch(String path, {Object? body}) async {
    return _route('PATCH', path, query: null, body: body);
  }

  @override
  Future<ApiResponse> delete(String path, {Object? body}) async {
    return _route('DELETE', path, query: null, body: body);
  }

  @override
  Future<ApiResponse> upload(String path, FormData formData) async {
    // The mock cannot store binary files, but it must honour the contract:
    // return a URL the client can render.
    return _ok(<String, dynamic>{
      'url': 'https://cdn.folio.app/uploads/mock-cover.png',
      'path': 'uploads/mock-cover.png',
    });
  }

  // ── Router ────────────────────────────────

  Future<ApiResponse> _route(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    // Simulate a small amount of network latency so loading states are real.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final Map<String, dynamic> payload = body is Map
        ? body.cast<String, dynamic>()
        : <String, dynamic>{};

    // Resolve the session once per request, exactly as the HTTP interceptor
    // would attach the bearer token.
    _sessionUid = _uidFromToken(await tokenStorage.readToken());

    try {
      // ── Auth ──────────────────────────────
      if (method == 'POST' && path == ApiConstants.authRegister) {
        return _register(payload);
      }
      if (method == 'POST' && path == ApiConstants.authLogin) {
        return _login(payload);
      }
      if (method == 'POST' && path == ApiConstants.authGoogle) {
        return _googleLogin(payload);
      }
      if (method == 'POST' && path == ApiConstants.authLogout) {
        await tokenStorage.clear();
        return _ok(null, message: 'Signed out.');
      }
      if (method == 'POST' && path == ApiConstants.authForgotPassword) {
        return _forgotPassword(payload);
      }
      if (method == 'POST' && path == ApiConstants.authVerifyCode) {
        return _verifyCode(payload);
      }
      if (method == 'POST' && path == ApiConstants.authResetPassword) {
        return _resetPassword(payload);
      }

      // ── Account ───────────────────────────
      if (path == ApiConstants.me) {
        final String uid = _requireUser();
        if (method == 'GET') return _ok(_users[uid]);
        if (method == 'PUT') return _updateProfile(uid, payload);
      }
      if (method == 'PUT' && path == ApiConstants.mePassword) {
        return _changePassword(payload);
      }

      // ── Catalog ───────────────────────────
      if (path == ApiConstants.categories) {
        if (method == 'GET') {
          return _paginate(
            _categories
                .map(
                  (c) => <String, dynamic>{
                    ...c,
                    'bookCount': _books
                        .where((b) => b['categoryId'] == c['id'])
                        .length,
                  },
                )
                .toList(),
            query ?? <String, dynamic>{},
          );
        }
      }
      if (method == 'GET' && path.startsWith('${ApiConstants.categories}/')) {
        final String id = _lastSegment(path);
        final Map<String, dynamic>? category = _find(_categories, id);
        if (category == null) return _notFound('Category not found.');
        return _ok(category);
      }
      if (method == 'GET' && path == ApiConstants.authors) {
        final Map<String, dynamic> q = query ?? <String, dynamic>{};
        final String search = _str(q['search']).toLowerCase();
        final List<Map<String, dynamic>> authors = search.isEmpty
            ? _authors
            : _authors
                  .where(
                    (Map<String, dynamic> a) =>
                        _str(a['name']).toLowerCase().contains(search),
                  )
                  .toList();
        return _paginate(authors, q);
      }
      if (method == 'GET' && path.startsWith('${ApiConstants.authors}/')) {
        final String id = _lastSegment(path);
        final Map<String, dynamic>? author = _find(_authors, id);
        if (author == null) return _notFound('Author not found.');
        return _ok(author);
      }
      if (method == 'GET' && path == ApiConstants.books) {
        return _queryBooks(query ?? <String, dynamic>{});
      }
      if (method == 'GET' &&
          path.startsWith('${ApiConstants.books}/') &&
          path.endsWith('/reviews')) {
        return _ok(
          _reviews[_bookIdFromReviews(path)] ?? <Map<String, dynamic>>[],
        );
      }
      if (method == 'GET' && path.startsWith('${ApiConstants.books}/')) {
        final String id = _lastSegment(path);
        final Map<String, dynamic>? book = _find(_books, id);
        if (book == null) return _notFound('Book not found.');
        return _ok(book);
      }
      if (method == 'GET' && path == ApiConstants.reviews) {
        return _paginate(_allReviews(), query ?? <String, dynamic>{});
      }
      if (method == 'POST' && path.endsWith('/reviews')) {
        return _createReview(payload);
      }
      if (method == 'PUT' && path.startsWith('${ApiConstants.reviews}/')) {
        return _updateReview(_reviewId(path), payload);
      }
      if (method == 'DELETE' && path.startsWith('${ApiConstants.reviews}/')) {
        return _deleteReview(_reviewId(path));
      }
      if (method == 'POST' && path.startsWith('${ApiConstants.reviews}/')) {
        return _toggleReviewLike(_reviewId(path));
      }

      // ── Cart ──────────────────────────────
      if (path == ApiConstants.cart) {
        final String uid = _requireUser();
        if (method == 'GET') return _ok(_cartPayload(uid));
        if (method == 'DELETE') {
          _carts[uid] = <Map<String, dynamic>>[];
          return _ok(_cartPayload(uid));
        }
      }
      if (method == 'POST' && path == ApiConstants.cartItems) {
        return _addToCart(payload);
      }
      if (method == 'PATCH' && path.startsWith('${ApiConstants.cartItems}/')) {
        return _updateCartItem(_lastSegment(path), payload);
      }
      if (method == 'DELETE' && path.startsWith('${ApiConstants.cartItems}/')) {
        return _removeCartItem(_lastSegment(path));
      }

      // ── Wishlist ──────────────────────────
      if (path == ApiConstants.wishlist) {
        final String uid = _requireUser();
        if (method == 'GET') return _ok(_wishlistPayload(uid));
        if (method == 'DELETE') {
          _wishlists[uid] = <Map<String, dynamic>>[];
          return _ok(_wishlistPayload(uid));
        }
      }
      if (method == 'POST' && path.startsWith('${ApiConstants.wishlist}/')) {
        return _addToWishlist(_lastSegment(path));
      }
      if (method == 'DELETE' && path.startsWith('${ApiConstants.wishlist}/')) {
        return _removeFromWishlist(_lastSegment(path));
      }

      // ── Addresses & payment methods ───────
      if (path == ApiConstants.addresses) {
        final String uid = _requireUser();
        if (method == 'GET') return _ok(_userList(uid, 'addresses'));
        if (method == 'POST') {
          return _addUserChild(uid, 'addresses', payload);
        }
      }
      if (method == 'PUT' && path.startsWith('${ApiConstants.addresses}/')) {
        return _updateUserChild(
          _requireUser(),
          'addresses',
          _lastSegment(path),
          payload,
        );
      }
      if (method == 'DELETE' && path.startsWith('${ApiConstants.addresses}/')) {
        return _deleteUserChild(
          _requireUser(),
          'addresses',
          _lastSegment(path),
        );
      }
      if (path == ApiConstants.paymentMethods) {
        final String uid = _requireUser();
        if (method == 'GET') return _ok(_userList(uid, 'paymentMethods'));
        if (method == 'POST') {
          return _addUserChild(uid, 'paymentMethods', payload);
        }
      }
      if (method == 'PUT' &&
          path.startsWith('${ApiConstants.paymentMethods}/')) {
        return _updateUserChild(
          _requireUser(),
          'paymentMethods',
          _lastSegment(path),
          payload,
        );
      }
      if (method == 'DELETE' &&
          path.startsWith('${ApiConstants.paymentMethods}/')) {
        return _deleteUserChild(
          _requireUser(),
          'paymentMethods',
          _lastSegment(path),
        );
      }

      // ── Orders ────────────────────────────
      if (path == ApiConstants.orders) {
        final String uid = _requireUser();
        if (method == 'GET') {
          return _paginate(
            _orders[uid] ?? <Map<String, dynamic>>[],
            query ?? <String, dynamic>{},
          );
        }
        if (method == 'POST') return _placeOrder(uid, payload);
      }
      if (method == 'GET' && path.startsWith('${ApiConstants.orders}/')) {
        return _getOrder(_lastSegment(path));
      }
      if (method == 'POST' && path.endsWith('/cancel')) {
        return _cancelOrder(_orderIdFromCancel(path), payload);
      }

      // ── Notifications ─────────────────────
      if (path == ApiConstants.notifications) {
        final String uid = _requireUser();
        if (method == 'GET') {
          return _ok(_notifications[uid] ?? <Map<String, dynamic>>[]);
        }
        if (method == 'POST') {
          final Map<String, dynamic> notification = <String, dynamic>{
            'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
            'title': _str(payload['title']),
            'message': _str(payload['message']),
            'read': false,
            'type': _str(payload['type']),
            'orderId': _str(payload['order_id']),
            'createdAt': DateTime.now().toIso8601String(),
          };
          _notifications
              .putIfAbsent(uid, () => <Map<String, dynamic>>[])
              .insert(0, notification);
          return _ok(notification, message: 'Notification created.');
        }
      }
      if (method == 'POST' && path == ApiConstants.notificationsReadAll) {
        final String uid = _requireUser();
        for (final Map<String, dynamic> n
            in _notifications[uid] ?? <Map<String, dynamic>>[]) {
          n['read'] = true;
        }
        return _ok(null, message: 'All notifications marked as read.');
      }
      if (method == 'POST' && path.endsWith('/read')) {
        return _markNotificationRead(_notificationId(path));
      }
      if (method == 'DELETE' &&
          path.startsWith('${ApiConstants.notifications}/')) {
        return _deleteNotification(_notificationId(path));
      }

      // ── Help ──────────────────────────────
      if (method == 'GET' && path == ApiConstants.faqs) {
        return _ok(_faqs);
      }
      if (method == 'POST' && path == ApiConstants.supportMessages) {
        final String uid = _requireUser();
        return _ok(<String, dynamic>{
          'id': 'support_${DateTime.now().millisecondsSinceEpoch}',
          'userId': uid,
          'subject': payload['subject'] ?? '',
          'message': payload['message'] ?? '',
          'createdAt': DateTime.now().toIso8601String(),
        }, message: 'Message sent. We will reply shortly.');
      }

      // ── Admin ─────────────────────────────
      if (method == 'GET' && path == ApiConstants.adminStats) {
        return _adminStats();
      }
      if (path == ApiConstants.adminBooks) {
        _requireAdmin();
        if (method == 'GET') {
          return _paginate(_books, query ?? <String, dynamic>{});
        }
        if (method == 'POST') return _createBook(payload);
      }
      if (method == 'PUT' && path.startsWith('${ApiConstants.adminBooks}/')) {
        _requireAdmin();
        return _updateBook(_lastSegment(path), payload);
      }
      if (method == 'PATCH' && path.startsWith('${ApiConstants.adminBooks}/')) {
        // The client sends this PATCH itself, right after a review is
        // written, so it only needs a valid session - an admin token is not
        // required. The contract says the endpoint must not fail the request.
        _requireUser();
        return _updateBookRating(_lastSegment(path), payload);
      }
      if (method == 'DELETE' &&
          path.startsWith('${ApiConstants.adminBooks}/')) {
        _requireAdmin();
        final String id = _lastSegment(path);
        _books.removeWhere((b) => b['id'] == id);
        return _ok(null, message: 'Book deleted.');
      }
      if (path == ApiConstants.adminCategories) {
        _requireAdmin();
        if (method == 'GET') return _ok(_categories);
        if (method == 'POST') return _createCategory(payload);
      }
      if (method == 'PUT' &&
          path.startsWith('${ApiConstants.adminCategories}/')) {
        _requireAdmin();
        return _updateCategory(_lastSegment(path), payload);
      }
      if (method == 'DELETE' &&
          path.startsWith('${ApiConstants.adminCategories}/')) {
        _requireAdmin();
        final String id = _lastSegment(path);
        _categories.removeWhere((c) => c['id'] == id);
        return _ok(null, message: 'Category deleted.');
      }
      if (path == ApiConstants.adminAuthors) {
        _requireAdmin();
        if (method == 'GET') return _ok(_authors);
        if (method == 'POST') return _createAuthor(payload);
      }
      if (method == 'PUT' && path.startsWith('${ApiConstants.adminAuthors}/')) {
        _requireAdmin();
        return _updateAuthor(_lastSegment(path), payload);
      }
      if (method == 'DELETE' &&
          path.startsWith('${ApiConstants.adminAuthors}/')) {
        _requireAdmin();
        final String id = _lastSegment(path);
        _authors.removeWhere((a) => a['id'] == id);
        return _ok(null, message: 'Author deleted.');
      }
      if (method == 'GET' && path == ApiConstants.adminOrders) {
        _requireAdmin();
        final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
        for (final List<Map<String, dynamic>> list in _orders.values) {
          all.addAll(list);
        }
        all.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (b['orderDate'] as String).compareTo(a['orderDate'] as String),
        );
        return _paginate(all, query ?? <String, dynamic>{});
      }
      if (method == 'PATCH' && path.endsWith('/status')) {
        _requireAdmin();
        return _updateOrderStatus(_orderIdFromStatus(path), payload);
      }
      if (method == 'GET' && path == ApiConstants.adminUsers) {
        _requireAdmin();
        return _ok(_users.values.toList());
      }
      if (method == 'PATCH' && path.endsWith('/block')) {
        _requireAdmin();
        return _blockUser(_userIdFromBlock(path), payload);
      }

      return _notFound('No mock route for $method $path');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Mock backend error: $e');
    }
  }

  // ── Auth handlers ─────────────────────────

  ApiResponse _register(Map<String, dynamic> payload) {
    final String name = _str(payload['name']);
    final String email = _str(payload['email']).toLowerCase();
    final String password = _str(payload['password']);
    final String phone = _str(payload['phone']);

    final Map<String, String> errors = <String, String>{};
    if (name.isEmpty) errors['name'] = 'The name field is required.';
    if (!_isEmail(email)) errors['email'] = 'Enter a valid email address.';
    if (password.length < 6) {
      errors['password'] = 'The password must be at least 6 characters.';
    }
    if (_passwords.containsKey(email)) {
      errors['email'] = 'The email has already been taken.';
    }
    if (errors.isNotEmpty) {
      throw ValidationException.withFields(errors.values.first, errors);
    }

    final String uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> user = <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': '',
      'role': 'customer',
      'createdAt': DateTime.now().toIso8601String(),
      'addresses': <Map<String, dynamic>>[],
      'paymentMethods': <Map<String, dynamic>>[],
      'isBlocked': false,
    };
    _users[uid] = user;
    _passwords[email] = password;

    final String token = _issueToken(uid);
    return _ok(<String, dynamic>{
      'token': token,
      'user': user,
    }, message: 'Account created.');
  }

  ApiResponse _login(Map<String, dynamic> payload) {
    final String email = _str(payload['email']).toLowerCase();
    final String password = _str(payload['password']);

    final String? uid = _uidForEmail(email);
    if (uid == null || _passwords[email] != password) {
      throw const InvalidCredentialsException();
    }
    if (_users[uid]!['isBlocked'] == true) {
      throw const AccountBlockedException();
    }

    final String token = _issueToken(uid);
    return _ok(<String, dynamic>{'token': token, 'user': _users[uid]});
  }

  ApiResponse _googleLogin(Map<String, dynamic> payload) {
    // The real backend verifies the Google ID token server-side. The mock
    // accepts any non-empty token and maps it to a stable demo account.
    final String idToken = _str(payload['id_token']);
    if (idToken.isEmpty) {
      throw const ValidationException('A Google ID token is required.');
    }
    final String email = idToken.contains('@')
        ? idToken.split('@').first
        : 'demo.reader@folio.app';
    final String normalised = email.toLowerCase();
    String uid = _uidForEmail(normalised) ?? 'user_google_demo';
    if (!_users.containsKey(uid)) {
      _users[uid] = <String, dynamic>{
        'uid': uid,
        'name': 'Google Reader',
        'email': normalised,
        'phone': '',
        'photoUrl': '',
        'role': 'customer',
        'createdAt': DateTime.now().toIso8601String(),
        'addresses': <Map<String, dynamic>>[],
        'paymentMethods': <Map<String, dynamic>>[],
        'isBlocked': false,
      };
      _passwords[normalised] = 'google-sign-in';
    }
    final String token = _issueToken(uid);
    return _ok(<String, dynamic>{'token': token, 'user': _users[uid]});
  }

  ApiResponse _forgotPassword(Map<String, dynamic> payload) {
    final String email = _str(payload['email']).toLowerCase();
    final String? uid = _uidForEmail(email);
    if (uid == null) {
      // Do not leak whether the address exists.
      return _ok(null, message: 'If the account exists, a code was sent.');
    }
    final String code = (100000 + _random.nextInt(900000)).toString();
    _resetCodes[email] = code;
    return _ok(<String, dynamic>{
      'email': email,
      // The mock returns the code so the flow can be demonstrated without a
      // mailbox. A real backend must never do this.
      'devCode': code,
    }, message: 'Verification code sent.');
  }

  ApiResponse _verifyCode(Map<String, dynamic> payload) {
    final String email = _str(payload['email']).toLowerCase();
    final String code = _str(payload['code']);
    final String? expected = _resetCodes[email];
    if (expected == null) {
      throw const ValidationException('Request a new code first.');
    }
    if (expected != code) {
      throw const ValidationException('That code is not correct.');
    }
    return _ok(<String, dynamic>{'verified': true});
  }

  ApiResponse _resetPassword(Map<String, dynamic> payload) {
    final String email = _str(payload['email']).toLowerCase();
    final String code = _str(payload['code']);
    final String password = _str(payload['password']);
    if (password.length < 6) {
      throw const ValidationException.withFields(
        'The password must be at least 6 characters.',
        <String, String>{
          'password': 'The password must be at least 6 characters.',
        },
      );
    }
    if (_resetCodes[email] != code) {
      throw const ValidationException('That code is not correct.');
    }
    _passwords[email] = password;
    _resetCodes.remove(email);
    return _ok(null, message: 'Password updated. You can sign in now.');
  }

  ApiResponse _updateProfile(String uid, Map<String, dynamic> payload) {
    final Map<String, dynamic> user = _users[uid]!;
    if (payload.containsKey('name')) user['name'] = _str(payload['name']);
    if (payload.containsKey('phone')) user['phone'] = _str(payload['phone']);
    if (payload.containsKey('photo_url')) {
      user['photoUrl'] = _str(payload['photo_url']);
    }
    return _ok(user, message: 'Profile updated.');
  }

  ApiResponse _changePassword(Map<String, dynamic> payload) {
    final String uid = _requireUser();
    final String current = _str(payload['current_password']);
    final String next = _str(payload['new_password']);
    final String email = _str(_users[uid]!['email']);
    if (_passwords[email] != current) {
      throw const InvalidCredentialsException(
        'Your current password is wrong.',
      );
    }
    if (next.length < 6) {
      throw const ValidationException.withFields(
        'The password must be at least 6 characters.',
        <String, String>{
          'new_password': 'The password must be at least 6 characters.',
        },
      );
    }
    _passwords[email] = next;
    return _ok(null, message: 'Password updated.');
  }

  // ── Catalog handlers ──────────────────────

  ApiResponse _queryBooks(Map<String, dynamic> query) {
    final String search = _str(query['search']).toLowerCase();
    final String author = _str(query['author']).toLowerCase();
    final String authorId = _str(query['author_id']);
    final String category = _str(query['category_id']);
    final String genre = _str(query['genre']).toLowerCase();
    final double? minPrice = _double(query['min_price']);
    final double? maxPrice = _double(query['max_price']);
    final double? minRating = _double(query['min_rating']);
    final bool inStock = _bool(query['in_stock']);
    final bool bestsellers = _bool(query['bestsellers']);
    final bool newArrivals = _bool(query['new_arrivals']);

    List<Map<String, dynamic>> result = _books.where((Map<String, dynamic> b) {
      if (search.isNotEmpty) {
        final String haystack =
            '${b['title']} ${b['author']} ${b['categoryName']}'.toLowerCase();
        if (!haystack.contains(search)) return false;
      }
      if (authorId.isNotEmpty && b['authorId'] != authorId) return false;
      if (author.isNotEmpty &&
          !_str(b['author']).toLowerCase().contains(author)) {
        return false;
      }
      if (category.isNotEmpty && b['categoryId'] != category) return false;
      if (genre.isNotEmpty &&
          !_str(b['categoryName']).toLowerCase().contains(genre)) {
        return false;
      }
      final double price = (b['price'] as num).toDouble();
      if (minPrice != null && price < minPrice) return false;
      if (maxPrice != null && price > maxPrice) return false;
      final double rating = (b['rating'] as num).toDouble();
      if (minRating != null && rating < minRating) return false;
      if (inStock && (b['stock'] as int) <= 0) return false;
      if (bestsellers && b['isBestseller'] != true) return false;
      if (newArrivals && b['isNewArrival'] != true) return false;
      return true;
    }).toList();

    final String sort = _str(query['sort']).toLowerCase();
    result = _sortBooks(result, sort);

    return _paginate(result, query);
  }

  List<Map<String, dynamic>> _sortBooks(
    List<Map<String, dynamic>> books,
    String sort,
  ) {
    switch (sort) {
      case 'price_low_high':
        books.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (a['price'] as num).compareTo(b['price'] as num),
        );
      case 'price_high_low':
        books.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (b['price'] as num).compareTo(a['price'] as num),
        );
      case 'popularity':
        books.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (b['reviewCount'] as num).compareTo(a['reviewCount'] as num),
        );
      case 'rating':
        books.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (b['rating'] as num).compareTo(a['rating'] as num),
        );
      case 'oldest':
        books.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (a['createdAt'] as String).compareTo(b['createdAt'] as String),
        );
      case 'newest':
      default:
        books.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (b['createdAt'] as String).compareTo(a['createdAt'] as String),
        );
    }
    return books;
  }

  ApiResponse _createBook(Map<String, dynamic> payload) {
    final String id = 'book_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> book = <String, dynamic>{
      'id': id,
      'title': _str(payload['title']),
      'author': _str(payload['author']),
      'authorId': _str(payload['author_id']),
      'categoryId': _str(payload['category_id']),
      'categoryName': _str(payload['category_name']),
      'price': _double(payload['price']) ?? 0,
      'stock': _int(payload['stock']),
      'description': _str(payload['description']),
      'isbn': _str(payload['isbn']),
      'coverImage': _str(payload['cover_image']),
      'publisher': _str(payload['publisher']),
      'pages': _int(payload['pages']),
      'language': 'English',
      'rating': 0,
      'reviewCount': 0,
      'isBestseller': false,
      'isNewArrival': true,
      'images': <String>[],
      'releaseDate': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    _books.add(book);
    return _ok(book, message: 'Book created.');
  }

  ApiResponse _updateBook(String id, Map<String, dynamic> payload) {
    final Map<String, dynamic>? book = _find(_books, id);
    if (book == null) return _notFound('Book not found.');
    _toCamelKeys(payload).forEach((String key, dynamic value) {
      if (key == 'id') return;
      book[key] = value;
    });
    return _ok(book, message: 'Book updated.');
  }

  /// Updates the denormalised rating aggregate of a book.
  ///
  /// The client PATCHes `{rating, review_count}` after every review is
  /// written, edited or deleted, so the book's row keeps the aggregate in
  /// step with the review table. Only those two fields are touched; every
  /// other field of the book is left alone.
  ApiResponse _updateBookRating(String id, Map<String, dynamic> payload) {
    final Map<String, dynamic>? book = _find(_books, id);
    if (book == null) return _notFound('Book not found.');
    // The request body is snake_case (`review_count`), the row is camelCase.
    final Map<String, dynamic> fields = _toCamelKeys(payload);
    if (fields.containsKey('rating')) {
      book['rating'] = _double(fields['rating']) ?? 0;
    }
    if (fields.containsKey('reviewCount')) {
      book['reviewCount'] = _int(fields['reviewCount']);
    }
    return _ok(book, message: 'Book rating updated.');
  }

  ApiResponse _createCategory(Map<String, dynamic> payload) {
    final String id = _str(payload['id']).isEmpty
        ? 'cat_${DateTime.now().millisecondsSinceEpoch}'
        : _str(payload['id']);
    final Map<String, dynamic> category = <String, dynamic>{
      'id': id,
      'name': _str(payload['name']),
      'description': _str(payload['description']),
      'image': _str(payload['image']),
      'createdAt': DateTime.now().toIso8601String(),
    };
    _categories.add(category);
    return _ok(category, message: 'Category created.');
  }

  ApiResponse _updateCategory(String id, Map<String, dynamic> payload) {
    final Map<String, dynamic>? category = _find(_categories, id);
    if (category == null) return _notFound('Category not found.');
    _toCamelKeys(payload).forEach((String key, dynamic value) {
      if (key == 'id') return;
      category[key] = value;
    });
    return _ok(category, message: 'Category updated.');
  }

  ApiResponse _createAuthor(Map<String, dynamic> payload) {
    final String id = _str(payload['id']).isEmpty
        ? 'author_${DateTime.now().millisecondsSinceEpoch}'
        : _str(payload['id']);
    final Map<String, dynamic> author = <String, dynamic>{
      'id': id,
      'name': _str(payload['name']),
      'bio': _str(payload['bio']),
      'photoUrl': _str(payload['photo_url']),
      'bookCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _authors.add(author);
    return _ok(author, message: 'Author created.');
  }

  ApiResponse _updateAuthor(String id, Map<String, dynamic> payload) {
    final Map<String, dynamic>? author = _find(_authors, id);
    if (author == null) return _notFound('Author not found.');
    _toCamelKeys(payload).forEach((String key, dynamic value) {
      if (key == 'id') return;
      author[key] = value;
    });
    return _ok(author, message: 'Author updated.');
  }

  // ── Reviews ───────────────────────────────

  ApiResponse _createReview(Map<String, dynamic> payload) {
    final String uid = _requireUser();
    final String bookId = _str(payload['book_id']);
    final int rating = _int(payload['rating']);
    final String comment = _str(payload['comment']);

    final Map<String, String> errors = <String, String>{};
    if (rating < 1 || rating > 5) {
      errors['rating'] = 'Choose a rating between 1 and 5.';
    }
    if (comment.trim().length < 10) {
      errors['comment'] = 'Write at least 10 characters.';
    }
    if (errors.isNotEmpty) {
      throw ValidationException.withFields(errors.values.first, errors);
    }

    final List<Map<String, dynamic>> list = _reviews.putIfAbsent(
      bookId,
      () => <Map<String, dynamic>>[],
    );
    final Map<String, dynamic> review = <String, dynamic>{
      'id': 'review_${DateTime.now().millisecondsSinceEpoch}',
      'bookId': bookId,
      'userId': uid,
      'userName': _str(_users[uid]!['name']),
      'userPhoto': _str(_users[uid]!['photoUrl']),
      'rating': rating,
      'comment': comment,
      'likes': 0,
      'likedBy': <String>[],
      'createdAt': DateTime.now().toIso8601String(),
    };
    list.insert(0, review);
    _syncBookRating(bookId);
    return _ok(review, message: 'Review published.');
  }

  ApiResponse _updateReview(String id, Map<String, dynamic> payload) {
    final String uid = _requireUser();
    final Map<String, dynamic>? review = _findReview(id);
    if (review == null) return _notFound('Review not found.');
    if (review['userId'] != uid) {
      throw const AccountBlockedException('You can only edit your own review.');
    }
    if (payload.containsKey('rating')) {
      review['rating'] = _int(payload['rating']);
    }
    if (payload.containsKey('comment')) {
      review['comment'] = _str(payload['comment']);
    }
    _syncBookRating(_str(review['bookId']));
    return _ok(review, message: 'Review updated.');
  }

  ApiResponse _deleteReview(String id) {
    final String uid = _requireUser();
    final Map<String, dynamic>? review = _findReview(id);
    if (review == null) return _notFound('Review not found.');
    if (review['userId'] != uid) {
      throw const AccountBlockedException(
        'You can only delete your own review.',
      );
    }
    final String bookId = _str(review['bookId']);
    _reviews[bookId]?.removeWhere((Map<String, dynamic> r) => r['id'] == id);
    _syncBookRating(bookId);
    return _ok(null, message: 'Review deleted.');
  }

  ApiResponse _toggleReviewLike(String id) {
    final String uid = _requireUser();
    final Map<String, dynamic>? review = _findReview(id);
    if (review == null) return _notFound('Review not found.');
    final List<dynamic> likedBy =
        (review['likedBy'] as List<dynamic>?) ?? <dynamic>[];
    final bool liked = likedBy.contains(uid);
    if (liked) {
      likedBy.remove(uid);
    } else {
      likedBy.add(uid);
    }
    review['likedBy'] = likedBy;
    review['likes'] = likedBy.length;
    return _ok(review);
  }

  Map<String, dynamic>? _findReview(String id) {
    for (final List<Map<String, dynamic>> list in _reviews.values) {
      for (final Map<String, dynamic> review in list) {
        if (review['id'] == id) return review;
      }
    }
    return null;
  }

  void _syncBookRating(String bookId) {
    final Map<String, dynamic>? book = _find(_books, bookId);
    if (book == null) return;
    final List<Map<String, dynamic>> list =
        _reviews[bookId] ?? <Map<String, dynamic>>[];
    if (list.isEmpty) {
      book['rating'] = 0;
      book['reviewCount'] = 0;
      return;
    }
    final double total = list.fold<double>(
      0,
      (double sum, Map<String, dynamic> r) =>
          sum + (r['rating'] as num).toDouble(),
    );
    book['rating'] = (total / list.length).roundToDouble();
    book['reviewCount'] = list.length;
  }

  // ── Cart & wishlist ───────────────────────

  ApiResponse _addToCart(Map<String, dynamic> payload) {
    final String uid = _requireUser();
    final String bookId = _str(payload['book_id']);
    final int qty = _int(payload['qty'], fallback: 1);
    final Map<String, dynamic>? book = _find(_books, bookId);
    if (book == null) return _notFound('Book not found.');
    if ((book['stock'] as int) <= 0) {
      throw const ValidationException('This book is out of stock.');
    }

    final List<Map<String, dynamic>> items = _carts.putIfAbsent(
      uid,
      () => <Map<String, dynamic>>[],
    );
    final Map<String, dynamic>? existing = items
        .where((Map<String, dynamic> i) => i['bookId'] == bookId)
        .firstOrNull;
    if (existing != null) {
      existing['qty'] = (existing['qty'] as int) + qty;
    } else {
      items.add(<String, dynamic>{
        'bookId': bookId,
        'title': book['title'],
        'price': book['price'],
        'qty': qty,
        'coverImage': book['coverImage'],
      });
    }
    return _ok(_cartPayload(uid), message: 'Added to cart.');
  }

  ApiResponse _updateCartItem(String bookId, Map<String, dynamic> payload) {
    final String uid = _requireUser();
    final int qty = _int(payload['qty']);
    final List<Map<String, dynamic>> items =
        _carts[uid] ?? <Map<String, dynamic>>[];
    final Map<String, dynamic>? item = items
        .where((Map<String, dynamic> i) => i['bookId'] == bookId)
        .firstOrNull;
    if (item == null) return _notFound('That item is not in your cart.');
    if (qty <= 0) {
      items.remove(item);
    } else {
      item['qty'] = qty;
    }
    return _ok(_cartPayload(uid));
  }

  ApiResponse _removeCartItem(String bookId) {
    final String uid = _requireUser();
    final List<Map<String, dynamic>> items =
        _carts[uid] ?? <Map<String, dynamic>>[];
    items.removeWhere((Map<String, dynamic> i) => i['bookId'] == bookId);
    return _ok(_cartPayload(uid), message: 'Item removed.');
  }

  Map<String, dynamic> _cartPayload(String uid) {
    final List<Map<String, dynamic>> items =
        _carts[uid] ?? <Map<String, dynamic>>[];
    return <String, dynamic>{
      'userId': uid,
      'items': items,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  ApiResponse _addToWishlist(String bookId) {
    final String uid = _requireUser();
    final Map<String, dynamic>? book = _find(_books, bookId);
    if (book == null) return _notFound('Book not found.');
    final List<Map<String, dynamic>> items = _wishlists.putIfAbsent(
      uid,
      () => <Map<String, dynamic>>[],
    );
    final bool exists = items.any(
      (Map<String, dynamic> i) => i['bookId'] == bookId,
    );
    if (!exists) {
      items.add(<String, dynamic>{
        'bookId': bookId,
        'title': book['title'],
        'price': book['price'],
        'coverImage': book['coverImage'],
        'addedAt': DateTime.now().toIso8601String(),
      });
    }
    return _ok(_wishlistPayload(uid), message: 'Saved to wishlist.');
  }

  ApiResponse _removeFromWishlist(String bookId) {
    final String uid = _requireUser();
    final List<Map<String, dynamic>> items =
        _wishlists[uid] ?? <Map<String, dynamic>>[];
    items.removeWhere((Map<String, dynamic> i) => i['bookId'] == bookId);
    return _ok(_wishlistPayload(uid), message: 'Removed from wishlist.');
  }

  Map<String, dynamic> _wishlistPayload(String uid) {
    return <String, dynamic>{
      'userId': uid,
      'items': _wishlists[uid] ?? <Map<String, dynamic>>[],
    };
  }

  // ── Addresses & payment methods ───────────

  List<Map<String, dynamic>> _userList(String uid, String key) {
    final List<dynamic> raw = _users[uid]![key] as List<dynamic>;
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> m) => m.cast<String, dynamic>())
        .toList();
  }

  ApiResponse _addUserChild(
    String uid,
    String key,
    Map<String, dynamic> payload,
  ) {
    final Map<String, dynamic> item = <String, dynamic>{
      'id': _str(payload['id']).isEmpty
          ? '${key}_${DateTime.now().millisecondsSinceEpoch}'
          : _str(payload['id']),
      ..._toCamelKeys(payload),
    };
    final List<dynamic> list = _users[uid]![key] as List<dynamic>;
    list.add(item);
    return _ok(item, message: 'Saved.');
  }

  ApiResponse _updateUserChild(
    String uid,
    String key,
    String id,
    Map<String, dynamic> payload,
  ) {
    final List<dynamic> list = _users[uid]![key] as List<dynamic>;
    for (final dynamic item in list) {
      if (item is Map && item['id'] == id) {
        _toCamelKeys(payload).forEach((String k, dynamic v) {
          if (k != 'id') item[k] = v;
        });
        return _ok(item.cast<String, dynamic>(), message: 'Updated.');
      }
    }
    return _notFound('Not found.');
  }

  ApiResponse _deleteUserChild(String uid, String key, String id) {
    final List<dynamic> list = _users[uid]![key] as List<dynamic>;
    list.removeWhere((dynamic item) => item is Map && item['id'] == id);
    return _ok(null, message: 'Deleted.');
  }

  // ── Orders ────────────────────────────────

  ApiResponse _placeOrder(String uid, Map<String, dynamic> payload) {
    final List<Map<String, dynamic>> items =
        _carts[uid] ?? <Map<String, dynamic>>[];
    if (items.isEmpty) {
      throw const ValidationException('Your cart is empty.');
    }

    final double subtotal = items.fold<double>(
      0,
      (double sum, Map<String, dynamic> i) =>
          sum + (i['price'] as num).toDouble() * (i['qty'] as int),
    );
    const double freeThreshold = 50;
    const double flatFee = 5.99;
    final double shipping = subtotal >= freeThreshold ? 0 : flatFee;
    final DateTime now = DateTime.now();

    final List<Map<String, dynamic>> orderItems = items.map((
      Map<String, dynamic> i,
    ) {
      return <String, dynamic>{
        'bookId': i['bookId'],
        'title': i['title'],
        'price': i['price'],
        'qty': i['qty'],
        'coverImage': i['coverImage'],
      };
    }).toList();

    final Map<String, dynamic> order = <String, dynamic>{
      'id': 'ORD-${now.millisecondsSinceEpoch.toString().substring(6)}',
      'userId': uid,
      'userName': _str(_users[uid]!['name']),
      'items': orderItems,
      'subtotal': subtotal,
      'shipping': shipping,
      'total': subtotal + shipping,
      'status': 'pending',
      'address': _str(payload['address']),
      'paymentMethod': _str(payload['payment_method']),
      'orderDate': now.toIso8601String(),
      'deliveryDate': now.add(const Duration(days: 3)).toIso8601String(),
      'timeline': <Map<String, dynamic>>[
        <String, dynamic>{
          'status': 'pending',
          'at': now.toIso8601String(),
          'note': 'Order placed.',
        },
      ],
      'cancelledReason': '',
    };

    _orders.putIfAbsent(uid, () => <Map<String, dynamic>>[]).insert(0, order);

    // Reduce stock.
    for (final Map<String, dynamic> line in orderItems) {
      final Map<String, dynamic>? book = _find(_books, _str(line['bookId']));
      if (book != null) {
        book['stock'] = ((book['stock'] as int) - (line['qty'] as int)).clamp(
          0,
          1 << 31,
        );
      }
    }

    _carts[uid] = <Map<String, dynamic>>[];

    _notifications
        .putIfAbsent(uid, () => <Map<String, dynamic>>[])
        .insert(0, <String, dynamic>{
          'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Order placed',
          'message': 'Your order ${order['id']} is now pending.',
          'read': false,
          'type': 'order',
          'orderId': order['id'],
          'createdAt': DateTime.now().toIso8601String(),
        });

    return _ok(order, message: 'Order placed.');
  }

  ApiResponse _getOrder(String id) {
    final String uid = _requireUser();
    for (final Map<String, dynamic> order
        in _orders[uid] ?? <Map<String, dynamic>>[]) {
      if (order['id'] == id) return _ok(order);
    }
    return _notFound('Order not found.');
  }

  ApiResponse _cancelOrder(String id, Map<String, dynamic> payload) {
    final String uid = _requireUser();
    for (final Map<String, dynamic> order
        in _orders[uid] ?? <Map<String, dynamic>>[]) {
      if (order['id'] != id) continue;
      final String status = _str(order['status']);
      if (status != 'pending' && status != 'confirmed') {
        throw const ValidationException(
          'This order can no longer be cancelled.',
        );
      }
      order['status'] = 'cancelled';
      order['cancelledReason'] = _str(payload['reason']);
      (order['timeline'] as List<dynamic>).add(<String, dynamic>{
        'status': 'cancelled',
        'at': DateTime.now().toIso8601String(),
        'note': _str(payload['reason']).isEmpty
            ? 'Cancelled by the customer.'
            : _str(payload['reason']),
      });
      return _ok(order, message: 'Order cancelled.');
    }
    return _notFound('Order not found.');
  }

  ApiResponse _updateOrderStatus(String id, Map<String, dynamic> payload) {
    _requireAdmin();
    final String status = _str(payload['status']);
    for (final List<Map<String, dynamic>> list in _orders.values) {
      for (final Map<String, dynamic> order in list) {
        if (order['id'] != id) continue;
        order['status'] = status;
        (order['timeline'] as List<dynamic>).add(<String, dynamic>{
          'status': status,
          'at': DateTime.now().toIso8601String(),
          'note': _str(payload['note']),
        });
        final String uid = _str(order['userId']);
        _notifications
            .putIfAbsent(uid, () => <Map<String, dynamic>>[])
            .insert(0, <String, dynamic>{
              'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
              'title': 'Order $status',
              'message': 'Your order $id is now $status.',
              'read': false,
              'type': 'order',
              'orderId': id,
              'createdAt': DateTime.now().toIso8601String(),
            });
        return _ok(order, message: 'Status updated.');
      }
    }
    return _notFound('Order not found.');
  }

  ApiResponse _markNotificationRead(String id) {
    final String uid = _requireUser();
    for (final Map<String, dynamic> n
        in _notifications[uid] ?? <Map<String, dynamic>>[]) {
      if (n['id'] == id) {
        n['read'] = true;
        return _ok(n);
      }
    }
    return _notFound('Notification not found.');
  }

  ApiResponse _deleteNotification(String id) {
    final String uid = _requireUser();
    final List<Map<String, dynamic>> list =
        _notifications[uid] ?? <Map<String, dynamic>>[];
    list.removeWhere((Map<String, dynamic> n) => n['id'] == id);
    return _ok(null, message: 'Notification deleted.');
  }

  // ── Admin ────────────────────────────────

  ApiResponse _adminStats() {
    _requireAdmin();
    double revenue = 0;
    int pending = 0;
    for (final List<Map<String, dynamic>> list in _orders.values) {
      for (final Map<String, dynamic> order in list) {
        revenue += (order['total'] as num).toDouble();
        if (order['status'] == 'pending') pending++;
      }
    }
    return _ok(<String, dynamic>{
      'totalBooks': _books.length,
      'totalCategories': _categories.length,
      'totalAuthors': _authors.length,
      'totalUsers': _users.length,
      'totalOrders': _orders.values.fold<int>(
        0,
        (int s, List<Map<String, dynamic>> l) => s + l.length,
      ),
      'pendingOrders': pending,
      'revenue': revenue,
    });
  }

  ApiResponse _blockUser(String id, Map<String, dynamic> payload) {
    _requireAdmin();
    final Map<String, dynamic>? user = _users[id];
    if (user == null) return _notFound('User not found.');
    final bool blocked = _bool(payload['is_blocked'], fallback: true);
    user['isBlocked'] = blocked;
    return _ok(user, message: blocked ? 'User blocked.' : 'User unblocked.');
  }

  // ── Helpers ───────────────────────────────

  String _issueToken(String uid) {
    final String token = 'mock.$uid.${DateTime.now().millisecondsSinceEpoch}';
    _sessions[token] = uid;
    return token;
  }

  /// Resolves a bearer token to a user id.
  ///
  /// Tokens issued by the mock have the shape `mock.<uid>.<timestamp>`, so a
  /// session survives an app restart (the token is restored from secure
  /// storage while the in-memory session table is gone).
  String? _uidFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final String? session = _sessions[token];
    if (session != null) return session;
    final List<String> parts = token.split('.');
    if (parts.length >= 3 && parts[0] == 'mock') {
      final String uid = parts[1];
      if (_users.containsKey(uid)) return uid;
    }
    return null;
  }

  String? _uidForEmail(String email) {
    for (final Map<String, dynamic> user in _users.values) {
      if (user['email'] == email) return user['uid'] as String;
    }
    return null;
  }

  String _requireUser() {
    final String? uid = _sessionUid;
    if (uid == null) {
      throw const UnauthenticatedException();
    }
    return uid;
  }

  void _requireAdmin() {
    final String uid = _requireUser();
    if (_users[uid]?['role'] != 'admin') {
      throw const AccountBlockedException(
        'Administrator access is required for this action.',
      );
    }
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> items, String id) {
    for (final Map<String, dynamic> item in items) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  String _lastSegment(String path) => path.split('/').last;

  /// Every review in the store, newest first.
  List<Map<String, dynamic>> _allReviews() {
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    for (final List<Map<String, dynamic>> list in _reviews.values) {
      all.addAll(list);
    }
    all.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final String ta = _str(a['createdAt']);
      final String tb = _str(b['createdAt']);
      return tb.compareTo(ta);
    });
    return all;
  }

  String _bookIdFromReviews(String path) =>
      path.split('/')[ApiConstants.books.split('/').length];

  String _reviewId(String path) {
    final List<String> parts = path.split('/');
    // /reviews/{id} or /reviews/{id}/like
    return parts[parts.length - (path.endsWith('/like') ? 2 : 1)];
  }

  String _orderIdFromCancel(String path) => path.split('/')[2];

  String _orderIdFromStatus(String path) => path.split('/')[3];

  String _notificationId(String path) => path.split('/')[2];

  String _userIdFromBlock(String path) => path.split('/')[3];

  static String _str(Object? value) => (value ?? '').toString().trim();

  static int _int(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _bool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final String v = value.toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return fallback;
  }

  static bool _isEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  // ── Envelope helpers ──────────────────────

  ApiResponse _ok(dynamic data, {String message = 'Success'}) {
    return ApiResponse(success: true, message: message, data: _toJson(data));
  }

  ApiResponse _notFound(String message) {
    throw ServerException(message, 'not-found');
  }

  ApiResponse _paginate(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> query,
  ) {
    final int perPage = _int(query['per_page'], fallback: 20);
    final int currentPage = _int(query['page'], fallback: 1).clamp(1, 1 << 30);
    final int total = items.length;
    final int lastPage = perPage <= 0
        ? 1
        : ((total + perPage - 1) ~/ perPage).clamp(1, 1 << 30);
    final int start = (currentPage - 1) * perPage;
    final int end = (start + perPage).clamp(0, total);

    return ApiResponse(
      success: true,
      message: 'Success',
      data: _toJson(items.sublist(start.clamp(0, total), end)),
      meta: ApiMeta(
        currentPage: currentPage,
        lastPage: lastPage,
        perPage: perPage,
        total: total,
        from: total == 0 ? null : start + 1,
        to: total == 0 ? null : end,
      ),
    );
  }

  /// Converts a payload to `snake_case` JSON, exactly like a Laravel Eloquent
  /// serialisation would.
  static dynamic _toJson(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (dynamic key, dynamic v) =>
            MapEntry<String, dynamic>(_toSnake(key.toString()), _toJson(v)),
      );
    }
    if (value is List) {
      return value.map(_toJson).toList();
    }
    return value;
  }

  static String _toSnake(String key) {
    return key.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (Match m) => '${m[1]}_${m[2]!.toLowerCase()}',
    );
  }

  /// Converts a `snake_case` request key to the mock's internal `camelCase`
  /// row key (`cover_image` -> `coverImage`).
  ///
  /// Request bodies follow the Laravel contract (`snake_case`), while the
  /// mock keeps its rows in `camelCase` and converts them back with
  /// [_toJson] when it builds a response.
  static String _toCamel(String key) {
    if (!key.contains('_')) return key;
    final List<String> parts = key
        .split('_')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return key;
    final StringBuffer buffer = StringBuffer(parts.first);
    for (int i = 1; i < parts.length; i++) {
      final String part = parts[i];
      buffer
        ..write(part[0].toUpperCase())
        ..write(part.substring(1));
    }
    return buffer.toString();
  }

  /// Rewrites the keys of an incoming request body to the mock's internal
  /// `camelCase` row format.
  static Map<String, dynamic> _toCamelKeys(Map<String, dynamic> payload) {
    final Map<String, dynamic> out = <String, dynamic>{};
    payload.forEach((String key, dynamic value) {
      out[_toCamel(key)] = value;
    });
    return out;
  }
}

/// Small helper so the mock can find the first matching element.
extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
