import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import 'cart_badge_button.dart';

/// A themed, reusable app bar for customer screens.
///
/// Adds sensible defaults (no elevation, transparent surface, explicit back
/// button with safe fallback to [fallbackRoute] when the stack cannot pop) and
/// can append a Home button and the [CartBadgeButton] automatically.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.showCart = true,
    this.showHome = true,
    this.fallbackRoute = AppRoutes.homePath,
    this.bottom,
    this.titleWidget,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final bool showCart;
  final bool showHome;
  final String fallbackRoute;
  final PreferredSizeWidget? bottom;

  /// Optional custom title widget (overrides [title] when provided).
  final Widget? titleWidget;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => AppNavigator.popOrGo(context, fallbackRoute),
            )
          : null,
      title: titleWidget ?? Text(title),
      bottom: bottom,
      actions: [
        ...?actions,
        if (showHome)
          IconButton(
            tooltip: 'Back to Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go(AppRoutes.homePath),
          ),
        if (showCart) const CartBadgeButton(),
      ],
    );
  }
}
