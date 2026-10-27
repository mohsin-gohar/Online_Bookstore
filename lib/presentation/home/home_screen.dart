import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/mock/demo_catalog.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/book_provider.dart';
import '../../../logic/cart_provider.dart';
import '../../../logic/notification_provider.dart';
import '../../../logic/wishlist_provider.dart';
import '../book_details/widgets/book_sample_reader_sheet.dart';
import '../common_widgets/book_card.dart';
import '../common_widgets/book_cover_image.dart';
import '../common_widgets/empty_state.dart';
import '../common_widgets/section_header.dart';
import '../common_widgets/shimmer_skeleton.dart';
import 'widgets/home_search_bar.dart';

/// Home screen displaying featured books, categories, bestsellers, and promotions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().loadHome();
    });
  }

  Future<void> _refresh() => context.read<BookProvider>().refreshHome();

  void _openBook(BookModel book) {
    context.push(AppRoutes.bookDetails(book.id));
  }

  Future<void> _addToBag(BookModel book) async {
    final cart = context.read<CartProvider>();
    final ok = await cart.addToCart(book);
    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, '${book.title} added to bag');
    } else if (cart.error != null) {
      SnackbarHelper.showError(context, cart.error!);
    }
  }

  Future<void> _toggleWishlist(BookModel book) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
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

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookProvider>();
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final notifications = context.watch<NotificationProvider>();

    final user = auth.user;
    final userName = user != null && user.name.isNotEmpty
        ? user.name.split(' ').first
        : 'Reader';

    final bestsellers = books.bestsellers.data ?? [];
    final newArrivals = books.newArrivals.data ?? [];
    final allLoadedBooks = <BookModel>{...bestsellers, ...newArrivals}.toList();
    final featuredBook = allLoadedBooks.isNotEmpty
        ? allLoadedBooks.first
        : null;
    final dealBook = allLoadedBooks.length > 1
        ? allLoadedBooks[1]
        : featuredBook;
    final editorsPicks = allLoadedBooks.length > 3
        ? allLoadedBooks.sublist(2, min(allLoadedBooks.length, 8))
        : allLoadedBooks;
    final trendingBooks = allLoadedBooks.length > 4
        ? allLoadedBooks.sublist(min(3, allLoadedBooks.length))
        : allLoadedBooks;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              titleSpacing: AppSizes.md,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.import_contacts_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  Gaps.hSm,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Welcome back, $userName',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Notification bell with unread badge
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.push(AppRoutes.notificationsPath),
                  icon: Badge(
                    isLabelVisible: notifications.unreadCount > 0,
                    label: Text('${notifications.unreadCount}'),
                    backgroundColor: AppColors.terracotta,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
                // Cart icon with count badge
                IconButton(
                  tooltip: 'Cart',
                  onPressed: () => context.go(AppRoutes.cartPath),
                  icon: Badge(
                    isLabelVisible: cart.itemCount > 0,
                    label: Text('${cart.itemCount}'),
                    backgroundColor: AppColors.accent,
                    textColor: AppColors.brandDark,
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
                Gaps.hXs,
              ],
            ),

            // ── Search Bar Section ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.md,
                  AppSizes.xs,
                  AppSizes.md,
                  AppSizes.sm,
                ),
                child: HomeSearchBar(),
              ),
            ),

            // ── Hero Editorial Spotlight ("Book of the Month") ──
            if (featuredBook != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: _HeroBookSpotlight(
                    book: featuredBook,
                    onTap: () => _openBook(featuredBook),
                    onReadSample: () =>
                        BookSampleReaderSheet.show(context, featuredBook),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: Gaps.lg),

            // ── Section 2: Genre / Category Explorer Pills ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BROWSE GENRES',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.catalogPath),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'All Categories →',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CategoryPillsRow(
                state: books.categories,
                selectedCategoryId: _selectedCategoryId,
                onSelectCategory: (id) {
                  setState(() => _selectedCategoryId = id);
                  if (id != null) {
                    final cat = books.categories.data?.firstWhere(
                      (c) => c.id == id,
                    );
                    if (cat != null) {
                      context.push(AppRoutes.categoryBooks(cat.id), extra: cat);
                    }
                  }
                },
              ),
            ),

            const SliverToBoxAdapter(child: Gaps.lg),

            // ── Section 3: Flash Deal of the Day (Live Countdown & 35% OFF) ──
            if (dealBook != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: _DealOfTheDayCard(
                    book: dealBook,
                    onTap: () => _openBook(dealBook),
                    onAddToBag: _addToBag,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Gaps.lg),
            ],

            // ── Section 4: Top 10 Ranked Bestsellers ──
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Top Bestsellers',
                actionLabel: AppStrings.seeAll,
                onAction: () => context.go(AppRoutes.catalogPath),
              ),
            ),
            SliverToBoxAdapter(
              child: _RankedBestsellersRail(
                state: books.bestsellers,
                onBookTap: _openBook,
                onAddToBag: _addToBag,
              ),
            ),

            const SliverToBoxAdapter(child: Gaps.lg),

            // ── Section 5: Editor’s Handpicked Staff Picks ──
            if (editorsPicks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Editor’s Choice',
                  actionLabel: 'Explore All',
                  onAction: () => context.go(AppRoutes.catalogPath),
                ),
              ),
              SliverToBoxAdapter(
                child: _EditorsPicksSection(
                  books: editorsPicks,
                  onBookTap: _openBook,
                  onReadSample: (b) => BookSampleReaderSheet.show(context, b),
                ),
              ),
              const SliverToBoxAdapter(child: Gaps.lg),
            ],

            // ── Section 6: Limited-Time Promo Voucher Banner ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: _PromoOfferBanner(
                  onAction: () {
                    SnackbarHelper.showSuccess(
                      context,
                      'Code APTECH20 copied! Enjoy 20% discount at checkout.',
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gaps.lg),

            // ── Section 7: New Arrivals & Fresh Releases ──
            SliverToBoxAdapter(
              child: SectionHeader(
                title: AppStrings.newArrivals,
                actionLabel: AppStrings.seeAll,
                onAction: () => context.go(AppRoutes.catalogPath),
              ),
            ),
            SliverToBoxAdapter(
              child: _NewArrivalsRail(
                state: books.newArrivals,
                onBookTap: _openBook,
                onToggleWishlist: _toggleWishlist,
              ),
            ),

            const SliverToBoxAdapter(child: Gaps.lg),

            // ── Section 8: Trending Now & Highly Rated ──
            if (trendingBooks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Trending & Highly Rated',
                  actionLabel: AppStrings.seeAll,
                  onAction: () => context.go(AppRoutes.catalogPath),
                ),
              ),
              SliverToBoxAdapter(
                child: _TrendingGridSection(
                  books: trendingBooks,
                  onBookTap: _openBook,
                  onAddToBag: _addToBag,
                ),
              ),
              const SliverToBoxAdapter(child: Gaps.lg),
            ],

            // ── Featured Authors ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md,
                  0,
                  AppSizes.md,
                  AppSizes.sm,
                ),
                child: Text(
                  'FEATURED AUTHORS',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FeaturedAuthorsRail(
                onAuthorTap: (name) =>
                    context.push(AppRoutes.authorBooks(name)),
              ),
            ),

            const SliverToBoxAdapter(child: Gaps.xl),

            // ── Section 11: Reader Stories & Verified Reviews Carousel ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.md,
                  0,
                  AppSizes.md,
                  AppSizes.sm,
                ),
                child: Text(
                  'VERIFIED READER EXPERIENCES',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _ReaderReviewsCarousel()),

            const SliverToBoxAdapter(child: Gaps.xl),

            // ── Section 12: VIP Readers Club & Membership Banner ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: _BookClubBanner(
                  onJoin: () {
                    SnackbarHelper.showSuccess(
                      context,
                      'Welcome to Book Store VIP Club! 15% discount applied.',
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gaps.xl),

            // ── Section 13: Trust & Quality Guarantee Badges ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: _StoreTrustBadges(),
              ),
            ),

            const SliverToBoxAdapter(child: Gaps.xxl),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 1. Hero Book Spotlight Card
// ──────────────────────────────────────────────
class _HeroBookSpotlight extends StatelessWidget {
  const _HeroBookSpotlight({
    required this.book,
    required this.onTap,
    required this.onReadSample,
  });

  final BookModel book;
  final VoidCallback onTap;
  final VoidCallback onReadSample;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF132042), Color(0xFF070C1B)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          children: [
            // Floating 3D Book Cover
            GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: BookCoverImage(
                  imageUrl: book.coverImage,
                  title: book.title,
                  author: book.author,
                  width: 95,
                  height: 140,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
            Gaps.hMd,
            // Info & CTAs
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      '⭐ EDITOR’S PICK',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Gaps.xs,
                  InkWell(
                    onTap: onTap,
                    child: Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Gaps.xxs,
                  Text(
                    'by ${book.author}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gaps.xs,
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        book.ratingLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        book.priceLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accentLight,
                        ),
                      ),
                    ],
                  ),
                  Gaps.sm,
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.brandDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusPill,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Explore Now',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Gaps.hXs,
                      OutlinedButton(
                        onPressed: onReadSample,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentLight,
                          side: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusPill,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_stories_rounded, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Sample',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 2. Category Pills Row
// ──────────────────────────────────────────────
class _CategoryPillsRow extends StatelessWidget {
  const _CategoryPillsRow({
    required this.state,
    required this.selectedCategoryId,
    required this.onSelectCategory,
  });

  final AsyncState<List<CategoryModel>> state;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && !state.hasLoadedOnce) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final categories = state.data ?? [];

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.xs),
            child: ChoiceChip(
              avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('All Books'),
              selected: selectedCategoryId == null,
              onSelected: (_) => onSelectCategory(null),
              selectedColor: AppColors.accent,
              checkmarkColor: AppColors.brandDark,
              labelStyle: TextStyle(
                color: selectedCategoryId == null
                    ? AppColors.brandDark
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: AppSizes.xs),
              child: ChoiceChip(
                avatar: Icon(_getCategoryIcon(c.name), size: 16),
                label: Text(c.name),
                selected: selectedCategoryId == c.id,
                onSelected: (_) => onSelectCategory(c.id),
                selectedColor: AppColors.accent,
                checkmarkColor: AppColors.brandDark,
                labelStyle: TextStyle(
                  color: selectedCategoryId == c.id
                      ? AppColors.brandDark
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fiction')) return Icons.menu_book_rounded;
    if (lower.contains('non-fiction')) return Icons.lightbulb_outline_rounded;
    if (lower.contains('academic')) return Icons.school_outlined;
    if (lower.contains('comic')) return Icons.brush_outlined;
    if (lower.contains('scifi') || lower.contains('science')) {
      return Icons.rocket_launch_outlined;
    }
    return Icons.bookmark_outline_rounded;
  }
}

// ──────────────────────────────────────────────
// 3. Ranked Bestsellers Rail (#1, #2, #3...)
// ──────────────────────────────────────────────
class _RankedBestsellersRail extends StatelessWidget {
  const _RankedBestsellersRail({
    required this.state,
    required this.onBookTap,
    required this.onAddToBag,
  });

  final AsyncState<List<BookModel>> state;
  final ValueChanged<BookModel> onBookTap;
  final ValueChanged<BookModel> onAddToBag;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && !state.hasLoadedOnce) {
      return const BookCardSkeletonRail();
    }
    final books = state.data ?? [];
    if (books.isEmpty) {
      return const SizedBox(
        height: 180,
        child: EmptyState(
          compact: true,
          icon: Icons.star_border_rounded,
          title: 'No bestsellers found',
          message: 'Top-selling titles will appear here.',
        ),
      );
    }

    return SizedBox(
      height: 285,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = books[i];
          final rank = i + 1;

          return SizedBox(
            width: 145,
            child: InkWell(
              onTap: () => onBookTap(book),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book cover with Gold Rank Badge
                  Stack(
                    children: [
                      Container(
                        height: 200,
                        width: 145,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: BookCoverImage(
                          imageUrl: book.coverImage,
                          title: book.title,
                          author: book.author,
                          width: 145,
                          height: 200,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                      ),
                      // Rank number badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            '#$rank',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ),
                      ),
                      // Quick Add to Cart button
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Material(
                          color: AppColors.brandDark.withValues(alpha: 0.85),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onAddToBag(book),
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 16,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Author
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        book.priceLabel,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            book.ratingLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 4. Promotional Banner Card
// ──────────────────────────────────────────────
class _PromoOfferBanner extends StatelessWidget {
  const _PromoOfferBanner({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B4513), Color(0xFFB4552B), Color(0xFF5A2A18)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB4552B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.celebration_rounded,
                        color: AppColors.accentLight,
                        size: 16,
                      ),
                      Gaps.xxs,
                      Text(
                        'READERS FESTIVAL',
                        style: TextStyle(
                          color: AppColors.accentLight.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Get 20% OFF on all books!',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Use promo code APTECH20 during checkout.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentLight,
                foregroundColor: AppColors.brandDark,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
              ),
              child: const Text(
                'Copy Code',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 5. New Arrivals Rail with Wishlist Toggle
// ──────────────────────────────────────────────
class _NewArrivalsRail extends StatelessWidget {
  const _NewArrivalsRail({
    required this.state,
    required this.onBookTap,
    required this.onToggleWishlist,
  });

  final AsyncState<List<BookModel>> state;
  final ValueChanged<BookModel> onBookTap;
  final ValueChanged<BookModel> onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && !state.hasLoadedOnce) {
      return const BookCardSkeletonRail();
    }
    final books = state.data ?? [];
    if (books.isEmpty) {
      return const SizedBox(
        height: 180,
        child: EmptyState(
          compact: true,
          icon: Icons.auto_stories_outlined,
          title: 'No new arrivals',
          message: 'Check back soon for fresh arrivals.',
        ),
      );
    }

    final wishlist = context.watch<WishlistProvider>();
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: books.length,
        separatorBuilder: (_, _) => Gaps.hSm,
        itemBuilder: (context, i) => BookCard(
          book: books[i],
          width: 140,
          isWishlisted: wishlist.contains(books[i].id),
          onTap: () => onBookTap(books[i]),
          onToggleWishlist: () => onToggleWishlist(books[i]),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 6. Featured Authors Rail
// ──────────────────────────────────────────────
class _FeaturedAuthorsRail extends StatelessWidget {
  const _FeaturedAuthorsRail({required this.onAuthorTap});

  final ValueChanged<String> onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final authors = demoAuthors.take(8).toList();

    return SizedBox(
      height: 115,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: authors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final author = authors[i];
          final name = author['name'] as String;
          final initials = name
              .trim()
              .split(' ')
              .map((p) => p.isNotEmpty ? p[0] : '')
              .take(2)
              .join();

          return InkWell(
            onTap: () => onAuthorTap(name),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E2D54), Color(0xFF0F172A)],
                      ),
                      border: Border.all(color: AppColors.accent, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 7. Store Trust & Quality Badges
// ──────────────────────────────────────────────
class _StoreTrustBadges extends StatelessWidget {
  const _StoreTrustBadges();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BadgeItem(
            icon: Icons.local_shipping_outlined,
            label: 'Free Delivery',
            sub: 'Orders \$50+',
          ),
          _BadgeItem(
            icon: Icons.verified_outlined,
            label: '100% Genuine',
            sub: 'Authentic Books',
          ),
          _BadgeItem(
            icon: Icons.replay_circle_filled_outlined,
            label: 'Easy Returns',
            sub: '7 Days Guarantee',
          ),
          _BadgeItem(
            icon: Icons.headset_mic_outlined,
            label: '24/7 Support',
            sub: 'Always Here',
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.sub,
  });

  final IconData icon;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 8. Deal of the Day Spotlight (Flash Countdown)
// ──────────────────────────────────────────────
class _DealOfTheDayCard extends StatefulWidget {
  const _DealOfTheDayCard({
    required this.book,
    required this.onTap,
    required this.onAddToBag,
  });

  final BookModel book;
  final VoidCallback onTap;
  final ValueChanged<BookModel> onAddToBag;

  @override
  State<_DealOfTheDayCard> createState() => _DealOfTheDayCardState();
}

class _DealOfTheDayCardState extends State<_DealOfTheDayCard> {
  int _secondsLeft = 5 * 3600 + 24 * 60 + 18;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0 && mounted) {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final hours = (_secondsLeft ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_secondsLeft % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final originalPrice = (book.price * 1.35).toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22150A), Color(0xFF100904)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tag + Live Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'DEAL OF THE DAY · 35% OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(),
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gaps.md,
          // Book preview row
          Row(
            children: [
              GestureDetector(
                onTap: widget.onTap,
                child: BookCoverImage(
                  imageUrl: book.coverImage,
                  title: book.title,
                  author: book.author,
                  width: 85,
                  height: 125,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              Gaps.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${book.author}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          book.priceLabel,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$$originalPrice',
                          style: TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Scarcity bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: const LinearProgressIndicator(
                              value: 0.25,
                              minHeight: 5,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.terracotta,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Only 3 left!',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => widget.onAddToBag(book),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.brandDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusPill,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.flash_on_rounded, size: 14),
                      label: const Text(
                        'Claim Deal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 9. Editor's Choice Section
// ──────────────────────────────────────────────
class _EditorsPicksSection extends StatelessWidget {
  const _EditorsPicksSection({
    required this.books,
    required this.onBookTap,
    required this.onReadSample,
  });

  final List<BookModel> books;
  final ValueChanged<BookModel> onBookTap;
  final ValueChanged<BookModel> onReadSample;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 155,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final book = books[i];
          return Container(
            width: 290,
            padding: const EdgeInsets.all(AppSizes.sm + 2),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onBookTap(book),
                  child: BookCoverImage(
                    imageUrl: book.coverImage,
                    title: book.title,
                    author: book.author,
                    width: 78,
                    height: 118,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'BOOK STORE CURATION',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracotta,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${book.author}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            book.priceLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accent,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => onReadSample(book),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              foregroundColor: AppColors.accent,
                            ),
                            child: const Text(
                              'Sample →',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 10. Trending & Highly Rated Section
// ──────────────────────────────────────────────
class _TrendingGridSection extends StatelessWidget {
  const _TrendingGridSection({
    required this.books,
    required this.onBookTap,
    required this.onAddToBag,
  });

  final List<BookModel> books;
  final ValueChanged<BookModel> onBookTap;
  final ValueChanged<BookModel> onAddToBag;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 275,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final book = books[i];
          return GestureDetector(
            onTap: () => onBookTap(book),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      BookCoverImage(
                        imageUrl: book.coverImage,
                        title: book.title,
                        author: book.author,
                        width: 140,
                        height: 180,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                book.ratingLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              book.priceLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                            InkWell(
                              onTap: () => onAddToBag(book),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Reader Stories & Testimonials Carousel
// ──────────────────────────────────────────────
class _ReaderReviewsCarousel extends StatelessWidget {
  const _ReaderReviewsCarousel();

  @override
  Widget build(BuildContext context) {
    final reviews = [
      {
        'quote':
            'Book Store has completely transformed how I discover new authors. The packaging and delivery was impeccable!',
        'reader': 'Sarah M.',
        'city': 'Karachi',
        'book': 'The Great Gatsby',
      },
      {
        'quote':
            'The hardcover quality and fast dispatch across Pakistan is unmatched. 100% genuine titles.',
        'reader': 'Bilal A.',
        'city': 'Lahore',
        'book': 'Atomic Habits',
      },
      {
        'quote':
            'Found computer science and fiction titles that were completely sold out in local stores. Highly recommended!',
        'reader': 'Dr. Tariq Z.',
        'city': 'Islamabad',
        'book': 'Clean Code',
      },
    ];

    return SizedBox(
      height: 145,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final r = reviews[i];
          return Container(
            width: 270,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (_) => const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 10,
                            color: Colors.green,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'VERIFIED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    '"${r['quote']}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '— ${r['reader']}, ${r['city']} · on ${r['book']}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 13. VIP Readers Club & Membership Banner
// ──────────────────────────────────────────────
class _BookClubBanner extends StatelessWidget {
  const _BookClubBanner({required this.onJoin});

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_membership_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOK STORE READERS CLUB',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Join 50,000+ Literary Explorers',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Get 15% off your next order, invitations to live author AMAs, monthly reading challenges, and free collector bookmarks.',
            style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.brandDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
            ),
            child: const Text(
              'Join VIP Club Free',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
