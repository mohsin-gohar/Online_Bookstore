import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/services/sample_data_service.dart';
import '../../logic/auth_provider.dart';
import '../../logic/book_provider.dart';
import '../../logic/order_provider.dart';

/// Admin dashboard: key stats + navigation to management screens.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _bookCount = 0;
  int _orderCount = 0;
  int _pendingCount = 0;
  double _revenue = 0;
  bool _loading = true;
  bool _statsFailed = false;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _statsFailed = false;
    });
    final orders = context.read<OrderProvider>();
    final books = context.read<BookProvider>();

    try {
      final results = await Future.wait([
        books.countBooks(),
        orders.countOrders(),
        orders.countByStatus(OrderStatus.pending),
        orders.getTotalRevenue(),
      ]);
      if (!mounted) return;
      setState(() {
        _bookCount = results[0] as int;
        _orderCount = results[1] as int;
        _pendingCount = results[2] as int;
        _revenue = results[3] as double;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _statsFailed = true);
        SnackbarHelper.showError(
          context,
          'Could not load dashboard statistics.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seed() async {
    if (_seeding || !context.read<AuthProvider>().isAdmin) return;
    // Lock before the dialog as well, so repeated taps cannot start two jobs.
    setState(() => _seeding = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Seed sample data?'),
          content: const Text(
            'Add missing sample books and categories to the catalogue? '
            'Existing records will not be overwritten. Use this for development only.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add sample data'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      if (!context.read<AuthProvider>().isAdmin) return;
      final books = context.read<BookProvider>();
      final count = await SampleDataService(
        categoryRepository: context.read<CategoryRepository>(),
        bookRepository: context.read<BookRepository>(),
      ).seedAll();
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, '$count sample books added.');
      await Future.wait([
        _loadStats(),
        books.refreshHome(),
        books.loadCatalog(),
      ]);
    } catch (_) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Could not finish sample-data setup. Check your connection and admin '
          'permissions, then retry. Existing records will be preserved.',
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  /// Confirms, then signs the admin out.
  ///
  /// The previous implementation called `context.go(loginPath)` right after
  /// `logout()` — when sign-out failed (or was still in flight) the user was
  /// still authenticated, so the router's redirect bounced them straight back
  /// here and the button looked dead. Now:
  ///  • a confirm dialog prevents accidental sign-outs,
  ///  • a failed sign-out surfaces an error instead of navigating,
  ///  • a successful sign-out is picked up reactively by GoRouter (we keep a
  ///    `go(login)` safety-net for the rare case the redirect lags).
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final signedOut = await context.read<AuthProvider>().logout();
    if (!signedOut) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Logout failed. Please try again.');
      }
      return;
    }
    if (mounted) context.go(AppRoutes.loginPath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminDashboard),
        actions: [
          IconButton(
            tooltip: AppStrings.viewApp,
            onPressed: () => context.go(AppRoutes.homePath),
            icon: const Icon(Icons.storefront_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            // ── Revenue hero ──
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                      ),
                      Gaps.hXs,
                      Text(
                        'Total Revenue',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  Gaps.xs,
                  Text(
                    _loading || _statsFailed
                        ? '—'
                        : Formatters.price(_revenue),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Gaps.md,

            // ── Stat grid ──
            GridView.extent(
              maxCrossAxisExtent: 240,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSizes.sm,
              mainAxisSpacing: AppSizes.sm,
              childAspectRatio: 1.7,
              children: [
                _StatCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Books',
                  value: _loading || _statsFailed ? '—' : '$_bookCount',
                  color: AppColors.info,
                ),
                _StatCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  value: _loading || _statsFailed ? '—' : '$_orderCount',
                  color: AppColors.accent,
                ),
                _StatCard(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Pending',
                  value: _loading || _statsFailed ? '—' : '$_pendingCount',
                  color: AppColors.statusPending,
                ),
                _StatCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Users',
                  value: 'Manage',
                  color: AppColors.verified,
                  onTap: () => context.push(AppRoutes.adminUsersPath),
                ),
              ],
            ),
            Gaps.lg,

            // ── Management links ──
            Text(
              'Manage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Gaps.xs,
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _AdminTile(
                    icon: Icons.menu_book_rounded,
                    title: AppStrings.manageBooks,
                    onTap: () => context.push(AppRoutes.adminBooksPath),
                  ),
                  const Divider(height: 1),
                  _AdminTile(
                    icon: Icons.category_rounded,
                    title: AppStrings.manageCategories,
                    onTap: () => context.push(AppRoutes.adminCategoriesPath),
                  ),
                  const Divider(height: 1),
                  _AdminTile(
                    icon: Icons.receipt_long_rounded,
                    title: AppStrings.manageOrders,
                    onTap: () => context.push(AppRoutes.adminOrdersPath),
                  ),
                  const Divider(height: 1),
                  _AdminTile(
                    icon: Icons.people_alt_rounded,
                    title: AppStrings.manageUsers,
                    onTap: () => context.push(AppRoutes.adminUsersPath),
                  ),
                  const Divider(height: 1),
                  _AdminTile(
                    icon: Icons.storefront_rounded,
                    title: AppStrings.viewApp,
                    onTap: () => context.go(AppRoutes.homePath),
                  ),
                  const Divider(height: 1),
                  _AdminTile(
                    icon: Icons.auto_fix_high_rounded,
                    title: _seeding
                        ? 'Setting up sample data…'
                        : 'Seed Sample Data',
                    onTap: _seeding ? null : _seed,
                  ),
                  if (context.watch<AuthProvider>().isAdmin) ...[
                    const Divider(height: 1),
                    _AdminTile(
                      icon: Icons.logout_rounded,
                      title: AppStrings.logout,
                      danger: true,
                      onTap: _logout,
                    ),
                  ],
                ],
              ),
            ),
            Gaps.xxl,
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: danger ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
