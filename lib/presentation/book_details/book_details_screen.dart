import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/book_model.dart';
import '../../data/models/review_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/book_provider.dart';
import '../../logic/cart_provider.dart';
import '../../logic/review_provider.dart';
import '../../logic/wishlist_provider.dart';
import '../common_widgets/book_card.dart';
import '../common_widgets/error_state.dart';
import '../common_widgets/loading_indicator.dart';
import '../common_widgets/quantity_selector.dart';
import 'widgets/audio_sample_sheet.dart';
import 'widgets/book_sample_reader_sheet.dart';
import 'widgets/review_tile.dart';
import 'widgets/write_review_sheet.dart';

/// Luxury Book details screen matching Screen 3 in reference design.
class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  BookModel? _book;
  bool _loading = true;
  String? _error;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = context.read<BookProvider>();
      final book = await books.getBook(widget.bookId, refresh: true);
      if (!mounted) return;
      setState(() {
        _book = book;
        _loading = false;
        _qty = 1;
      });
      if (book != null) {
        context.read<ReviewProvider>().loadReviews(book.id, refresh: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    final book = _book;
    if (book == null) return;
    if (!context.read<AuthProvider>().isAuthenticated) {
      SnackbarHelper.showWarning(context, 'Please log in to add to cart.');
      return;
    }
    final cart = context.read<CartProvider>();
    final ok = await cart.addToCart(book, qty: _qty);
    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Added $_qty to cart');
    } else if (cart.error != null) {
      SnackbarHelper.showError(context, cart.error!);
    }
  }

  Future<void> _toggleWishlist() async {
    final book = _book;
    if (book == null) return;
    if (!context.read<AuthProvider>().isAuthenticated) {
      SnackbarHelper.showWarning(context, 'Please log in to save books.');
      return;
    }
    final wishlist = context.read<WishlistProvider>();
    final wasSaved = wishlist.contains(book.id);
    final ok = await wishlist.toggle(book);
    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(
        context,
        wasSaved ? 'Removed from wishlist' : 'Added to wishlist',
      );
    } else if (wishlist.error != null) {
      SnackbarHelper.showError(context, wishlist.error!);
    }
  }

  Future<void> _writeReview() async {
    final book = _book;
    final auth = context.read<AuthProvider>();
    if (book == null) return;
    if (!auth.isAuthenticated) {
      SnackbarHelper.showWarning(context, 'Please log in to write a review.');
      return;
    }
    final reviews = context.read<ReviewProvider>();
    final existing = reviews.userReview(book.id, auth.uid!);

    final draft = await WriteReviewSheet.show(
      context,
      initialRating: existing?.rating ?? 0,
      initialComment: existing?.comment ?? '',
    );
    if (draft == null || !mounted) return;

    final user = auth.user!;
    final bool ok;
    if (existing == null) {
      final created = await reviews.addReview(
        bookId: book.id,
        userId: user.uid,
        userName: user.name,
        userPhoto: user.photoUrl,
        rating: draft.rating,
        comment: draft.comment,
      );
      ok = created != null;
    } else {
      ok = await reviews.updateReview(
        existing.copyWith(rating: draft.rating, comment: draft.comment),
      );
    }
    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Thanks for your review!');
      context.read<BookProvider>().getBook(book.id, refresh: true).then((b) {
        if (mounted && b != null) setState(() => _book = b);
      });
    } else if (reviews.error != null) {
      SnackbarHelper.showError(context, reviews.error!);
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete review'),
        content: const Text('Delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final reviews = context.read<ReviewProvider>();
    final ok = await reviews.deleteReview(review.id, review.bookId);
    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Review deleted');
      context.read<BookProvider>().getBook(review.bookId, refresh: true).then((
        b,
      ) {
        if (mounted && b != null) setState(() => _book = b);
      });
    } else if (reviews.error != null) {
      SnackbarHelper.showError(context, reviews.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(), body: const FullScreenLoader());
    }
    if (_error != null || _book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: _error ?? 'This book could not be found.',
          onRetry: _load,
        ),
      );
    }

    final book = _book!;
    final wishlist = context.watch<WishlistProvider>();
    final isWishlisted = wishlist.contains(book.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              SnackbarHelper.showSuccess(context, 'Link copied to clipboard');
            },
          ),
          IconButton(
            tooltip: 'Wishlist',
            onPressed: _toggleWishlist,
            icon: Icon(
              isWishlisted
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isWishlisted ? AppColors.danger : null,
            ),
          ),
          Gaps.hXs,
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Prominent Centered Book Cover ──
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Hero(
                  tag: BookCard.heroTag(book.id),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    child: book.coverImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: book.coverImage,
                            width: 170,
                            height: 250,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              width: 170,
                              height: 250,
                              color: AppColors.darkSurfaceVariant,
                            ),
                          )
                        : Container(
                            width: 170,
                            height: 250,
                            color: AppColors.darkSurfaceVariant,
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 64,
                              color: AppColors.accent,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Gaps.lg,

            // ── Title & Author ──
            Text(
              book.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            Gaps.xs,
            InkWell(
              onTap: () => context.push(AppRoutes.authorBooks(book.author)),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.author,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accent.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    Gaps.xxs,
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
            Gaps.sm,

            // ── Read Sample & Audio Sample Preview ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => BookSampleReaderSheet.show(context, book),
                  icon: const Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  label: const Text(
                    'Read Sample',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                ),
                Gaps.hSm,
                OutlinedButton.icon(
                  onPressed: () => AudioSampleSheet.show(context, book),
                  icon: const Icon(
                    Icons.headphones_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  label: const Text(
                    'Audio Sample',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                ),
              ],
            ),
            if (book.isInStock && book.stock <= 5) ...[
              Gaps.xs,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    Gaps.xxs,
                    Text(
                      'Only ${book.stock} left in stock — order soon',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Gaps.md,

            // ── Synopsis / Description ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Synopsis',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ),
            Gaps.xs,
            Text(
              book.description.isEmpty
                  ? 'No description available for this book yet.'
                  : book.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gaps.lg,

            // ── Metadata Cards (Publisher, Pages, ISBN) ──
            Card(
              color: AppColors.darkSurface,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publisher',
                            style: TextStyle(
                              color: AppColors.grey400,
                              fontSize: 12,
                            ),
                          ),
                          Gaps.xxs,
                          Text(
                            book.publisher.isEmpty
                                ? 'Folio Press'
                                : book.publisher,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Gaps.sm,
                          Text(
                            'ISBN',
                            style: TextStyle(
                              color: AppColors.grey400,
                              fontSize: 12,
                            ),
                          ),
                          Gaps.xxs,
                          Text(
                            book.isbn.isEmpty ? 'N/A' : book.isbn,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pages',
                            style: TextStyle(
                              color: AppColors.grey400,
                              fontSize: 12,
                            ),
                          ),
                          Gaps.xxs,
                          Text(
                            '${book.pages > 0 ? book.pages : 320}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Gaps.sm,
                          Text(
                            'Category',
                            style: TextStyle(
                              color: AppColors.grey400,
                              fontSize: 12,
                            ),
                          ),
                          Gaps.xxs,
                          Text(
                            book.categoryName.isEmpty
                                ? 'General'
                                : book.categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Gaps.lg,

            // ── Reader Reviews Section ──
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    'Reader Reviews',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _writeReview,
                    icon: const Icon(
                      Icons.rate_review_outlined,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    label: const Text(
                      'Review',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            Gaps.xs,
            Row(
              children: [
                RatingBarIndicator(
                  rating: book.rating,
                  itemCount: 5,
                  itemSize: 18,
                  itemBuilder: (_, _) =>
                      const Icon(Icons.star_rounded, color: AppColors.accent),
                ),
                Gaps.hSm,
                Text(
                  '${book.ratingLabel} (${book.reviewCount} reviews)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Gaps.md,

            _ReviewsList(
              bookId: book.id,
              onDelete: _deleteReview,
              onWriteReview: _writeReview,
            ),

            Gaps.xxl,
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            border: Border(
              top: BorderSide(color: AppColors.darkSurfaceVariant),
            ),
          ),
          child: Row(
            children: [
              QuantitySelector(
                qty: _qty,
                max: book.stock > 0 ? book.stock : 10,
                onChanged: (v) => setState(() => _qty = v),
              ),
              Gaps.hMd,
              Text(
                Formatters.price(book.price * _qty),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Gaps.hMd,
              Expanded(
                child: ElevatedButton(
                  onPressed: book.isInStock ? _addToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.brandDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                  child: const Text(
                    'Add to Bag',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  const _ReviewsList({
    required this.bookId,
    required this.onDelete,
    required this.onWriteReview,
  });

  final String bookId;
  final ValueChanged<ReviewModel> onDelete;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewProvider>();
    final list = reviews.reviewsFor(bookId);
    final auth = context.watch<AuthProvider>();

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Text(
          'No reviews yet. Be the first to share your thoughts!',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => ReviewTile(
        review: list[i],
        currentUserId: auth.uid,
        isAdmin: auth.isAdmin,
        onToggleLike: () => reviews.toggleLike(list[i], auth.uid ?? ''),
        onDelete: () => onDelete(list[i]),
        onEdit: onWriteReview,
      ),
    );
  }
}
