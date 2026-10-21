import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/local_storage_service.dart';
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

/// Full-screen search matching Screen 2 in reference UI.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  bool _isSearching = false;
  String _term = '';
  List<BookModel> _results = const [];
  String? _error;
  List<String> _recent = const [];

  static const List<String> _popularTags = [
    'Fiction',
    'Classics',
    'Mystery',
    'Sci-Fi',
    'Philosophy',
    'History',
  ];

  @override
  void initState() {
    super.initState();
    _recent = context.read<LocalStorageService>().recentSearches;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _term = value.trim());
    if (_term.isEmpty) {
      setState(() {
        _results = const [];
        _isSearching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final term = _term;
    if (term.isEmpty) return;
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final results = await context.read<BookProvider>().searchFor(term);
      if (!mounted || term != _term) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submitTerm(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    _controller.text = trimmed;
    _controller.selection = TextSelection.collapsed(offset: trimmed.length);
    setState(() => _term = trimmed);
    await context.read<LocalStorageService>().addRecentSearch(trimmed);
    if (!mounted) return;
    setState(
      () => _recent = context.read<LocalStorageService>().recentSearches,
    );
    await _runSearch();
  }

  Future<void> _clearRecent() async {
    await context.read<LocalStorageService>().clearRecentSearches();
    if (!mounted) return;
    setState(() => _recent = const []);
  }

  Future<void> _openFilter() async {
    final books = context.read<BookProvider>();
    final categories = books.categories.data ?? [];
    final res = await FilterSheet.show(
      context,
      categories: categories,
      initialSort: books.query.sort,
    );
    if (res != null) {
      books.updateFilters(
        sort: res.sort,
        categoryId: res.categoryId,
        minPrice: res.minPrice,
        maxPrice: res.maxPrice,
        minRating: res.minRating,
        inStockOnly: res.inStockOnly,
      );
      if (_term.isNotEmpty) _runSearch();
    }
  }

  Future<void> _toggleWishlist(BookModel book) async {
    if (!context.read<AuthProvider>().isAuthenticated) {
      SnackbarHelper.showWarning(context, 'Please log in to save books.');
      return;
    }
    final wishlist = context.read<WishlistProvider>();
    final ok = await wishlist.toggle(book);
    if (!mounted) return;
    if (!ok && wishlist.error != null) {
      SnackbarHelper.showError(context, wishlist.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _submitTerm,
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.accent,
              ),
              suffixIcon: _term.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: const Icon(Icons.tune_rounded, color: AppColors.accent),
            onPressed: _openFilter,
          ),
          Gaps.hXs,
        ],
      ),
      body: _buildBody(wishlist),
    );
  }

  Widget _buildBody(WishlistProvider wishlist) {
    if (_term.isEmpty) {
      return _SearchOverview(
        recent: _recent,
        popularTags: _popularTags,
        onTapTerm: _submitTerm,
        onClearRecent: _clearRecent,
      );
    }
    if (_isSearching) {
      return const BookGridSkeleton(count: 6);
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _runSearch);
    }
    if (_results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: AppStrings.emptySearch,
        message: AppStrings.emptySearchBody,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final book = _results[i];
        return BookCard(
          book: book,
          layout: BookCardLayout.list,
          isWishlisted: wishlist.contains(book.id),
          onTap: () => context.push(AppRoutes.bookDetails(book.id)),
          onToggleWishlist: () => _toggleWishlist(book),
        );
      },
    );
  }
}

class _SearchOverview extends StatelessWidget {
  const _SearchOverview({
    required this.recent,
    required this.popularTags,
    required this.onTapTerm,
    required this.onClearRecent,
  });

  final List<String> recent;
  final List<String> popularTags;
  final ValueChanged<String> onTapTerm;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.md),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClearRecent,
                child: const Text(AppStrings.clearAll),
              ),
            ],
          ),
          Gaps.xs,
          Wrap(
            spacing: AppSizes.xs,
            runSpacing: AppSizes.xs,
            children: recent
                .map(
                  (term) => ActionChip(
                    avatar: const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    label: Text(term),
                    onPressed: () => onTapTerm(term),
                  ),
                )
                .toList(),
          ),
          Gaps.lg,
        ],

        Text(
          'Popular Genres & Tags',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        Gaps.xs,
        Wrap(
          spacing: AppSizes.xs,
          runSpacing: AppSizes.xs,
          children: popularTags
              .map(
                (tag) => ChoiceChip(
                  label: Text(tag),
                  selected: false,
                  onSelected: (_) => onTapTerm(tag),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
