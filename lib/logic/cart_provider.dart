import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/models/book_model.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/cart_model.dart';
import '../data/repositories/cart_repository.dart';
import '../data/services/app_exceptions.dart';

/// Owns the current user's cart.
///
/// The cart is always keyed by the signed-in user's uid. When no user is signed
/// in, the cart is empty and mutating actions throw
/// [UnauthenticatedException] (the UI should prompt login first).
class CartProvider extends ChangeNotifier {
  CartProvider({required CartRepository repository}) : _repo = repository;

  final CartRepository _repo;

  CartModel _cart = const CartModel();
  String? _userId;

  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;

  // ── State ─────────────────

  CartModel get cart => _cart;
  List<CartItemModel> get items => _cart.items;
  int get itemCount => _cart.itemCount;
  double get subtotal => _cart.subtotal;
  bool get isEmpty => _cart.isEmpty;

  bool get isLoading => _isLoading;

  /// True while an add/update/remove is in flight (to disable buttons).
  bool get isMutating => _isMutating;
  String? get error => _error;

  bool get isAuthenticated => _userId != null;

  /// Whether [bookId] is in the cart.
  bool contains(String bookId) => _cart.contains(bookId);

  /// Quantity of [bookId] in the cart.
  int quantityOf(String bookId) => _cart.quantityOf(bookId);

  // ── Session ───────────────

  /// Called when auth state changes. Loads the cart for [userId], or clears it
  /// when the user signs out (pass null).
  Future<void> onUserChanged(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      _cart = const CartModel();
      notifyListeners();
      return;
    }
    await loadCart();
  }

  /// Loads the cart from the API.
  Future<void> loadCart() async {
    if (_userId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _cart = await _repo.getCart(_userId!);
    } on AppException catch (e) {
      _error = e.message;
    } catch (e, s) {
      developer.log('CartProvider.loadCart failed', error: e, stackTrace: s);
      _error = const UnknownException().message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mutations ─────────────

  /// Adds [book] to the cart. Returns true on success.
  Future<bool> addToCart(BookModel book, {int qty = 1}) async {
    if (!_requireAuth()) return false;
    if (book.isOutOfStock) {
      _error = 'This book is out of stock.';
      notifyListeners();
      return false;
    }
    return _mutate(() async {
      _cart = await _repo.addItem(_userId!, book, qty: qty);
    });
  }

  /// Increments the quantity of [bookId] by one.
  Future<bool> increment(String bookId) {
    final current = _cart.quantityOf(bookId);
    return updateQty(bookId, current + 1);
  }

  /// Decrements the quantity of [bookId] by one (removes at 0).
  Future<bool> decrement(String bookId) {
    final current = _cart.quantityOf(bookId);
    return updateQty(bookId, current - 1);
  }

  /// Sets the quantity of [bookId].
  Future<bool> updateQty(String bookId, int qty) async {
    if (!_requireAuth()) return false;
    return _mutate(() async {
      _cart = await _repo.updateQty(_userId!, bookId, qty);
    });
  }

  /// Removes [bookId] from the cart.
  Future<bool> removeFromCart(String bookId) async {
    if (!_requireAuth()) return false;
    return _mutate(() async {
      _cart = await _repo.removeItem(_userId!, bookId);
    });
  }

  /// Empties the cart.
  Future<bool> clearCart() async {
    if (!_requireAuth()) return false;
    return _mutate(() async {
      _cart = await _repo.clear(_userId!);
    });
  }

  /// Called after a successful checkout to empty the local cart immediately.
  void clearLocal() {
    _cart = const CartModel();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ── Internals ─────────────

  bool _requireAuth() {
    if (_userId == null) {
      _error = const UnauthenticatedException().message;
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Runs [action] with mutation bookkeeping; returns success/failure.
  Future<bool> _mutate(Future<void> Function() action) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (e, s) {
      developer.log('CartProvider mutation failed', error: e, stackTrace: s);
      _error = const UnknownException().message;
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
