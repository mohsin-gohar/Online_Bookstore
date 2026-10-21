import 'dart:async';

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/book_model.dart';
import '../models/page_result.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';
import 'user_repository.dart' show pollStream;

/// The sort orders offered by the catalog.
///
/// The labels match the wording used in the project specification so the UI
/// and the API agree on one vocabulary.
enum BookSort {
  newest,
  oldest,
  priceLowHigh,
  priceHighLow,
  popularity,
  rating;

  /// Human-readable label shown in the sort menu.
  String get label {
    switch (this) {
      case BookSort.newest:
        return 'Release date: newest';
      case BookSort.oldest:
        return 'Release date: oldest';
      case BookSort.priceLowHigh:
        return 'Price: low to high';
      case BookSort.priceHighLow:
        return 'Price: high to low';
      case BookSort.popularity:
        return 'Most popular';
      case BookSort.rating:
        return 'Top rated';
    }
  }

  /// The `sort` value sent to the Laravel API.
  String get apiValue {
    switch (this) {
      case BookSort.newest:
        return 'newest';
      case BookSort.oldest:
        return 'oldest';
      case BookSort.priceLowHigh:
        return 'price_low_high';
      case BookSort.priceHighLow:
        return 'price_high_low';
      case BookSort.popularity:
        return 'popularity';
      case BookSort.rating:
        return 'rating';
    }
  }
}

/// The filter + sort state of the catalog.
class BookQuery {
  const BookQuery({
    this.searchTerm = '',
    this.categoryId,
    this.authorId,
    this.authorName,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sort = BookSort.newest,
    this.bestsellersOnly = false,
    this.newArrivalsOnly = false,
    this.inStockOnly = false,
    this.pageSize = ApiConstants.catalogPerPage,
    this.cursor,
  });

  /// Free-text search across title, author and genre.
  final String searchTerm;

  final String? categoryId;

  /// Restricts the results to one author.
  final String? authorId;

  /// Free-text author filter (used when the author is known by name only).
  final String? authorName;

  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final BookSort sort;
  final bool bestsellersOnly;
  final bool newArrivalsOnly;
  final bool inStockOnly;
  final int pageSize;

  /// The page number to load (Laravel pagination).
  final Object? cursor;

  bool get hasActiveFilters =>
      (categoryId != null && categoryId!.isNotEmpty) ||
      (authorId != null && authorId!.isNotEmpty) ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      bestsellersOnly ||
      newArrivalsOnly ||
      inStockOnly;

  /// The query parameters sent to `GET /books`.
  Map<String, dynamic> toQueryParameters({int? page}) {
    final Map<String, dynamic> params = <String, dynamic>{
      'per_page': pageSize,
      'sort': sort.apiValue,
    };

    final String term = searchTerm.trim();
    if (term.isNotEmpty) params['search'] = term;

    if (categoryId != null && categoryId!.isNotEmpty) {
      params['category_id'] = categoryId;
    }
    if (authorId != null && authorId!.isNotEmpty) {
      params['author_id'] = authorId;
    }
    if (authorName != null && authorName!.trim().isNotEmpty) {
      params['author'] = authorName!.trim();
    }
    if (minPrice != null) params['min_price'] = minPrice;
    if (maxPrice != null) params['max_price'] = maxPrice;
    if (minRating != null) params['min_rating'] = minRating;
    if (bestsellersOnly) params['bestsellers'] = 1;
    if (newArrivalsOnly) params['new_arrivals'] = 1;
    if (inStockOnly) params['in_stock'] = 1;

    final int? pageNumber = page ?? (cursor is int ? cursor as int : null);
    if (pageNumber != null && pageNumber > 1) params['page'] = pageNumber;

    return params;
  }

  BookQuery copyWith({
    String? searchTerm,
    String? categoryId,
    String? authorId,
    String? authorName,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    BookSort? sort,
    bool? bestsellersOnly,
    bool? newArrivalsOnly,
    bool? inStockOnly,
    int? pageSize,
    Object? cursor,
    bool clearCursor = false,
    bool clearAuthor = false,
    bool clearCategory = false,
  }) {
    return BookQuery(
      searchTerm: searchTerm ?? this.searchTerm,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      authorId: clearAuthor ? null : (authorId ?? this.authorId),
      authorName: clearAuthor ? null : (authorName ?? this.authorName),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      sort: sort ?? this.sort,
      bestsellersOnly: bestsellersOnly ?? this.bestsellersOnly,
      newArrivalsOnly: newArrivalsOnly ?? this.newArrivalsOnly,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      pageSize: pageSize ?? this.pageSize,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
    );
  }
}

/// Reads and writes the book catalogue.
///
/// Backed by `GET /books`, `GET /books/{id}` and the admin book endpoints.
class BookRepository {
  BookRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  /// Fetches a single book, or null when it does not exist.
  Future<BookModel?> getBook(String bookId) async {
    if (bookId.isEmpty) return null;
    try {
      final ApiResponse response = await _api.get(ApiConstants.book(bookId));
      if (response.data == null) return null;
      return BookModel.fromMap(response.map, id: bookId);
    } catch (_) {
      return null;
    }
  }

  /// Live view of a single book (polls while listened to).
  Stream<BookModel?> watchBook(String bookId) {
    return pollStream<BookModel?>(
      fetch: () => getBook(bookId),
      interval: const Duration(seconds: 30),
    );
  }

  /// Runs a filtered, sorted, paginated catalog query.
  Future<PageResult<BookModel>> queryBooks(BookQuery query) async {
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.books,
        query: query.toQueryParameters(),
      );
      return response.toPageResult<BookModel>(
        (Map<String, dynamic> m) => BookModel.fromMap(m),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException('Could not load books.');
    }
  }

  /// Loads the first page of [query] (cursor cleared).
  Future<PageResult<BookModel>> fetchFirstPage(BookQuery query) =>
      queryBooks(query.copyWith(clearCursor: true));

  /// The current bestsellers.
  Future<List<BookModel>> getBestsellers({int limit = 10}) async {
    try {
      final PageResult<BookModel> page = await queryBooks(
        BookQuery(bestsellersOnly: true, pageSize: limit),
      );
      if (page.items.isEmpty) {
        final PageResult<BookModel> fallback = await queryBooks(
          BookQuery(pageSize: limit),
        );
        return fallback.items;
      }
      return page.items;
    } catch (_) {
      return const [];
    }
  }

  /// The newest additions.
  Future<List<BookModel>> getNewArrivals({int limit = 10}) async {
    try {
      final PageResult<BookModel> page = await queryBooks(
        BookQuery(newArrivalsOnly: true, pageSize: limit),
      );
      if (page.items.isEmpty) {
        final PageResult<BookModel> fallback = await queryBooks(
          BookQuery(pageSize: limit),
        );
        return fallback.items;
      }
      return page.items;
    } catch (_) {
      return const [];
    }
  }

  /// The books in one category.
  Future<List<BookModel>> getByCategory(
    String categoryId, {
    int limit = 20,
  }) async {
    final PageResult<BookModel> page = await queryBooks(
      BookQuery(categoryId: categoryId, pageSize: limit),
    );
    return page.items;
  }

  /// The books by one author.
  Future<List<BookModel>> getByAuthor(String authorId, {int limit = 20}) async {
    final PageResult<BookModel> page = await queryBooks(
      BookQuery(authorId: authorId, pageSize: limit),
    );
    return page.items;
  }

  /// Free-text search across title, author and genre.
  Future<List<BookModel>> search(String term, {int limit = 30}) async {
    if (term.trim().isEmpty) return const [];
    final PageResult<BookModel> page = await queryBooks(
      BookQuery(searchTerm: term, pageSize: limit),
    );
    return page.items;
  }

  /// Books related to [book] — same category, excluding the book itself.
  Future<List<BookModel>> getRelated(BookModel book, {int limit = 8}) async {
    if (book.categoryId.isEmpty) return const [];
    final PageResult<BookModel> page = await queryBooks(
      BookQuery(categoryId: book.categoryId, pageSize: limit + 1),
    );
    return page.items
        .where((BookModel b) => b.id != book.id)
        .take(limit)
        .toList();
  }

  /// The total number of books in the catalogue.
  Future<int> countBooks() async {
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.books,
        query: <String, dynamic>{'per_page': 1},
      );
      return response.pagination.total;
    } catch (_) {
      return 0;
    }
  }

  /// Creates a book (admin).
  Future<String> createBook(BookModel book) async {
    _validateBook(book);
    final ApiResponse response = await _api.post(
      ApiConstants.adminBooks,
      body: book.toMap(),
    );
    final String id = response.map['id']?.toString() ?? '';
    return id.isEmpty ? book.id : id;
  }

  /// Updates a book (admin).
  Future<void> updateBook(BookModel book) async {
    if (book.id.isEmpty) throw const ValidationException('Missing book id.');
    _validateBook(book);
    await _api.put(ApiConstants.adminBook(book.id), body: book.toMap());
  }

  /// Deletes a book (admin).
  Future<void> deleteBook(String bookId) async {
    if (bookId.isEmpty) throw const ValidationException('Missing book id.');
    await _api.delete(ApiConstants.adminBook(bookId));
  }

  /// Adjusts the stock of [bookId] by [delta].
  Future<void> adjustStock(String bookId, int delta) async {
    final BookModel? book = await getBook(bookId);
    if (book == null) return;
    final int newStock = (book.stock + delta).clamp(0, 999999);
    await updateBook(book.copyWith(stock: newStock));
  }

  /// Updates the denormalised rating of a book.
  Future<void> updateRatingAggregate(
    String bookId, {
    required double rating,
    required int reviewCount,
  }) async {
    try {
      await _api.patch(
        ApiConstants.adminBook(bookId),
        body: <String, dynamic>{'rating': rating, 'review_count': reviewCount},
      );
    } catch (_) {
      // The aggregate is a convenience; the server recomputes it anyway.
    }
  }

  void _validateBook(BookModel book) {
    if (book.title.trim().isEmpty) {
      throw const ValidationException('Book title is required.');
    }
    if (book.author.trim().isEmpty) {
      throw const ValidationException('Book author is required.');
    }
    if (book.price < 0) {
      throw const ValidationException('Price cannot be negative.');
    }
  }
}
