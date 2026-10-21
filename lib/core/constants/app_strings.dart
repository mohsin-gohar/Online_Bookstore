/// All user-facing strings for the **Folio** app live here.
///
/// Centralising copy keeps widgets free of hard-coded text and makes future
/// localisation (e.g. wrapping these in `l10n`) a mechanical change.
class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────
  static const String appName = 'Folio';
  static const String appTagline = 'Curated reads, delivered to your door.';
  static const String appFailedToStart = 'Folio could not start';

  // ── Onboarding ─────────────────────────
  static const String onboardingTitle1 = 'A Library in Your Pocket';
  static const String onboardingBody1 =
      'Browse fiction, non-fiction, academic titles and comics — all picked '
      'for you in one place.';
  static const String onboardingTitle2 = 'Find It in a Few Taps';
  static const String onboardingBody2 =
      'Search by title, author or genre, then narrow the shelf by price, '
      'rating and availability.';
  static const String onboardingTitle3 = 'From Shelf to Doorstep';
  static const String onboardingBody3 =
      'Fill your basket, check out in moments and follow every order from '
      'the press to your front door.';
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String getStarted = 'Get Started';

  // ── Auth ───────────────────────────────
  static const String login = 'Login';
  static const String register = 'Register';
  static const String signUp = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String phone = 'Phone Number';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String sendResetLink = 'Send Reset Link';
  static const String continueWithGoogle = 'Continue with Google';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String welcomeBack = 'Welcome back.';
  static const String createAccount = 'Create your account';
  static const String loginSubtitle = 'Sign in to pick up where you left off.';
  static const String registerSubtitle =
      'Join Folio and start building your shelf.';
  static const String resetSent = 'Password reset link sent. Check your inbox.';
  static const String orContinueWith = 'or continue with';
  static const String welcomeBackToast = 'Welcome back!';
  static const String accountCreated = 'Account created. Welcome to Folio!';
  static const String googleSignedIn = 'Signed in with Google';
  static const String backToLogin = 'Back to Login';

  // ── Navigation / Tabs ──────────────────
  static const String home = 'Home';
  static const String catalog = 'Catalog';
  static const String cart = 'Cart';
  static const String profile = 'Profile';
  static const String wishlist = 'Wishlist';
  static const String orders = 'My Orders';
  static const String notifications = 'Notifications';
  static const String dashboard = 'Dashboard';

  // ── Home ───────────────────────────────
  static const String categories = 'Categories';
  static const String bestsellers = 'Bestsellers';
  static const String newArrivals = 'New Arrivals';
  static const String seeAll = 'See All';
  static const String searchHint = 'Search books, authors, genres…';

  // ── Catalog / Filters ──────────────────
  static const String filters = 'Filters';
  static const String sortBy = 'Sort By';
  static const String priceRange = 'Price Range';
  static const String rating = 'Rating';
  static const String apply = 'Apply';
  static const String reset = 'Reset';
  static const String clearAll = 'Clear All';

  // ── Book details ───────────────────────
  static const String description = 'Description';
  static const String reviews = 'Reviews';
  static const String writeReview = 'Write a Review';
  static const String addToCart = 'Add to Cart';
  static const String buyNow = 'Buy Now';
  static const String inStock = 'In Stock';
  static const String outOfStock = 'Out of Stock';
  static const String relatedBooks = 'You may also like';

  // ── Cart / Checkout ────────────────────
  static const String subtotal = 'Subtotal';
  static const String shipping = 'Shipping';
  static const String total = 'Total';
  static const String checkout = 'Checkout';
  static const String placeOrder = 'Place Order';
  static const String orderSuccess = 'Order Placed Successfully!';
  static const String emptyCart = 'Your cart is empty';
  static const String emptyCartBody = 'Add some books to get started.';

  // ── Orders ─────────────────────────────
  static const String orderId = 'Order ID';
  static const String orderDate = 'Order Date';
  static const String deliveryDate = 'Expected Delivery';
  static const String trackOrder = 'Track Order';
  static const String orderDetails = 'Order Details';
  static const String emptyOrders = 'No orders yet';
  static const String emptyOrdersBody = 'Your placed orders will appear here.';

  // ── Profile ────────────────────────────
  static const String editProfile = 'Edit Profile';
  static const String addresses = 'My Addresses';
  static const String paymentMethods = 'Payment Methods';
  static const String settings = 'Settings';
  static const String darkMode = 'Dark Mode';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String confirm = 'Confirm';

  // ── Admin ──────────────────────────────
  static const String adminDashboard = 'Admin Dashboard';
  static const String manageBooks = 'Manage Books';
  static const String manageCategories = 'Manage Categories';
  static const String manageOrders = 'Manage Orders';
  static const String manageUsers = 'Manage Users';
  static const String revenue = 'Revenue';
  static const String view = 'View';
  static const String viewInStore = 'View on Store';
  static const String viewApp = 'View App';

  // ── Messages ───────────────────────────
  static const String loading = 'Loading…';
  static const String somethingWentWrong =
      'Something went wrong. Please try again.';
  static const String noInternet = 'No internet connection.';
  static const String logoutConfirm = 'Are you sure you want to logout?';

  // ── Empty states ───────────────────────
  static const String emptyWishlist = 'Your wishlist is empty';
  static const String emptyWishlistBody =
      'Tap the heart on a book to save it here.';
  static const String emptySearch = 'No results found';
  static const String emptySearchBody = 'Try adjusting your search or filters.';
}
