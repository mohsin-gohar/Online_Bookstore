import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/book_model.dart';
import '../../data/models/category_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/book_provider.dart';
import '../../logic/wishlist_provider.dart';
import '../common_widgets/book_card.dart';
import '../common_widgets/custom_appbar.dart';
import '../common_widgets/empty_state.dart';
import '../common_widgets/error_state.dart';
import '../common_widgets/shimmer_box.dart';

/// Lists every book in a category (opened from the home categories row).
///
/// Receives the [CategoryModel] via `extra`; if opened by deep link without it,
/// the id in the path is used for the title fallback.
class CategoryBooksScreen extends StatefulWidget {
  const CategoryBooksScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  final String categoryId;
  final CategoryModel? category;

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  late Future<List<BookModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<BookProvider>().getByCategory(widget.categoryId);
  }

  Future<void> _reload() {
    final future = context.read<BookProvider>().getByCategory(
      widget.categoryId,
    );
    setState(() => _future = future);
    return future;
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
    final title = widget.category?.name ?? 'Category';

    return Scaffold(
      appBar: CustomAppBar(title: title, showCart: true),
      body: FutureBuilder<List<BookModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const BookGridSkeleton(count: 6);
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final books = snapshot.data ?? const <BookModel>[];
          if (books.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: AppStrings.emptySearch,
              message: 'No books in $title yet.',
              actionLabel: 'Browse all',
              onAction: () => context.go(AppRoutes.catalogPath),
            );
          }
          return _CategoryGrid(
            books: books,
            onToggleWishlist: _toggleWishlist,
            onRefresh: _reload,
          );
        },
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.books,
    required this.onToggleWishlist,
    required this.onRefresh,
  });

  final List<BookModel> books;
  final ValueChanged<BookModel> onToggleWishlist;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: books.length,
        // Responsive: phones get 2 columns; tablets automatically more.
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 190,
          crossAxisSpacing: AppSizes.sm,
          mainAxisSpacing: AppSizes.md,
          childAspectRatio: 0.52,
        ),
        itemBuilder: (context, i) {
          final book = books[i];
          return BookCard(
            book: book,
            width: double.infinity,
            isWishlisted: wishlist.contains(book.id),
            onTap: () => context.push(AppRoutes.bookDetails(book.id)),
            onToggleWishlist: () => onToggleWishlist(book),
          );
        },
      ),
    );
  }
}
