import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/wishlist_item_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/book_provider.dart';
import '../../logic/cart_provider.dart';
import '../../logic/wishlist_provider.dart';
import '../common_widgets/book_cover_image.dart';
import '../common_widgets/custom_appbar.dart';
import '../common_widgets/empty_state.dart';

/// The Wishlist tab: saved books with "move to cart" and remove actions.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  Future<void> _moveToCart(BuildContext context, WishlistItemModel item) async {
    final books = context.read<BookProvider>();
    final cart = context.read<CartProvider>();
    final wishlist = context.read<WishlistProvider>();

    try {
      // Resolve the full book so we have stock/price for the cart entry.
      final book = await books.getBook(item.bookId);
      if (book == null) {
        if (context.mounted) {
          SnackbarHelper.showError(
            context,
            'This book is no longer available.',
          );
        }
        return;
      }
      if (book.isOutOfStock) {
        if (context.mounted) {
          SnackbarHelper.showWarning(context, 'This book is out of stock.');
        }
        return;
      }
      final ok = await cart.addToCart(book);
      if (!context.mounted) return;
      if (ok) {
        await wishlist.remove(item.bookId);
        if (!context.mounted) return;
        SnackbarHelper.showSuccess(context, 'Moved to cart');
      } else if (cart.error != null) {
        SnackbarHelper.showError(context, cart.error!);
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Could not move to cart.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wishlist = context.watch<WishlistProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: const CustomAppBar(title: AppStrings.wishlist, showCart: false),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Log in to see your wishlist',
          message: 'Save books you love and find them here later.',
          actionLabel: AppStrings.login,
          onAction: () => context.go(AppRoutes.loginPath),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.wishlist, showCart: true),
      body: wishlist.isLoading && wishlist.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : wishlist.items.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: AppStrings.emptyWishlist,
              message: AppStrings.emptyWishlistBody,
              actionLabel: 'Browse books',
              onAction: () => context.go(AppRoutes.catalogPath),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: wishlist.items.length,
              separatorBuilder: (_, _) => const Divider(height: AppSizes.lg),
              itemBuilder: (context, i) {
                final item = wishlist.items[i];
                return _WishlistRow(
                  item: item,
                  onMoveToCart: () => _moveToCart(context, item),
                  onRemove: () => wishlist.remove(item.bookId),
                );
              },
            ),
    );
  }
}

class _WishlistRow extends StatelessWidget {
  const _WishlistRow({
    required this.item,
    required this.onMoveToCart,
    required this.onRemove,
  });

  final WishlistItemModel item;
  final VoidCallback onMoveToCart;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.bookDetails(item.bookId)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCoverImage(
            imageUrl: item.coverImage,
            title: item.title,
            width: 64,
            height: 96,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          Gaps.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      onPressed: onRemove,
                    ),
                  ],
                ),
                Gaps.xxs,
                Text(
                  Formatters.price(item.price),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.xs,
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onMoveToCart,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text('Move to Cart'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
