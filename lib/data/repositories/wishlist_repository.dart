import 'dart:async';
import 'dart:developer' as developer;

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/book_model.dart';
import '../models/wishlist_item_model.dart';
import '../models/wishlist_model.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';
import 'user_repository.dart' show pollStream;

/// Manages the signed-in user's wishlist.
///
/// Backed by `GET /wishlist`, `POST /wishlist/{book_id}` and
/// `DELETE /wishlist/{book_id}`.
class WishlistRepository {
  WishlistRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  /// Loads the wishlist (empty when there is none).
  Future<WishlistModel> getWishlist(String userId) async {
    if (userId.isEmpty) throw const UnauthenticatedException();
    try {
      final ApiResponse response = await _api.get(ApiConstants.wishlist);
      return _fromResponse(response, userId);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'WishlistRepository.getWishlist failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not load your wishlist.');
    }
  }

  /// Live view of the wishlist.
  Stream<WishlistModel> watchWishlist(String userId) {
    return pollStream<WishlistModel>(
      fetch: () => getWishlist(userId),
      interval: const Duration(seconds: 15),
    );
  }

  /// Adds [book] to the wishlist (no-op when already present).
  Future<WishlistModel> addItem(String userId, BookModel book) async {
    final ApiResponse response = await _api.post(
      ApiConstants.wishlistItem(book.id),
      body: <String, dynamic>{'book_id': book.id},
    );
    return _fromResponse(response, userId);
  }

  /// Removes [bookId] from the wishlist.
  Future<WishlistModel> removeItem(String userId, String bookId) async {
    final ApiResponse response = await _api.delete(
      ApiConstants.wishlistItem(bookId),
    );
    return _fromResponse(response, userId);
  }

  /// Toggles [book] in the wishlist; returns the resulting wishlist.
  Future<WishlistModel> toggle(String userId, BookModel book) async {
    final WishlistModel wishlist = await getWishlist(userId);
    if (wishlist.contains(book.id)) {
      return removeItem(userId, book.id);
    }
    return addItem(userId, book);
  }

  /// Removes every item.
  Future<WishlistModel> clear(String userId) async {
    if (userId.isEmpty) throw const UnauthenticatedException();
    try {
      final ApiResponse response = await _api.delete(ApiConstants.wishlist);
      return _fromResponse(response, userId);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log('WishlistRepository.clear failed', error: e, stackTrace: s);
      throw const ServerException('Could not clear your wishlist.');
    }
  }

  /// The live API returns the wishlist as a bare `data[]` list, while the
  /// mock transport wraps it in `{userId, items}`; accept both.
  WishlistModel _fromResponse(ApiResponse response, String userId) {
    if (response.data == null) return WishlistModel.empty(userId);
    if (response.isList) {
      return WishlistModel(
        userId: userId,
        items: response.list
            .map(WishlistItemModel.fromMap)
            .toList(growable: false),
      );
    }
    return WishlistModel.fromMap(response.map, userId: userId);
  }
}
