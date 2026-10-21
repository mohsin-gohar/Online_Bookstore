/// A page of results for a paginated query.
///
/// The Laravel API paginates with page numbers. A cursor is still carried
/// alongside the page metadata so a repository's public interface stays the
/// same regardless of the active backend:
///
///  * [cursor] — the continuation token. For the Laravel API this is the page
///    number of the next page.
///  * [currentPage] / [lastPage] — page-based pagination metadata, read from
///    the API's `meta` block.
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.hasMore,
    this.cursor,
    this.total,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  final List<T> items;

  /// True when more documents exist beyond this page.
  final bool hasMore;

  /// Opaque continuation token (the next page number for the Laravel API).
  final Object? cursor;

  /// Optional total count when it has been computed.
  final int? total;

  /// 1-based index of this page (Laravel `meta.current_page`).
  final int currentPage;

  /// Total number of pages (Laravel `meta.last_page`).
  final int lastPage;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// An empty, terminal page (no items, nothing more to load).
  static PageResult<T> empty<T>() =>
      PageResult<T>(items: const [], hasMore: false);

  @override
  String toString() => 'PageResult(${items.length} items, hasMore: $hasMore)';
}
