/// Route path and name constants for the whole app.
///
/// Keeping paths in one place avoids typos and makes refactors safe: change a
/// value here and every `context.go(AppRoutes.x)` follows. Route *names* are
/// used by GoRouter for imperative navigation (`context.goNamed`).
class AppRoutes {
  AppRoutes._();

  // ── Paths ──────────────────────────────
  static const String splashPath = '/';
  static const String onboardingPath = '/onboarding';

  // Auth
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String forgotPasswordPath = '/forgot-password';

  // Customer shell (bottom nav)
  static const String homePath = '/home';
  static const String catalogPath = '/catalog';
  static const String cartPath = '/cart';
  static const String profilePath = '/profile';

  // Catalog nested
  static const String searchPath = '/search';
  static const String categoryPath = '/category/:id'; // books in a category
  static const String authorPath = '/author/:name'; // books by author
  // Book
  static const String bookDetailsPath = '/book/:id'; // `/book/abc123`

  // Wishlist / orders
  static const String wishlistPath = '/wishlist';
  static const String ordersPath = '/orders';
  static const String orderDetailsPath = '/orders/:id';
  static const String trackOrderPath = '/orders/:id/track';

  // Checkout
  static const String checkoutPath = '/checkout';
  static const String orderSuccessPath = '/order-success';

  // Profile nested
  static const String editProfilePath = '/profile/edit';
  static const String addressesPath = '/profile/addresses';
  static const String paymentsPath = '/profile/payments';
  static const String notificationsPath = '/notifications';
  static const String faqPath = '/help-faqs';

  // Admin
  static const String adminDashboardPath = '/admin';
  static const String adminBooksPath = '/admin/books';
  static const String adminCategoriesPath = '/admin/categories';
  static const String adminOrdersPath = '/admin/orders';
  static const String adminUsersPath = '/admin/users';

  // ── Names (for goNamed) ────────────────
  static const String splashName = 'splash';
  static const String onboardingName = 'onboarding';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String forgotPasswordName = 'forgotPassword';
  static const String homeName = 'home';
  static const String catalogName = 'catalog';
  static const String cartName = 'cart';
  static const String profileName = 'profile';
  static const String searchName = 'search';
  static const String categoryName = 'category';
  static const String authorName = 'author';
  static const String bookDetailsName = 'bookDetails';
  static const String wishlistName = 'wishlist';
  static const String ordersName = 'orders';
  static const String orderDetailsName = 'orderDetails';
  static const String trackOrderName = 'trackOrder';
  static const String checkoutName = 'checkout';
  static const String orderSuccessName = 'orderSuccess';
  static const String editProfileName = 'editProfile';
  static const String addressesName = 'addresses';
  static const String paymentsName = 'payments';
  static const String notificationsName = 'notifications';
  static const String faqName = 'faq';
  static const String adminDashboardName = 'adminDashboard';
  static const String adminBooksName = 'adminBooks';
  static const String adminCategoriesName = 'adminCategories';
  static const String adminOrdersName = 'adminOrders';
  static const String adminUsersName = 'adminUsers';

  // ── Helpers ────────────────────────────
  /// Builds a concrete path for a book details route.
  static String bookDetails(String id) => '/book/$id';

  /// Builds a concrete path for a category's books route.
  static String categoryBooks(String id) => '/category/$id';

  /// Builds a concrete path for an author's books route.
  static String authorBooks(String name) =>
      '/author/${Uri.encodeComponent(name)}';

  /// Builds a concrete path for an order details route.
  static String orderDetails(String id) => '/orders/$id';

  /// Builds a concrete path for an order tracking route.
  static String trackOrder(String id) => '/orders/$id/track';
}
