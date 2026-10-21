import 'dart:developer' as developer;

import '../models/book_model.dart';
import '../models/category_model.dart';
import '../models/page_result.dart';
import '../mock/demo_catalog.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';

/// Creates the bundled demo catalogue on the server when it is missing.
///
/// This replaces the old "seed" helper: the same rows are
/// inserted through the **admin API** (`POST /admin/categories`,
/// `POST /admin/books`), so a Laravel backend can be populated from the app
/// itself — handy while developing, and it keeps the admin dashboard's
/// "Add sample data" button working.
///
/// Existing records are never overwritten.
class SampleDataService {
  SampleDataService({
    required CategoryRepository categoryRepository,
    required BookRepository bookRepository,
  }) : _categories = categoryRepository,
       _books = bookRepository;

  final CategoryRepository _categories;
  final BookRepository _books;

  /// Creates the missing categories and books. Returns how many were added.
  Future<int> seedAll() async {
    int created = 0;

    try {
      final List<CategoryModel> existing = await _categories.getCategories();
      final Set<String> existingCategoryIds = existing
          .map((CategoryModel c) => c.id)
          .toSet();

      for (final Map<String, dynamic> row in demoCategories) {
        if (existingCategoryIds.contains(row['id'])) continue;
        final CategoryModel category = CategoryModel.fromMap(row);
        await _categories.createCategory(category);
        created++;
      }

      final PageResult<BookModel> books = await _books.queryBooks(
        const BookQuery(pageSize: 200),
      );
      final Set<String> existingBookIds = books.items
          .map((BookModel b) => b.id)
          .toSet();

      for (final Map<String, dynamic> row in demoBooks) {
        if (existingBookIds.contains(row['id'])) continue;
        final BookModel book = BookModel.fromMap(row);
        await _books.createBook(book);
        created++;
      }
    } catch (e, s) {
      developer.log(
        'SampleDataService.seedAll failed',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }

    return created;
  }
}
