import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/models/book_model.dart';
import '../data/models/wishlist_item_model.dart';
import '../data/models/wishlist_model.dart';
import '../data/repositories/wishlist_repository.dart';
import '../data/services/app_exceptions.dart';

/// Owns the current user's wishlist.
class WishlistProvider extends ChangeNotifier {
  WishlistProvider({required WishlistRepository repository})
    : _repo = repository;

  final WishlistRepository _repo;

  WishlistModel _wishlist = const WishlistModel();
  String? _userId;

  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;

  // ── State ─────────────────

  WishlistModel get wishlist => _wishlist;
  List<WishlistItemModel> get items => _wishlist.items;
  int get count => _wishlist.count;
  bool get isEmpty => _wishlist.isEmpty;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;

  /// Whether [bookId] is saved.
  bool contains(String bookId) => _wishlist.contains(bookId);

  // ── Session ───────────────

  Future<void> onUserChanged(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      _wishlist = const WishlistModel();
      notifyListeners();
      return;
    }
    await loadWishlist();
  }

  Future<void> loadWishlist() async {
    if (_userId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _wishlist = await _repo.getWishlist(_userId!);
    } on AppException catch (e) {
      _error = e.message;
    } catch (e, s) {
      developer.log(
        'WishlistProvider.loadWishlist failed',
        error: e,
        stackTrace: s,
      );
      _error = const UnknownException().message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mutations ─────────────

  /// Toggles [book] in the wishlist. Returns true on success.
  Future<bool> toggle(BookModel book) async {
    if (!_requireAuth()) return false;
    return _mutate(() async {
      _wishlist = await _repo.toggle(_userId!, book);
    });
  }

  /// Adds [book] to the wishlist.
  Future<bool> add(BookModel book) async {
    if (!_requireAuth()) return false;
    return _mutate(() async {
      _wishlist = await _repo.addItem(_userId!, book);
    });
  }

  /// Removes [bookId] from the wishlist.
  Future<bool> remove(String bookId) async {
    if (!_requireAuth()) return false;
    return _mutate(() async {
      _wishlist = await _repo.removeItem(_userId!, bookId);
    });
  }

  /// Empties the wishlist.
  Future<bool> clear() async {
    if (!_requireAuth()) return false;
    return _mutate(() async {
      _wishlist = await _repo.clear(_userId!);
    });
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
      developer.log(
        'WishlistProvider mutation failed',
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
}
