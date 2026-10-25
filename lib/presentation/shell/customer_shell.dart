import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../logic/auth_provider.dart';
import '../../logic/cart_provider.dart';

/// The customer area's scaffold: a 4-tab bottom navigation bar
/// ([Home] [Catalog] [Cart] [Profile]).
///
/// Used as the `builder` of a [StatefulShellRoute] so each tab keeps its own
/// navigation stack and scroll position while switching. The Cart tab shows a
/// live badge driven by [CartProvider].
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.navigationShell});

  /// The shell's navigation controller (provided by StatefulShellRoute).
  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    // The trailing admin tab (index 4) isn't a shell branch — it jumps to the
    // admin dashboard, outside the customer shell.
    if (index == 4) {
      context.go(AppRoutes.adminDashboardPath);
      return;
    }
    // `initialLocation: true` re-taps a tab to pop it back to its root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Live cart count for the badge.
    final cartCount = context.select<CartProvider, int>((c) => c.itemCount);
    // Admins get an extra Dashboard tab to hop into the admin area.
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppStrings.home,
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: AppStrings.catalog,
          ),
          NavigationDestination(
            icon: _CartIcon(count: cartCount, filled: false),
            selectedIcon: _CartIcon(count: cartCount, filled: true),
            label: AppStrings.cart,
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: AppStrings.profile,
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded),
              label: AppStrings.dashboard,
            ),
        ],
      ),
    );
  }
}

/// Cart tab icon with a live count badge.
class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, required this.filled});

  final int count;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      filled ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined,
    );
    if (count <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
