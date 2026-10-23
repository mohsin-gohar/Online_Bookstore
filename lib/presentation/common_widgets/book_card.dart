import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/book_model.dart';
import 'book_cover_image.dart';

/// Layout variants for [BookCard].
enum BookCardLayout {
  /// Vertical card for grids / horizontal carousels (cover on top).
  grid,

  /// Wide card with the cover on the left (search results, related lists).
  list,
}

/// The primary, reusable book tile.
///
/// Shows cover, title, author, rating and price. Handles the shimmer/loading
/// state of the cover image and a tap-to-open callback. The cover participates
/// in a Hero animation keyed by the book id so it morphs into the details
/// screen (the details screen uses the same [heroTag]).
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.layout = BookCardLayout.grid,
    this.width = AppSizes.coverWidth,
    this.isWishlisted = false,
    this.onToggleWishlist,
    this.showWishlistButton = true,
  });

  final BookModel book;
  final VoidCallback onTap;
  final BookCardLayout layout;
  final double width;
  final bool isWishlisted;
  final VoidCallback? onToggleWishlist;
  final bool showWishlistButton;

  /// Stable hero tag shared with the details screen.
  static String heroTag(String bookId) => 'book-cover-$bookId';

  @override
  Widget build(BuildContext context) {
    return layout == BookCardLayout.grid
        ? _buildGrid(context)
        : _buildList(context);
  }

  // ── Grid layout ───────────────────────────

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);

    // Responsive cover sizing. Grid tiles and horizontal carousels give this
    // card a bounded height: the cover then fills exactly the space left
    // below the text block (Expanded + StackFit.expand), so the image always
    // stays inside the card on any screen size — even when `width` is
    // unbounded (grids pass double.infinity, which used to produce an
    // infinite cover height and made the image spill out of the card).
    // When the height itself is unbounded (card dropped into a plain scroll
    // view), fall back to the classic 2:3 aspect cover sized from the width.
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final fallbackWidth = width.isFinite ? width : AppSizes.coverWidth;

        final cover = hasBoundedHeight
            ? _Cover(book: book, heroTag: heroTag(book.id))
            : _Cover(
                book: book,
                width: fallbackWidth,
                height: fallbackWidth / AppSizes.coverAspect,
                heroTag: heroTag(book.id),
              );

        final coverArea = Stack(
          fit: hasBoundedHeight ? StackFit.expand : StackFit.loose,
          clipBehavior: Clip.none,
          children: [
            cover,
            if (book.isBestseller || book.isNewArrival)
              Positioned(
                top: AppSizes.xs,
                left: AppSizes.xs,
                child: _Badge(
                  label: book.isBestseller ? 'Bestseller' : 'New',
                  color: book.isBestseller ? AppColors.brand : AppColors.accent,
                ),
              ),
            if (book.isOutOfStock)
              Positioned(
                bottom: AppSizes.xs,
                left: AppSizes.xs,
                child: _Badge(label: 'Out of stock', color: AppColors.grey800),
              ),
            if (showWishlistButton)
              Positioned(
                top: 0,
                right: 0,
                child: _WishlistButton(
                  isWishlisted: isWishlisted,
                  onPressed: onToggleWishlist,
                ),
              ),
          ],
        );

        return SizedBox(
          width: width,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBoundedHeight) Expanded(child: coverArea) else coverArea,
                Gaps.xs,
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                Gaps.xxs,
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                Gaps.xxs,
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.rating,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      book.ratingLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Flexible + ellipsis so a long price can never overflow the
                    // narrow (130px) grid card.
                    Flexible(
                      child: Text(
                        book.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── List layout ───────────────────────────

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    const coverW = 76.0;
    final coverH = coverW / AppSizes.coverAspect;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(
              book: book,
              width: coverW,
              height: coverH,
              heroTag: heroTag(book.id),
            ),
            Gaps.hSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gaps.xxs,
                  Text(book.author, style: theme.textTheme.bodySmall),
                  Gaps.xxs,
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.rating,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${book.ratingLabel} (${book.reviewCount})',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  Gaps.xxs,
                  Text(
                    book.priceLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isWishlisted
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isWishlisted ? AppColors.danger : null,
              ),
              onPressed: onToggleWishlist,
            ),
          ],
        ),
      ),
    );
  }
}

/// The book cover with loading/error handling and a Hero wrapper.
///
/// When [width] and [height] are given the cover takes that fixed size; when
/// they are null the cover fills whatever space its parent gives it (used
/// inside grid tiles where the tile drives the card's height).
class _Cover extends StatelessWidget {
  const _Cover({
    required this.book,
    required this.heroTag,
    this.width,
    this.height,
  });

  final BookModel book;
  final double? width;
  final double? height;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final cover = BookCoverImage(
      imageUrl: book.coverImage,
      title: book.title,
      author: book.author,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      heroTag: heroTag,
    );

    if (width == null || height == null) {
      return SizedBox.expand(child: cover);
    }
    return cover;
  }
}

/// Small pill badge ("Bestseller", "New", "Out of stock").
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Heart toggle shown over the cover in grid layout.
class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.isWishlisted, required this.onPressed});

  final bool isWishlisted;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              isWishlisted
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 18,
              color: isWishlisted ? AppColors.danger : null,
            ),
          ),
        ),
      ),
    );
  }
}
