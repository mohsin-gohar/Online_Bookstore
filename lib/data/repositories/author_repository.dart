import 'dart:async';

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/author_model.dart';
import '../models/book_model.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';

/// Reads the catalogue's authors.
///
/// Backed by `GET /authors`, `GET /authors/{id}` and the admin author
/// endpoints.
class AuthorRepository {
  AuthorRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  /// All authors, ordered by name.
  Future<List<AuthorModel>> getAuthors() async {
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.authors,
        query: <String, dynamic>{'per_page': 100},
      );
      return response.list
          .map((Map<String, dynamic> m) => AuthorModel.fromMap(m))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// A single author, or null.
  Future<AuthorModel?> getAuthor(String authorId) async {
    if (authorId.isEmpty) return null;
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.author(authorId),
      );
      if (response.data == null) return null;
      return AuthorModel.fromMap(response.map, id: authorId);
    } catch (_) {
      return null;
    }
  }

  /// Searches authors by name.
  Future<List<AuthorModel>> searchAuthors(String term, {int limit = 30}) async {
    if (term.trim().isEmpty) return const [];
    final ApiResponse response = await _api.get(
      ApiConstants.authors,
      query: <String, dynamic>{'search': term.trim(), 'per_page': limit},
    );
    return response.list
        .map((Map<String, dynamic> m) => AuthorModel.fromMap(m))
        .toList(growable: false);
  }

  /// The books written by [authorId].
  Future<List<BookModel>> getBooksByAuthor(
    String authorId, {
    int limit = 20,
  }) async {
    final ApiResponse response = await _api.get(
      ApiConstants.books,
      query: <String, dynamic>{'author_id': authorId, 'per_page': limit},
    );
    return response.list
        .map((Map<String, dynamic> m) => BookModel.fromMap(m))
        .toList(growable: false);
  }

  /// The number of authors.
  Future<int> countAuthors() async {
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.authors,
        query: <String, dynamic>{'per_page': 1},
      );
      final int total = response.pagination.total;
      return total > 0 ? total : (response.isList ? response.list.length : 0);
    } catch (_) {
      return 0;
    }
  }

  /// Creates an author (admin).
  Future<String> createAuthor(AuthorModel author) async {
    _validate(author);
    final ApiResponse response = await _api.post(
      ApiConstants.adminAuthors,
      body: author.toMap(),
    );
    final String id = response.map['id']?.toString() ?? '';
    return id.isEmpty ? author.id : id;
  }

  /// Updates an author (admin).
  Future<void> updateAuthor(AuthorModel author) async {
    if (author.id.isEmpty) {
      throw const ValidationException('Missing author id.');
    }
    _validate(author);
    await _api.put(ApiConstants.adminAuthor(author.id), body: author.toMap());
  }

  /// Deletes an author (admin).
  Future<void> deleteAuthor(String authorId) async {
    if (authorId.isEmpty) throw const ValidationException('Missing author id.');
    await _api.delete(ApiConstants.adminAuthor(authorId));
  }

  void _validate(AuthorModel author) {
    if (author.name.trim().isEmpty) {
      throw const ValidationException('Author name is required.');
    }
  }
}
