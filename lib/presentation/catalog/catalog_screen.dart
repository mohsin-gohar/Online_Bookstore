import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/book_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/book_provider.dart';
import '../../logic/wishlist_provider.dart';
import '../common_widgets/book_card.dart';
import '../common_widgets/empty_state.dart';
import '../common_widgets/error_state.dart';
import '../common_widgets/shimmer_box.dart';
import 'widgets/filter_sheet.dart';

/// The Catalog tab: a filtered, sorted, paginated grid of all books.
///
/// Search is entered from the Home search bar (Phase 5's search screen); the
/// catalog itself reflects the current [BookProvider.query] and exposes a
/// filter/sort bar plus infinite scroll.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final books = context.read<BookProvider>();
      if (!books.catalog.hasLoadedOnce && !books.catalog.isLoading) {
        books.loadCatalog();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Loads the next page as the user nears the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 400;
    if (_scrollController.position.pixels >= threshold) {
      context.read<BookProvider>().loadMoreCatalog();
    }
  }

  Future<void> _openFilters() async {
    final books = context.read<BookProvider>();
    final result = await FilterSheet.show(
      context,
      categories: books.categories.data ?? const [],
      initialSort: books.query.sort,
      categoryId: books.query.categoryId,
      minPrice: books.query.minPrice,
      maxPrice: books.query.maxPrice,
      minRating: books.query.minRating,
      inStockOnly: books.query.inStockOnly,
    );
    if (result == null || !mounted) return;
    await books.updateFilters(
      categoryId: result.categoryId,
      minPrice: result.minPrice,
      maxPrice: result.maxPrice,
      minRating: result.minRating,
      sort: result.sort,
      inStockOnly: result.inStockOnly,
    );
  }

  Future<void> _toggleWishlist(BookModel book) async {
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

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookProvider>();
    final state = books.catalog;
    final items = state.data ?? const <BookModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.catalog),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppRoutes.searchPath),
          ),
        ],
      ),
      body: Column(
        children: [
          _CatalogToolbar(
            sortLabel: books.query.sort.label,
            hasFilters: books.query.hasActiveFilters,
            onSortTap: _openFilters,
            onFilterTap: _openFilters,
            onClear: books.clearFilters,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<BookProvider>().loadCatalog(),
              child: _buildBody(state, items, books),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AsyncState<List<BookModel>> state,
    List<BookModel> items,
    BookProvider books,
  ) {
    if (state.isLoading && items.isEmpty) {
      return const BookGridSkeleton(count: 8);
    }
    if (state.hasError && items.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: ErrorState(
              message: state.error!,
              onRetry: () => context.read<BookProvider>().loadCatalog(),
            ),
          ),
        ],
      );
    }
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: AppStrings.emptySearch,
              message: AppStrings.emptySearchBody,
              actionLabel: 'Clear filters',
              onAction: books.isFiltered ? books.clearFilters : null,
            ),
          ),
        ],
      );
    }

    final wishlist = context.watch<WishlistProvider>();
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSizes.md),
          sliver: SliverGrid(
            // Responsive: phones get 2 columns; tablets / wide screens
            // automatically get more (tiles never exceed 190dp wide).
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 190,
              crossAxisSpacing: AppSizes.sm,
              mainAxisSpacing: AppSizes.md,
              childAspectRatio: 0.52,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final book = items[i];
              return BookCard(
                book: book,
                width: double.infinity,
                isWishlisted: wishlist.contains(book.id),
                onTap: () => context.push(AppRoutes.bookDetails(book.id)),
                onToggleWishlist: () => _toggleWishlist(book),
              );
            }, childCount: items.length),
          ),
        ),
        if (books.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSizes.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (!books.hasMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSizes.xl),
              child: Center(
                child: Text(
                  "You've reached the end",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The sort + filter bar shown above the grid.
class _CatalogToolbar extends StatelessWidget {
  const _CatalogToolbar({
    required this.sortLabel,
    required this.hasFilters,
    required this.onSortTap,
    required this.onFilterTap,
    required this.onClear,
  });

  final String sortLabel;
  final bool hasFilters;
  final VoidCallback onSortTap;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.xs,
        AppSizes.md,
        AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSortTap,
              icon: const Icon(Icons.sort_rounded, size: 18),
              label: Text(sortLabel, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                // Using fromHeight(44) is safe here as Expanded provides width
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Gaps.hSm,
          Expanded(
            child: Badge(
              isLabelVisible: hasFilters,
              label: const Text('!'),
              alignment: const AlignmentDirectional(10, -10),
              child: SizedBox(
                // Constraining the button width inside the Badge
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onFilterTap,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ),
          if (hasFilters) ...[
            Gaps.hXs,
            IconButton(
              tooltip: 'Clear filters',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
