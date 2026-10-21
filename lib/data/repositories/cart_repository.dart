import 'dart:async';
import 'dart:developer' as developer;

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/book_model.dart';
import '../models/cart_model.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';
import 'user_repository.dart' show pollStream;

/// Manages the signed-in user's cart.
///
/// Backed by `GET /cart`, `POST /cart/items`, `PATCH /cart/items/{book_id}`
/// and `DELETE /cart/items/{book_id}`. The cart belongs to the authenticated
/// user — the server derives it from the bearer token, never from a
/// client-supplied id.
class CartRepository {
  CartRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  /// Loads the user's cart (empty when there is none).
  Future<CartModel> getCart(String userId) async {
    if (userId.isEmpty) throw const UnauthenticatedException();
    try {
      final ApiResponse response = await _api.get(ApiConstants.cart);
      if (response.data == null) return CartModel.empty(userId);
      return CartModel.fromMap(response.map, userId: userId);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log('CartRepository.getCart failed', error: e, stackTrace: s);
      throw const ServerException('Could not load your cart.');
    }
  }

  /// Live view of the user's cart.
  Stream<CartModel> watchCart(String userId) {
    return pollStream<CartModel>(
      fetch: () => getCart(userId),
      interval: const Duration(seconds: 15),
    );
  }

  /// Adds [book] to the cart (increments the quantity when already present).
  Future<CartModel> addItem(
    String userId,
    BookModel book, {
    int qty = 1,
  }) async {
    if (book.isOutOfStock) {
      throw const ValidationException('This book is out of stock.');
    }

    final ApiResponse response = await _api.post(
      ApiConstants.cartItems,
      body: <String, dynamic>{
        'book_id': book.id,
        'qty': qty.clamp(1, book.stock),
      },
    );

    return CartModel.fromMap(response.map, userId: userId);
  }

  /// Sets the quantity of [bookId] to [qty]. A quantity of zero removes the
  /// item.
  Future<CartModel> updateQty(String userId, String bookId, int qty) async {
    if (qty <= 0) return removeItem(userId, bookId);

    final ApiResponse response = await _api.patch(
      ApiConstants.cartItem(bookId),
      body: <String, dynamic>{'qty': qty},
    );

    return CartModel.fromMap(response.map, userId: userId);
  }

  /// Removes [bookId] from the cart.
  Future<CartModel> removeItem(String userId, String bookId) async {
    final ApiResponse response = await _api.delete(
      ApiConstants.cartItem(bookId),
    );
    if (response.data == null) return CartModel.empty(userId);
    return CartModel.fromMap(response.map, userId: userId);
  }

  /// Removes every item from the cart.
  Future<CartModel> clear(String userId) async {
    if (userId.isEmpty) throw const UnauthenticatedException();
    try {
      final ApiResponse response = await _api.delete(ApiConstants.cart);
      if (response.data == null) return CartModel.empty(userId);
      return CartModel.fromMap(response.map, userId: userId);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log('CartRepository.clear failed', error: e, stackTrace: s);
      throw const ServerException('Could not clear your cart.');
    }
  }
}
