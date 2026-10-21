import 'package:flutter/material.dart';

import 'cart_badge_button.dart';

/// A themed, reusable app bar for customer screens.
///
/// Adds sensible defaults (no elevation, transparent surface, optional back
/// button) and can append the [CartBadgeButton] automatically.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.showCart = true,
    this.bottom,
    this.titleWidget,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final bool showCart;
  final PreferredSizeWidget? bottom;

  /// Optional custom title widget (overrides [title] when provided).
  final Widget? titleWidget;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      title: titleWidget ?? Text(title),
      bottom: bottom,
      actions: [...?actions, if (showCart) const CartBadgeButton()],
    );
  }
}
