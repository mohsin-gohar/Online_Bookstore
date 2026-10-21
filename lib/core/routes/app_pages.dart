import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/category_model.dart';
import '../../data/models/order_model.dart';
import '../../presentation/auth/forgot_password_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/book_details/book_details_screen.dart';
import '../../presentation/cart/cart_screen.dart';
import '../../presentation/catalog/catalog_screen.dart';
import '../../presentation/catalog/author_books_screen.dart';
import '../../presentation/catalog/category_books_screen.dart';
import '../../presentation/catalog/search_screen.dart';
import '../../presentation/checkout/checkout_screen.dart';
import '../../presentation/checkout/order_success_screen.dart';
import '../../presentation/faq_screen.dart';
import 'admin_guard.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/orders/my_orders_screen.dart';
import '../../presentation/orders/order_details_screen.dart';
import '../../presentation/orders/track_order_screen.dart';
import '../../presentation/addresses_screen.dart';
import '../../presentation/admin/manage_books_screen.dart';
import '../../presentation/admin/manage_categories_screen.dart';
import '../../presentation/admin/manage_orders_screen.dart';
import '../../presentation/admin/manage_users_screen.dart';
import '../../presentation/admin_dashboard_screen.dart';
import '../../presentation/edit_profile_screen.dart';
import '../../presentation/notifications_screen.dart';
import '../../presentation/payments_screen.dart';
import '../../presentation/profile_screen.dart';
import '../../presentation/shell/customer_shell.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/wishlist/wishlist_screen.dart';
import '../services/local_storage_service.dart';
import '../../logic/auth_provider.dart';
import 'app_routes.dart';

/// The app's GoRouter instance.
class AppPages {
  AppPages._();

  /// Creates a [GoRouter] instance that is reactive to [AuthProvider] changes.
  static GoRouter createRouter(
    AuthProvider authProvider,
    LocalStorageService storage,
  ) {
    return GoRouter(
      initialLocation: AppRoutes.splashPath,
      refreshListenable: authProvider,
      debugLogDiagnostics: false,
      redirect: (context, state) => _redirect(state, authProvider, storage),
      routes: <RouteBase>[
        // ── Splash ─────────────────────────────
        GoRoute(
          path: AppRoutes.splashPath,
          name: AppRoutes.splashName,
          builder: (context, state) => const SplashScreen(),
        ),

        // ── Onboarding ─────────────────────────
        GoRoute(
          path: AppRoutes.onboardingPath,
          name: AppRoutes.onboardingName,
          builder: (context, state) => const OnboardingScreen(),
        ),

        // ── Auth ───────────────────────────────
        GoRoute(
          path: AppRoutes.loginPath,
          name: AppRoutes.loginName,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.registerPath,
          name: AppRoutes.registerName,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPasswordPath,
          name: AppRoutes.forgotPasswordName,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // ── Customer shell (4-tab bottom nav) ──
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              CustomerShell(navigationShell: navigationShell),
          branches: [
            // Tab 0 — Home
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.homePath,
                  name: AppRoutes.homeName,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            // Tab 1 — Catalog
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.catalogPath,
                  name: AppRoutes.catalogName,
                  builder: (context, state) => const CatalogScreen(),
                ),
              ],
            ),
            // Tab 2 — Cart
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.cartPath,
                  name: AppRoutes.cartName,
                  builder: (context, state) => const CartScreen(),
                ),
              ],
            ),
            // Tab 3 — Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profilePath,
                  name: AppRoutes.profileName,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Search (pushed over the shell) ─────
        GoRoute(
          path: AppRoutes.searchPath,
          name: AppRoutes.searchName,
          builder: (context, state) => const SearchScreen(),
        ),

        // ── Category books (from the home categories row) ──
        GoRoute(
          path: AppRoutes.categoryPath,
          name: AppRoutes.categoryName,
          builder: (context, state) => CategoryBooksScreen(
            categoryId: state.pathParameters['id'] ?? '',
            category: state.extra is CategoryModel
                ? state.extra! as CategoryModel
                : null,
          ),
        ),

        // ── Author books ───────────────────────
        GoRoute(
          path: AppRoutes.authorPath,
          name: AppRoutes.authorName,
          builder: (context, state) => AuthorBooksScreen(
            authorName: Uri.decodeComponent(state.pathParameters['name'] ?? ''),
            authorId: state.uri.queryParameters['id'],
          ),
        ),

        // ── Book details ───────────────────────
        GoRoute(
          path: AppRoutes.bookDetailsPath,
          name: AppRoutes.bookDetailsName,
          builder: (context, state) =>
              BookDetailsScreen(bookId: state.pathParameters['id'] ?? ''),
        ),

        // ── Wishlist ───────────────────────────
        GoRoute(
          path: AppRoutes.wishlistPath,
          name: AppRoutes.wishlistName,
          builder: (context, state) => const WishlistScreen(),
        ),

        // ── Orders ─────────────────────────────
        GoRoute(
          path: AppRoutes.ordersPath,
          name: AppRoutes.ordersName,
          builder: (context, state) => const MyOrdersScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: AppRoutes.orderDetailsName,
              builder: (context, state) =>
                  OrderDetailsScreen(orderId: state.pathParameters['id'] ?? ''),
              routes: [
                GoRoute(
                  path: 'track',
                  name: AppRoutes.trackOrderName,
                  builder: (context, state) => TrackOrderScreen(
                    orderId: state.pathParameters['id'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Checkout ───────────────────────────
        GoRoute(
          path: AppRoutes.checkoutPath,
          name: AppRoutes.checkoutName,
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: AppRoutes.orderSuccessPath,
          name: AppRoutes.orderSuccessName,
          builder: (context, state) => OrderSuccessScreen(
            order: state.extra is OrderModel
                ? state.extra! as OrderModel
                : null,
          ),
        ),

        // ── Profile nested ─────────────────────
        GoRoute(
          path: AppRoutes.editProfilePath,
          name: AppRoutes.editProfileName,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.addressesPath,
          name: AppRoutes.addressesName,
          builder: (context, state) => const AddressesScreen(),
        ),
        GoRoute(
          path: AppRoutes.paymentsPath,
          name: AppRoutes.paymentsName,
          builder: (context, state) => const PaymentsScreen(),
        ),
        GoRoute(
          path: AppRoutes.notificationsPath,
          name: AppRoutes.notificationsName,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.faqPath,
          name: AppRoutes.faqName,
          builder: (context, state) => const FaqScreen(),
        ),

        // ── Admin (guarded by AdminGuard) ──────
        GoRoute(
          path: AppRoutes.adminDashboardPath,
          name: AppRoutes.adminDashboardName,
          redirect: AdminGuard.redirect,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminBooksPath,
          name: AppRoutes.adminBooksName,
          redirect: AdminGuard.redirect,
          builder: (context, state) => const ManageBooksScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminCategoriesPath,
          name: AppRoutes.adminCategoriesName,
          redirect: AdminGuard.redirect,
          builder: (context, state) => const ManageCategoriesScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminOrdersPath,
          name: AppRoutes.adminOrdersName,
          redirect: AdminGuard.redirect,
          builder: (context, state) => const ManageOrdersScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminUsersPath,
          name: AppRoutes.adminUsersName,
          redirect: AdminGuard.redirect,
          builder: (context, state) => const ManageUsersScreen(),
        ),
      ],

      // ── 404 ──────────────────
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64),
                const SizedBox(height: 16),
                Text(
                  'No route for ${state.uri}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Global redirection logic based on auth status and current location.
  static String? _redirect(
    GoRouterState state,
    AuthProvider auth,
    LocalStorageService storage,
  ) {
    final status = auth.status;
    final location = state.uri.path;

    // 1. While auth status is unknown, stay on Splash (or wait).
    if (status == AuthStatus.unknown) return null;

    final isLoggingIn =
        location == AppRoutes.loginPath ||
        location == AppRoutes.registerPath ||
        location == AppRoutes.forgotPasswordPath ||
        location == AppRoutes.onboardingPath ||
        location == AppRoutes.splashPath;

    // 2. Not authenticated?
    if (status == AuthStatus.unauthenticated) {
      if (isLoggingIn) return null; // allow auth screens

      // If they haven't seen onboarding, send them there; otherwise login.
      return storage.isOnboardingDone
          ? AppRoutes.loginPath
          : AppRoutes.onboardingPath;
    }

    // 3. Authenticated?
    if (status == AuthStatus.authenticated) {
      // If they are on an auth screen, send them to their home.
      if (isLoggingIn) {
        return auth.isAdmin ? AppRoutes.adminDashboardPath : AppRoutes.homePath;
      }
    }

    return null; // allow navigation
  }
}
