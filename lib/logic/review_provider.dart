import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/models/review_model.dart';
import '../data/repositories/review_repository.dart';
import '../data/services/app_exceptions.dart';

/// Owns a book's reviews, the current user's review, and the like system.
class ReviewProvider extends ChangeNotifier {
  ReviewProvider({required ReviewRepository repository}) : _repo = repository;

  final ReviewRepository _repo;

  // Per-book review lists (so navigating between books doesn't thrash one list).
  final Map<String, List<ReviewModel>> _reviewsByBook = {};
  final Map<String, bool> _loadingByBook = {};
  final Map<String, String?> _errorByBook = {};

  bool _isMutating = false;
  String? _error;

  // ── State ─────────────────

  bool get isMutating => _isMutating;
  String? get error => _error;

  List<ReviewModel> reviewsFor(String bookId) =>
      _reviewsByBook[bookId] ?? const [];

  bool isLoadingFor(String bookId) => _loadingByBook[bookId] ?? false;

  String? errorFor(String bookId) => _errorByBook[bookId];

  /// Average rating computed from the currently-loaded reviews (0 when none).
  double averageFor(String bookId) {
    final list = reviewsFor(bookId);
    if (list.isEmpty) return 0;
    final total = list.fold<double>(0, (sum, r) => sum + r.rating);
    return double.parse((total / list.length).toStringAsFixed(2));
  }

  /// Count of loaded reviews for [bookId].
  int countFor(String bookId) => reviewsFor(bookId).length;

  /// Whether the given user has already reviewed [bookId] in the loaded list.
  ReviewModel? userReview(String bookId, String userId) {
    for (final r in reviewsFor(bookId)) {
      if (r.userId == userId) return r;
    }
    return null;
  }

  // ── Loads ─────────────────

  /// Loads reviews for [bookId] (cached per book).
  Future<void> loadReviews(String bookId, {bool refresh = false}) async {
    if (!refresh && _reviewsByBook.containsKey(bookId)) return;

    _loadingByBook[bookId] = true;
    _errorByBook[bookId] = null;
    notifyListeners();
    try {
      final list = await _repo.getBookReviews(bookId);
      _reviewsByBook[bookId] = list;
    } on AppException catch (e) {
      _errorByBook[bookId] = e.message;
    } catch (e, s) {
      developer.log(
        'ReviewProvider.loadReviews failed',
        error: e,
        stackTrace: s,
      );
      _errorByBook[bookId] = const UnknownException().message;
    } finally {
      _loadingByBook[bookId] = false;
      notifyListeners();
    }
  }

  /// Live subscription alternative to [loadReviews] (used by the details screen
  /// for real-time updates). The caller owns the subscription.
  Stream<List<ReviewModel>> watchReviews(String bookId) {
    return _repo.watchBookReviews(bookId);
  }

  // ── Mutations ─────────────

  /// Submits a new review. Returns the created review or null on failure.
  Future<ReviewModel?> addReview({
    required String bookId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
    String userPhoto = '',
  }) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      final review = ReviewModel(
        id: '',
        bookId: bookId,
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      );
      final created = await _repo.addReview(review);
      // Prepend to the cached list.
      _reviewsByBook[bookId] = [created, ...reviewsFor(bookId)];
      return created;
    } on AppException catch (e) {
      _error = e.message;
      return null;
    } catch (e, s) {
      developer.log('ReviewProvider.addReview failed', error: e, stackTrace: s);
      _error = const UnknownException().message;
      return null;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// Updates the current user's review.
  Future<bool> updateReview(ReviewModel review) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.updateReview(review);
      _replaceInCache(review);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (e, s) {
      developer.log(
        'ReviewProvider.updateReview failed',
        error: e,
        stackTrace: s,
      );
      _error = const UnknownException().message;
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// Deletes a review (owner or admin).
  Future<bool> deleteReview(String reviewId, String bookId) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.deleteReview(reviewId, bookId);
      final list = reviewsFor(bookId).where((r) => r.id != reviewId).toList();
      _reviewsByBook[bookId] = list;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (e, s) {
      developer.log(
        'ReviewProvider.deleteReview failed',
        error: e,
        stackTrace: s,
      );
      _error = const UnknownException().message;
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// Toggles [userId]'s like on [review].
  Future<bool> toggleLike(ReviewModel review, String userId) async {
    try {
      final updated = await _repo.toggleLike(review, userId);
      _replaceInCache(updated);
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e, s) {
      developer.log(
        'ReviewProvider.toggleLike failed',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  // ── Helpers ───────────────

  void _replaceInCache(ReviewModel review) {
    final list = reviewsFor(
      review.bookId,
    ).map((r) => r.id == review.id ? review : r).toList();
    _reviewsByBook[review.bookId] = list;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
