import 'dart:async';

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/category_model.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';
import 'user_repository.dart' show pollStream;

/// Reads and writes the catalogue's genres.
///
/// Backed by `GET /categories` and the admin category endpoints.
class CategoryRepository {
  CategoryRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  /// All categories, ordered by name.
  Future<List<CategoryModel>> getCategories() async {
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.categories,
        query: <String, dynamic>{'per_page': 100},
      );
      return response.list
          .map((Map<String, dynamic> m) => CategoryModel.fromMap(m))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Live view of the categories (polls while listened to).
  Stream<List<CategoryModel>> watchCategories() {
    return pollStream<List<CategoryModel>>(
      fetch: getCategories,
      interval: const Duration(seconds: 30),
    );
  }

  /// A single category, or null.
  Future<CategoryModel?> getCategory(String categoryId) async {
    if (categoryId.isEmpty) return null;
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.category(categoryId),
      );
      if (response.data == null) return null;
      return CategoryModel.fromMap(response.map, id: categoryId);
    } catch (_) {
      return null;
    }
  }

  /// The number of categories.
  Future<int> countCategories() async {
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.categories,
        query: <String, dynamic>{'per_page': 1},
      );
      final int total = response.pagination.total;
      return total > 0 ? total : (response.isList ? response.list.length : 0);
    } catch (_) {
      return 0;
    }
  }

  /// Creates a category (admin).
  Future<String> createCategory(CategoryModel category) async {
    _validate(category);
    final ApiResponse response = await _api.post(
      ApiConstants.adminCategories,
      body: category.toMap(),
    );
    final String id = response.map['id']?.toString() ?? '';
    return id.isEmpty ? category.id : id;
  }

  /// Updates a category (admin).
  Future<void> updateCategory(CategoryModel category) async {
    if (category.id.isEmpty) {
      throw const ValidationException('Missing category id.');
    }
    _validate(category);
    await _api.put(
      ApiConstants.adminCategory(category.id),
      body: category.toMap(),
    );
  }

  /// Deletes a category (admin).
  ///
  /// The server refuses to delete a category that still has books.
  Future<void> deleteCategory(String categoryId) async {
    if (categoryId.isEmpty) return;
    await _api.delete(ApiConstants.adminCategory(categoryId));
  }

  void _validate(CategoryModel category) {
    if (category.name.trim().isEmpty) {
      throw const ValidationException('Category name is required.');
    }
  }
}
