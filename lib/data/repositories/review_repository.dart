import 'dart:async';
import 'dart:developer' as developer;

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/review_model.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';
import 'book_repository.dart';
import 'user_repository.dart' show pollStream;

/// Reads and writes book reviews.
///
/// Backed by `GET/POST /books/{id}/reviews`, `PUT/DELETE /reviews/{id}` and
/// `POST /reviews/{id}/like`.
class ReviewRepository {
  ReviewRepository({ApiTransport? transport, BookRepository? bookRepository})
    : _api = transport ?? ApiFactory.transport,
      _books = bookRepository ?? BookRepository(transport: transport);

  final ApiTransport _api;
  final BookRepository _books;

  /// Fetches reviews for a book, newest first.
  Future<List<ReviewModel>> getBookReviews(
    String bookId, {
    int limit = 50,
  }) async {
    if (bookId.isEmpty) throw const ValidationException('Missing book id.');
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.bookReviews(bookId),
        query: <String, dynamic>{'per_page': limit},
      );
      return response.list
          .map((Map<String, dynamic> m) => ReviewModel.fromMap(m))
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'ReviewRepository.getBookReviews failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not load reviews.');
    }
  }

  /// Live view of a book's reviews.
  Stream<List<ReviewModel>> watchBookReviews(String bookId) {
    return pollStream<List<ReviewModel>>(
      fetch: () => getBookReviews(bookId),
      interval: const Duration(seconds: 20),
    );
  }

  /// The current user's existing review for [bookId], or null.
  Future<ReviewModel?> getUserReview(String bookId, String userId) async {
    final List<ReviewModel> reviews = await getBookReviews(bookId);
    for (final ReviewModel review in reviews) {
      if (review.userId == userId) return review;
    }
    return null;
  }

  /// Total number of reviews (admin dashboard).
  Future<int> countReviews() async {
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.reviews,
        query: <String, dynamic>{'per_page': 1},
      );
      return response.pagination.total;
    } catch (_) {
      return 0;
    }
  }

  // ── Writes ────────────────────────────────

  /// Adds a review for a book.
  ///
  /// One review per user per book is enforced by the server.
  Future<ReviewModel> addReview(ReviewModel review) async {
    _validate(review);
    try {
      final ApiResponse response = await _api.post(
        ApiConstants.bookReviews(review.bookId),
        body: <String, dynamic>{
          'book_id': review.bookId,
          'rating': review.rating,
          'comment': review.comment,
        },
      );
      await _refreshBookRating(review.bookId);
      return ReviewModel.fromMap(response.map);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'ReviewRepository.addReview failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not submit your review.');
    }
  }

  /// Updates an existing review (rating/comment).
  Future<void> updateReview(ReviewModel review) async {
    if (review.id.isEmpty) {
      throw const ValidationException('Missing review id.');
    }
    _validate(review);
    try {
      await _api.put(
        ApiConstants.review(review.id),
        body: <String, dynamic>{
          'rating': review.rating,
          'comment': review.comment,
        },
      );
      await _refreshBookRating(review.bookId);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'ReviewRepository.updateReview failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not update your review.');
    }
  }

  /// Deletes a review.
  Future<void> deleteReview(String reviewId, String bookId) async {
    await _api.delete(ApiConstants.review(reviewId));
    await _refreshBookRating(bookId);
  }

  /// Toggles the signed-in user's like on [review].
  Future<ReviewModel> toggleLike(ReviewModel review, String userId) async {
    if (userId.isEmpty) throw const UnauthenticatedException();
    try {
      final ApiResponse response = await _api.post(
        ApiConstants.reviewLike(review.id),
      );
      return ReviewModel.fromMap(response.map, id: review.id);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'ReviewRepository.toggleLike failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not update your reaction.');
    }
  }

  // ── Internals ─────────────────────────────

  /// Recomputes a book's average rating and review count.
  Future<void> _refreshBookRating(String bookId) async {
    try {
      final List<ReviewModel> reviews = await getBookReviews(
        bookId,
        limit: 200,
      );
      if (reviews.isEmpty) {
        await _books.updateRatingAggregate(bookId, rating: 0, reviewCount: 0);
        return;
      }
      final double total = reviews.fold<double>(
        0,
        (double sum, ReviewModel r) => sum + r.rating,
      );
      final double avg = total / reviews.length;
      await _books.updateRatingAggregate(
        bookId,
        rating: double.parse(avg.toStringAsFixed(2)),
        reviewCount: reviews.length,
      );
    } catch (e, s) {
      // The aggregate refresh is best-effort — never fail the review write.
      developer.log(
        'ReviewRepository._refreshBookRating failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  void _validate(ReviewModel review) {
    if (review.bookId.isEmpty) {
      throw const ValidationException('Missing book id.');
    }
    if (review.userId.isEmpty) {
      throw const UnauthenticatedException();
    }
    if (review.rating < 1 || review.rating > 5) {
      throw const ValidationException('Rating must be between 1 and 5 stars.');
    }
    if (review.comment.trim().isEmpty) {
      throw const ValidationException('Please write a short comment.');
    }
  }
}
