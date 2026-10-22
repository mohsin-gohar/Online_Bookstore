import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/order_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/cart_provider.dart';
import '../common_widgets/book_cover_image.dart';
import '../common_widgets/empty_state.dart';

/// The Cart / Your Bag screen matching Screen 4 in reference design.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Bag')),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Log in to see your bag',
          message: 'Your bag is saved to your account across devices.',
          actionLabel: AppStrings.login,
          onAction: () => context.go(AppRoutes.loginPath),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Bag'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => _clearCart(context),
              child: const Text(
                'Clear',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
        ],
      ),
      body: cart.isLoading && cart.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your bag is empty',
              message: 'Explore our collection and add your favourite reads.',
              actionLabel: 'Browse books',
              onAction: () => context.go(AppRoutes.catalogPath),
            )
          : _CartBody(items: cart.items, subtotal: cart.subtotal),
    );
  }

  Future<void> _clearCart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear bag?'),
        content: const Text('Remove all items from your bag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<CartProvider>().clearCart();
  }
}

class _CartBody extends StatelessWidget {
  const _CartBody({required this.items, required this.subtotal});

  final List<CartItemModel> items;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final shipping = OrderModel.computeShipping(subtotal);
    final total = subtotal + shipping;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: AppSizes.lg),
            itemBuilder: (context, i) => _CartRow(item: items[i]),
          ),
        ),
        _OrderSummaryCard(subtotal: subtotal, shipping: shipping, total: total),
      ],
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.read<CartProvider>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
        BookCoverImage(
          imageUrl: item.coverImage,
          title: item.title,
          width: 60,
          height: 88,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        Gaps.hMd,

        // Details + Quantity Controller
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gaps.xxs,
              Text(
                Formatters.price(item.price),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gaps.xs,

              // Quantity Stepper (- 1 +)
              Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    onPressed: () => cart.updateQty(item.bookId, item.qty - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.qty}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    onPressed: () => cart.updateQty(item.bookId, item.qty + 1),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Remove button link
        TextButton(
          onPressed: () => cart.removeFromCart(item.bookId),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.danger,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Remove',
            style: TextStyle(
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.brandDark),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.subtotal,
    required this.shipping,
    required this.total,
  });

  final double subtotal;
  final double shipping;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
          border: Border(top: BorderSide(color: AppColors.darkSurfaceVariant)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Gaps.md,
            _row(theme, AppStrings.subtotal, Formatters.price(subtotal)),
            Gaps.xs,
            _row(
              theme,
              AppStrings.shipping,
              shipping == 0 ? 'Free' : Formatters.price(shipping),
            ),
            const Divider(height: AppSizes.lg),
            _row(theme, AppStrings.total, Formatters.price(total), bold: true),
            Gaps.md,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.checkoutPath),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.brandDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: bold
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
