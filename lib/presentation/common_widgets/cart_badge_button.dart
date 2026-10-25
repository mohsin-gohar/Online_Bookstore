import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../logic/cart_provider.dart';

/// A cart icon button with a live item-count badge.
///
/// Used in app bars across the customer flow. Tapping it navigates to the cart
/// tab. The badge reflects `CartProvider.itemCount` and disappears at zero.
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    // Only rebuild when the count changes, not on every cart mutation.
    final count = context.select<CartProvider, int>((c) => c.itemCount);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: 'Cart',
        onPressed: () => context.go(AppRoutes.cartPath),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.shopping_cart_outlined, color: iconColor),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
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
        ),
      ),
    );
  }
}
