import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../logic/auth_provider.dart';
import '../../logic/order_provider.dart';
import '../../logic/profile_provider.dart';
import '../../logic/theme_provider.dart';
import '../../logic/wishlist_provider.dart';
import 'orders/widgets/order_status_chip.dart';

/// Luxury Profile Screen matching Screen 5 in reference design.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0; // 0 = My Orders, 1 = Wishlist

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().uid;
      if (uid != null) {
        context.read<OrderProvider>().loadUserOrders(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final user = auth.user;

    if (!auth.isAuthenticated || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.profile)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 64,
                  color: AppColors.accent,
                ),
                Gaps.md,
                Text(
                  'You are not signed in',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Gaps.md,
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.loginPath),
                    child: const Text(AppStrings.login),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final orders = context.watch<OrderProvider>().orders;
    final wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.accent),
          onPressed: () => context.push(AppRoutes.editProfilePath),
        ),
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded, color: AppColors.accent),
            onPressed: () => context.push(AppRoutes.editProfilePath),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // ── User Header with Gold Ring Border ──
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.darkSurfaceVariant,
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(user.photoUrl)
                        : null,
                    child: user.photoUrl.isEmpty
                        ? Text(
                            user.initial,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                          )
                        : null,
                  ),
                ),
                Gaps.sm,
                Text(
                  user.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(user.email, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Gaps.lg,

          // ── Tab Switcher: "My Orders" | "Wishlist" ──
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _selectedTab = 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTab == 0
                        ? AppColors.accent
                        : AppColors.darkSurfaceVariant,
                    foregroundColor: _selectedTab == 0
                        ? AppColors.brandDark
                        : AppColors.grey300,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                  child: const Text(
                    'My Orders',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Gaps.hSm,
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _selectedTab = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTab == 1
                        ? AppColors.accent
                        : AppColors.darkSurfaceVariant,
                    foregroundColor: _selectedTab == 1
                        ? AppColors.brandDark
                        : AppColors.grey300,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                  child: Text(
                    'Wishlist (${wishlist.count})',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          Gaps.lg,

          // ── Tab 0: Orders Table ──
          if (_selectedTab == 0) ...[
            if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Center(
                  child: Text(
                    'No orders placed yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
            else
              Card(
                color: AppColors.darkSurface,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      color: AppColors.darkSurfaceVariant,
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Order #',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Date',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...orders
                        .take(5)
                        .map(
                          (o) => InkWell(
                            onTap: () =>
                                context.push(AppRoutes.orderDetails(o.id)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.darkSurfaceVariant,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      Formatters.orderNumber(o.id),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      o.orderDate != null
                                          ? Formatters.date(o.orderDate!)
                                          : 'Recent',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: OrderStatusChip(
                                      status: o.status,
                                      dense: true,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      Formatters.price(o.total),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
          ] else ...[
            // Tab 1: Wishlist Link
            ListTile(
              leading: const Icon(
                Icons.favorite_rounded,
                color: AppColors.accent,
              ),
              title: const Text('View Wishlist Items'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.wishlistPath),
            ),
          ],
          Gaps.lg,

          // ── Preferences / Settings Menu ──
          _MenuSection(
            children: [
              _MenuItem(
                icon: Icons.location_on_outlined,
                title: AppStrings.addresses,
                trailing: '${profile.addresses.length}',
                onTap: () => context.push(AppRoutes.addressesPath),
              ),
              _MenuItem(
                icon: Icons.credit_card_rounded,
                title: AppStrings.paymentMethods,
                trailing: '${profile.paymentMethods.length}',
                onTap: () => context.push(AppRoutes.paymentsPath),
              ),
              _MenuItem(
                icon: Icons.notifications_none_rounded,
                title: AppStrings.notifications,
                onTap: () => context.push(AppRoutes.notificationsPath),
              ),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help Center & FAQs',
                onTap: () => context.push(AppRoutes.faqPath),
              ),
            ],
          ),
          Gaps.md,

          _MenuSection(children: [const _DarkModeToggle()]),
          Gaps.md,

          if (auth.isAdmin)
            _MenuSection(
              children: [
                _MenuItem(
                  icon: Icons.admin_panel_settings_outlined,
                  title: AppStrings.adminDashboard,
                  onTap: () => context.go(AppRoutes.adminDashboardPath),
                ),
              ],
            ),
          if (auth.isAdmin) Gaps.md,

          _MenuSection(
            children: [
              _MenuItem(
                icon: Icons.logout_rounded,
                title: AppStrings.logout,
                danger: true,
                onTap: () => _logout(context),
              ),
            ],
          ),
          Gaps.xl,
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.accent;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: danger ? AppColors.danger : null),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _DarkModeToggle extends StatelessWidget {
  const _DarkModeToggle();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return SwitchListTile(
      secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.accent),
      title: const Text(AppStrings.darkMode),
      activeThumbColor: AppColors.accent,
      value: themeProvider.isDarkMode,
      onChanged: (v) => context.read<ThemeProvider>().toggleDarkMode(v),
    );
  }
}
