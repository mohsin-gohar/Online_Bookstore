import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/api_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_pages.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/author_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/book_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/repositories/support_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/wishlist_repository.dart';
import 'data/services/api_factory.dart';
import 'logic/auth_provider.dart';
import 'logic/book_provider.dart';
import 'logic/cart_provider.dart';
import 'logic/notification_provider.dart';
import 'logic/order_provider.dart';
import 'logic/profile_provider.dart';
import 'logic/review_provider.dart';
import 'logic/theme_provider.dart';
import 'logic/wishlist_provider.dart';
import 'presentation/common_widgets/user_session_sync.dart';

/// Root widget of the Book Store app.
///
/// Wires up:
///  • Global providers via [MultiProvider] (local storage + theme).
///  • `MaterialApp.router` bound to the [AppPages.router] GoRouter instance.
///  • Light/dark Material 3 themes.
///
/// The data layer talks to a single [ApiTransport]: the Laravel REST API, or
/// the bundled in-memory mock (see `ApiConstants.useMockMode`).
class BookStoreApp extends StatelessWidget {
  const BookStoreApp({super.key, required this.localStorage});

  final LocalStorageService localStorage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Expose the already-initialised storage instance app-wide.
        Provider<LocalStorageService>.value(value: localStorage),

        // ── Repositories ──
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<BookRepository>(create: (_) => BookRepository()),
        Provider<CategoryRepository>(create: (_) => CategoryRepository()),
        Provider<AuthorRepository>(create: (_) => AuthorRepository()),
        Provider<CartRepository>(create: (_) => CartRepository()),
        Provider<WishlistRepository>(create: (_) => WishlistRepository()),
        Provider<OrderRepository>(create: (_) => OrderRepository()),
        Provider<ReviewRepository>(
          create: (ctx) =>
              ReviewRepository(bookRepository: ctx.read<BookRepository>()),
        ),
        Provider<NotificationRepository>(
          create: (_) => NotificationRepository(),
        ),
        Provider<AccountRepository>(create: (_) => AccountRepository()),
        Provider<SupportRepository>(create: (_) => SupportRepository()),

        // ── Auth state (login/register/role) ──
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(
            repository: ctx.read<AuthRepository>(),
            storage: localStorage,
          ),
        ),

        // ── Catalog / cart / wishlist / orders / reviews ──
        ChangeNotifierProvider<BookProvider>(
          create: (ctx) => BookProvider(
            bookRepository: ctx.read<BookRepository>(),
            categoryRepository: ctx.read<CategoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (ctx) => CartProvider(repository: ctx.read<CartRepository>()),
        ),
        ChangeNotifierProvider<WishlistProvider>(
          create: (ctx) =>
              WishlistProvider(repository: ctx.read<WishlistRepository>()),
        ),
        ChangeNotifierProvider<ReviewProvider>(
          create: (ctx) =>
              ReviewProvider(repository: ctx.read<ReviewRepository>()),
        ),
        // NotificationProvider must sit above OrderProvider: the proxy below
        // resolves it from the enclosing scope at create/update time.
        ChangeNotifierProvider<NotificationProvider>(
          create: (ctx) => NotificationProvider(
            repository: ctx.read<NotificationRepository>(),
          ),
        ),
        // OrderProvider depends on NotificationProvider so an admin status
        // change can raise a customer notification.
        ChangeNotifierProxyProvider<NotificationProvider, OrderProvider>(
          create: (ctx) =>
              OrderProvider(repository: ctx.read<OrderRepository>()),
          update: (ctx, notifications, orders) {
            final provider =
                orders ??
                OrderProvider(repository: ctx.read<OrderRepository>());
            provider.onStatusChanged = (order, previous, next) {
              // Notify the order's owner about the new status.
              notifications.push(
                userId: order.userId,
                title: 'Order ${next.label}',
                message:
                    'Your order ${order.id} is now ${next.label.toLowerCase()}.',
                type: 'order',
                orderId: order.id,
              );
            };
            return provider;
          },
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (ctx) =>
              ProfileProvider(repository: ctx.read<UserRepository>()),
        ),

        // Theme mode (light/dark/system) with persistence.
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(localStorage),
        ),

        // ── Router ──────────────────────────────
        // We create the router here so it can listen to AuthProvider.
        ProxyProvider2<AuthProvider, LocalStorageService, GoRouter>(
          update: (ctx, auth, storage, previous) =>
              previous ?? AppPages.createRouter(auth, storage),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Rebuild MaterialApp when the theme mode changes.
          final themeMode = context.watch<ThemeProvider>().themeMode;
          final router = context.read<GoRouter>();

          return _SessionBootstrap(
            child: UserSessionSync(
              child: MaterialApp.router(
                title: AppStrings.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                routerConfig: router,
                // Expose the active backend so the profile screen can say
                // whether the app is talking to a live server.
                builder: (context, child) => child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Restores the stored session on every launch.
///
/// The splash screen does this too, but a deep-link reload starts directly on
/// the target route, so the root must guarantee it happens.
class _SessionBootstrap extends StatefulWidget {
  const _SessionBootstrap({required this.child});

  final Widget child;

  @override
  State<_SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends State<_SessionBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shows the active backend mode in the profile screen.
String get backendModeLabel => ApiConstants.modeLabel;

/// Lets the app sign the user out when the API rejects the stored token.
void configureSessionExpiryHandler(void Function() onExpired) {
  ApiFactory.onUnauthorized = onExpired;
}
