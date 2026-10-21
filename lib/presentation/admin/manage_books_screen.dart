import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/book_model.dart';
import '../../data/repositories/book_repository.dart';
import '../../logic/book_provider.dart';
import '../common_widgets/custom_appbar.dart';
import '../common_widgets/empty_state.dart';
import '../common_widgets/error_state.dart';
import 'widgets/book_form_sheet.dart';

/// Admin: list, search, add, edit and delete books.
class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  final _searchController = TextEditingController();
  List<BookModel> _books = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await context.read<BookProvider>().searchFor(
        _searchController.text.trim(),
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final books = context.read<BookProvider>();
    final repo = context.read<BookRepository>();
    final categories = books.categories.data ?? const [];
    if (categories.isEmpty) {
      SnackbarHelper.showWarning(context, 'Create a category first.');
      return;
    }
    final book = await BookFormSheet.show(context, categories: categories);
    if (book == null || !mounted) return;
    try {
      await repo.createBook(book);
      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        'Book added',
        actionLabel: AppStrings.view,
        onAction: () {
          if (!mounted) return;
          AppNavigator.toBookDetails(context, book.id);
        },
      );
      _load();
      books.loadHome();
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, e.toString());
    }
  }

  Future<void> _edit(BookModel book) async {
    final books = context.read<BookProvider>();
    final repo = context.read<BookRepository>();
    final categories = books.categories.data ?? const [];
    final updated = await BookFormSheet.show(
      context,
      categories: categories,
      existing: book,
    );
    if (updated == null || !mounted) return;
    try {
      await repo.updateBook(updated);
      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        'Book updated',
        actionLabel: AppStrings.view,
        onAction: () {
          if (!mounted) return;
          AppNavigator.toBookDetails(context, updated.id);
        },
      );
      _load();
      books.loadHome();
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, e.toString());
    }
  }

  Future<void> _delete(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('Delete "${book.title}"? This cannot be undone.'),
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
    try {
      await context.read<BookRepository>().deleteBook(book.id);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Book deleted');
      _load();
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.manageBooks,
        showBack: true,
        showCart: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Book'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search books…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _load();
                  },
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    if (_books.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No books',
        message: 'Tap "Add Book" to create your first title.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.md,
          0,
          AppSizes.md,
          AppSizes.xxl * 2,
        ),
        itemCount: _books.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) => _BookRow(
          book: _books[i],
          onView: () => AppNavigator.toBookDetails(context, _books[i].id),
          onEdit: () => _edit(_books[i]),
          onDelete: () => _delete(_books[i]),
        ),
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.book,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final BookModel book;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: SizedBox(
              width: 44,
              height: 64,
              child: book.coverImage.isEmpty
                  ? Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: scheme.onSurface.withValues(alpha: 0.3),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: book.coverImage,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: scheme.surfaceContainerHighest),
                      errorWidget: (_, _, _) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_rounded),
                      ),
                    ),
            ),
          ),
          Gaps.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(book.author, style: theme.textTheme.bodySmall),
                Gaps.xxs,
                Row(
                  children: [
                    Text(
                      Formatters.price(book.price),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gaps.hSm,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (book.isInStock
                                    ? AppColors.success
                                    : AppColors.danger)
                                .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusPill,
                        ),
                      ),
                      child: Text(
                        'Stock ${book.stock}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: book.isInStock
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.viewInStore,
            icon: const Icon(Icons.visibility_outlined),
            onPressed: onView,
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
