import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/models/book_model.dart';
import '../data/models/category_model.dart';
import '../data/repositories/book_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/services/app_exceptions.dart';

/// A tiny async state wrapper so screens can render loading/empty/error/success
/// without each one re-implementing the same booleans.
class AsyncState<T> {
  const AsyncState({
    this.data,
    this.isLoading = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  final T? data;
  final bool isLoading;
  final String? error;

  /// True after at least one successful load (so we can show "empty" instead of
  /// the initial spinner).
  final bool hasLoadedOnce;

  bool get hasError => error != null;
  bool get hasData => data != null;
  bool get isEmpty => data is List && (data as List).isEmpty;

  AsyncState<T> loading() =>
      AsyncState<T>(data: data, isLoading: true, hasLoadedOnce: hasLoadedOnce);

  AsyncState<T> success(T value) =>
      AsyncState<T>(data: value, isLoading: false, hasLoadedOnce: true);

  AsyncState<T> failure(String message) => AsyncState<T>(
    data: data,
    isLoading: false,
    error: message,
    hasLoadedOnce: hasLoadedOnce,
  );
}

/// Owns catalog data: categories, bestsellers, new arrivals, and the paginated
/// search/filter results for the catalog screen.
class BookProvider extends ChangeNotifier {
  BookProvider({
    required BookRepository bookRepository,
    required CategoryRepository categoryRepository,
  }) : _books = bookRepository,
       _categories = categoryRepository;

  final BookRepository _books;
  final CategoryRepository _categories;

  // ── Home-screen sections (private state + public getters) ──
  AsyncState<List<CategoryModel>> _categoriesState = const AsyncState();
  AsyncState<List<BookModel>> _bestsellersState = const AsyncState();
  AsyncState<List<BookModel>> _newArrivalsState = const AsyncState();

  AsyncState<List<CategoryModel>> get categories => _categoriesState;
  AsyncState<List<BookModel>> get bestsellers => _bestsellersState;
  AsyncState<List<BookModel>> get newArrivals => _newArrivalsState;

  // ── Catalog (search/filter/sort/paginate) ─
  BookQuery _query = const BookQuery();
  AsyncState<List<BookModel>> _catalog = const AsyncState();
  final List<BookModel> _catalogItems = [];
  bool _hasMore = false;
  bool _loadingMore = false;

  BookQuery get query => _query;
  AsyncState<List<BookModel>> get catalog => AsyncState<List<BookModel>>(
    data: _catalogItems,
    isLoading: _catalog.isLoading,
    error: _catalog.error,
    hasLoadedOnce: _catalog.hasLoadedOnce,
  );
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  /// True when a search term or any filter is active.
  bool get isFiltered =>
      _query.searchTerm.trim().isNotEmpty || _query.hasActiveFilters;

  // ── Book details cache ────────────────────
  final Map<String, BookModel> _bookCache = {};

  /// Returns a cached book if present, otherwise fetches and caches it.
  Future<BookModel?> getBook(String bookId, {bool refresh = false}) async {
    if (!refresh && _bookCache.containsKey(bookId)) {
      return _bookCache[bookId];
    }
    try {
      final book = await _books.getBook(bookId);
      if (book != null) _bookCache[bookId] = book;
      notifyListeners();
      return book;
    } on AppException catch (e) {
      developer.log('BookProvider.getBook error: ${e.message}');
      rethrow;
    }
  }

  BookModel? cachedBook(String bookId) => _bookCache[bookId];

  // ── Home load ─────────────────────────────

  /// Loads categories, bestsellers and new arrivals for the home screen.
  ///
  /// Runs the three requests in parallel; each section reports its own error so
  /// one failing section never blanks the whole home screen.
  Future<void> loadHome() async {
    await Future.wait([
      _loadCategories(),
      _loadBestsellers(),
      _loadNewArrivals(),
    ]);
  }

  Future<void> refreshHome() => loadHome();

  Future<void> _loadCategories() async {
    _setCategories(categories.loading());
    try {
      final list = await _categories.getCategories();
      _setCategories(AsyncState(data: list, hasLoadedOnce: true));
    } on AppException catch (e) {
      _setCategories(categories.failure(e.message));
    }
  }

  Future<void> _loadBestsellers() async {
    _setBestsellers(bestsellers.loading());
    try {
      final list = await _books.getBestsellers();
      _setBestsellers(AsyncState(data: list, hasLoadedOnce: true));
    } on AppException catch (e) {
      _setBestsellers(bestsellers.failure(e.message));
    }
  }

  Future<void> _loadNewArrivals() async {
    _setNewArrivals(newArrivals.loading());
    try {
      final list = await _books.getNewArrivals();
      _setNewArrivals(AsyncState(data: list, hasLoadedOnce: true));
    } on AppException catch (e) {
      _setNewArrivals(newArrivals.failure(e.message));
    }
  }

  // ── Catalog ───────────────

  /// Runs the current [_query] from the first page.
  Future<void> loadCatalog() async {
    _setCatalog(_catalog.loading());
    try {
      final page = await _books.fetchFirstPage(_query);
      _catalogItems
        ..clear()
        ..addAll(page.items);
      _hasMore = page.hasMore;
      _query = _query.copyWith(cursor: page.cursor);
      _setCatalog(
        AsyncState(data: List.of(_catalogItems), hasLoadedOnce: true),
      );
    } on AppException catch (e) {
      _setCatalog(_catalog.failure(e.message));
    }
  }

  /// Loads the next page and appends it.
  Future<void> loadMoreCatalog() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _books.queryBooks(_query);
      _catalogItems.addAll(page.items);
      _hasMore = page.hasMore;
      _query = _query.copyWith(cursor: page.cursor);
      _setCatalog(
        AsyncState(data: List.of(_catalogItems), hasLoadedOnce: true),
      );
    } on AppException catch (e) {
      _setCatalog(_catalog.failure(e.message));
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Applies a new search term and reloads the catalog.
  Future<void> search(String term) {
    _query = _query.copyWith(searchTerm: term, clearCursor: true);
    return loadCatalog();
  }

  /// One-shot search used by the dedicated Search screen.
  ///
  /// Unlike [search] this does **not** mutate the catalog query — it simply
  /// returns matching books so the search screen owns its own result list.
  Future<List<BookModel>> searchFor(String term, {int limit = 30}) {
    return _books.search(term, limit: limit);
  }

  /// Total number of books (admin dashboard stat).
  Future<int> countBooks() => _books.countBooks();

  /// Applies new filters/sort and reloads the catalog.
  Future<void> applyQuery(BookQuery query) {
    _query = query.copyWith(clearCursor: true);
    return loadCatalog();
  }

  /// Convenience for the filter sheet: sets individual fields.
  Future<void> updateFilters({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    BookSort? sort,
    bool? inStockOnly,
  }) {
    _query = _query.copyWith(
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      sort: sort,
      inStockOnly: inStockOnly,
      clearCursor: true,
    );
    return loadCatalog();
  }

  /// Clears search + filters back to the defaults and reloads.
  Future<void> clearFilters() => applyQuery(const BookQuery());

  /// Books in a category (used by the "see all" category screen).
  Future<List<BookModel>> getByCategory(String categoryId, {int limit = 20}) {
    return _books.getByCategory(categoryId, limit: limit);
  }

  /// Related books for the details screen.
  Future<List<BookModel>> getRelated(BookModel book) => _books.getRelated(book);

  // ── Setters ───────────────────────────────

  void _setCategories(AsyncState<List<CategoryModel>> s) {
    _categoriesState = s;
    notifyListeners();
  }

  void _setBestsellers(AsyncState<List<BookModel>> s) {
    _bestsellersState = s;
    notifyListeners();
  }

  void _setNewArrivals(AsyncState<List<BookModel>> s) {
    _newArrivalsState = s;
    notifyListeners();
  }

  void _setCatalog(AsyncState<List<BookModel>> s) {
    _catalog = s;
    notifyListeners();
  }
}
