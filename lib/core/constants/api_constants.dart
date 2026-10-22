import 'package:flutter/foundation.dart';

/// Centralised configuration for the **Laravel REST API** the app talks to.
///
/// Everything that changes between environments (host, timeouts, feature
/// flags) lives here so no other file has to know about `dart-define`s.
///
/// ## Choosing a backend
///
/// | Mode | How to select | When to use |
/// |------|---------------|-------------|
/// | Mock | `flutter run --dart-define=API_MODE=mock` (default) | No Laravel server available — the app runs off the bundled demo catalogue. |
/// | Live | `flutter run --dart-define=API_MODE=live --dart-define=API_BASE_URL=http://10.0.2.2:8000/api` | A Laravel backend is running. |
///
/// ### Base URLs
///
/// * **Android emulator** → `http://10.0.2.2:8000/api` (the host machine is
///   reachable at `10.0.2.2`).
/// * **iOS simulator** → `http://127.0.0.1:8000/api`.
/// * **Physical device** → your machine's LAN IP, e.g. `http://192.168.1.10:8000/api`.
///   The phone and the computer must be on the same Wi-Fi, and the Laravel
///   server must listen on `0.0.0.0` (`php artisan serve --host=0.0.0.0`).
///
/// Cleartext HTTP is only allowed for the debug/dev hosts listed in
/// `android/app/src/main/AndroidManifest.xml` (`usesCleartextTraffic`).
class ApiConstants {
  ApiConstants._();

  // ── Mode ────────────────────────────────
  /// Which backend the repositories talk to.
  static const String _modeDefine = String.fromEnvironment(
    'API_MODE',
    defaultValue: 'mock',
  );

  /// `true` → the bundled demo catalogue (no server required).
  /// `false` → the Laravel REST API.
  static const bool useMockMode = _modeDefine == 'mock';

  /// Human-readable label for the current mode (shown in the profile screen).
  static const String modeLabel = useMockMode
      ? 'Demo data (no server)'
      : 'Live API';

  // ── Google Sign-In ───────────────────────
  /// The **web** OAuth client id (used on iOS and web).
  ///
  /// Overridable with `--dart-define=GOOGLE_CLIENT_ID=...`.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  /// The **web** OAuth client id used as the server client id on Android.
  ///
  /// Overridable with `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// `true` when at least one Google client id has been supplied.
  ///
  /// Android also accepts the id from `android/app/src/main/res/values/
  /// strings.xml` (`default_web_client_id`), so the check is advisory.
  static bool get hasGoogleClient =>
      googleClientId.isNotEmpty || googleServerClientId.isNotEmpty;

  // ── Base URL ────────────────────────────
  /// Overridable with `--dart-define=API_BASE_URL=...`.
  static const String _baseUrlDefine = String.fromEnvironment('API_BASE_URL');

  /// Default for the current platform when nothing is overridden.
  static String get _platformDefaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000/api'
        : 'http://127.0.0.1:8000/api';
  }

  /// The API root, **without** a trailing slash.
  static String get baseUrl {
    final String raw = _baseUrlDefine.isNotEmpty
        ? _baseUrlDefine
        : _platformDefaultBaseUrl;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  // ── Timeouts ────────────────────────────
  /// TCP + handshake timeout.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Timeout while the server is sending the response body.
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Timeout while uploading a request body (image uploads use a longer one).
  static const Duration sendTimeout = Duration(seconds: 20);

  /// Extra allowance for multipart uploads.
  static const Duration uploadTimeout = Duration(seconds: 60);

  // ── Pagination ──────────────────────────
  /// Default `per_page` value sent to Laravel.
  static const int defaultPerPage = 20;

  /// Page size used by the catalog grid (matches the `maxCrossAxisExtent`
  /// grid layout).
  static const int catalogPerPage = 20;

  // ── Endpoints ───────────────────────────
  // Authentication
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authGoogle = '/auth/google';
  static const String authLogout = '/auth/logout';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authVerifyCode = '/auth/verify-code';
  static const String me = '/me';
  static const String mePassword = '/me/password';

  // Catalog
  static const String categories = '/categories';
  static const String authors = '/authors';
  static const String books = '/books';
  static const String reviews = '/reviews';

  // Shopping
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static const String wishlist = '/wishlist';

  // Account
  static const String addresses = '/addresses';
  static const String paymentMethods = '/payment-methods';
  static const String orders = '/orders';
  static const String notifications = '/notifications';

  // Help
  static const String faqs = '/faqs';
  static const String supportMessages = '/support/messages';
  static const String uploads = '/uploads';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminBooks = '/admin/books';
  static const String adminCategories = '/admin/categories';
  static const String adminAuthors = '/admin/authors';
  static const String adminOrders = '/admin/orders';
  static const String adminUsers = '/admin/users';

  // ── Nested resource paths ───────────────
  /// `/books/{id}`
  static String book(String id) => '$books/$id';

  /// `/authors/{id}`
  static String author(String id) => '$authors/$id';

  /// `/categories/{id}`
  static String category(String id) => '$categories/$id';

  /// `/books/{id}/reviews`
  static String bookReviews(String bookId) => '${book(bookId)}/reviews';

  /// `/reviews/{id}`
  static String review(String id) => '$reviews/$id';

  /// `/reviews/{id}/like`
  static String reviewLike(String id) => '${review(id)}/like';

  /// `/cart/items/{bookId}`
  static String cartItem(String bookId) => '$cartItems/$bookId';

  /// `/wishlist/{bookId}`
  static String wishlistItem(String bookId) => '$wishlist/$bookId';

  /// `/orders/{id}`
  static String order(String id) => '$orders/$id';

  /// `/orders/{id}/cancel`
  static String orderCancel(String id) => '${order(id)}/cancel';

  /// `/addresses/{id}`
  static String address(String id) => '$addresses/$id';

  /// `/payment-methods/{id}`
  static String paymentMethod(String id) => '$paymentMethods/$id';

  /// `/notifications/{id}/read`
  static String notificationRead(String id) => '$notifications/$id/read';

  /// `/notifications/{id}`
  static String notification(String id) => '$notifications/$id';

  /// `/notifications/read-all`
  static const String notificationsReadAll = '$notifications/read-all';

  /// `/admin/orders/{id}/status`
  static String adminOrderStatus(String id) => '$adminOrders/$id/status';

  /// `/admin/users/{id}/block`
  static String adminUserBlock(String id) => '$adminUsers/$id/block';

  /// `/admin/books/{id}`
  static String adminBook(String id) => '$adminBooks/$id';

  /// `/admin/categories/{id}`
  static String adminCategory(String id) => '$adminCategories/$id';

  /// `/admin/authors/{id}`
  static String adminAuthor(String id) => '$adminAuthors/$id';
}
