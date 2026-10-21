import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/models/order_model.dart';
import '../data/models/order_status.dart';
import '../data/repositories/order_repository.dart';
import '../data/services/app_exceptions.dart';

/// Signature for the optional order-status-change hook (wired to the
/// notification system in `app.dart`).
typedef OrderStatusChangedCallback =
    void Function(OrderModel order, OrderStatus previous, OrderStatus next);

/// Owns order placement, order history and admin status updates.
class OrderProvider extends ChangeNotifier {
  OrderProvider({required OrderRepository repository, this.onStatusChanged})
    : _repo = repository;

  /// Invoked after an order's status changes so callers can raise a
  /// notification. Kept as a callback to avoid a provider-to-provider coupling.
  /// Settable so a `ChangeNotifierProxyProvider` can (re)inject it.
  OrderStatusChangedCallback? onStatusChanged;

  final OrderRepository _repo;

  // Customer history
  final List<OrderModel> _orders = [];
  bool _isLoadingOrders = false;
  bool _hasMoreOrders = false;
  Object? _ordersCursor;
  String? _ordersError;

  // Checkout
  bool _isPlacingOrder = false;
  String? _checkoutError;
  OrderModel? _lastPlacedOrder;

  // Admin
  final List<OrderModel> _adminOrders = [];
  bool _isLoadingAdmin = false;
  OrderStatus? _adminStatusFilter;

  // ── State getters ─────────

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoadingOrders => _isLoadingOrders;
  bool get hasMoreOrders => _hasMoreOrders;
  String? get ordersError => _ordersError;
  bool get hasOrders => _orders.isNotEmpty;

  bool get isPlacingOrder => _isPlacingOrder;
  String? get checkoutError => _checkoutError;
  OrderModel? get lastPlacedOrder => _lastPlacedOrder;

  List<OrderModel> get adminOrders => List.unmodifiable(_adminOrders);
  bool get isLoadingAdminOrders => _isLoadingAdmin;
  OrderStatus? get adminStatusFilter => _adminStatusFilter;

  // ── Customer: history ─────

  /// Loads (or reloads) the first page of [userId]'s orders.
  Future<void> loadUserOrders(String userId, {bool refresh = false}) async {
    if (refresh) {
      _orders.clear();
      _ordersCursor = null;
    }
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();
    try {
      final page = await _repo.getUserOrders(userId, cursor: _ordersCursor);
      _orders.addAll(page.items);
      _hasMoreOrders = page.hasMore;
      _ordersCursor = page.cursor;
    } on AppException catch (e) {
      _ordersError = e.message;
    } catch (e, s) {
      developer.log(
        'OrderProvider.loadUserOrders failed',
        error: e,
        stackTrace: s,
      );
      _ordersError = const UnknownException().message;
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  /// Loads the next page of the user's orders.
  Future<void> loadMoreUserOrders(String userId) async {
    if (_isLoadingOrders || !_hasMoreOrders) return;
    await loadUserOrders(userId);
  }

  /// Fetches a single order (details screen).
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      return await _repo.getOrder(orderId);
    } on AppException catch (e) {
      developer.log('OrderProvider.getOrder error: ${e.message}');
      return null;
    }
  }

  /// Live stream of an order for the tracking screen.
  Stream<OrderModel?> watchOrder(String orderId) => _repo.watchOrder(orderId);

  // ── Customer: checkout ────

  /// Places [order]. On success, stores it in [lastPlacedOrder] and prepends it
  /// to the local history list. Returns the created order, or null on failure.
  Future<OrderModel?> placeOrder(OrderModel order) async {
    _isPlacingOrder = true;
    _checkoutError = null;
    notifyListeners();
    try {
      final created = await _repo.placeOrder(order);
      _lastPlacedOrder = created;
      _orders.insert(0, created);
      return created;
    } on AppException catch (e) {
      _checkoutError = e.message;
      return null;
    } catch (e, s) {
      developer.log('OrderProvider.placeOrder failed', error: e, stackTrace: s);
      _checkoutError = const UnknownException().message;
      return null;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  /// Cancels an order (customer action) and updates the local list.
  Future<bool> cancelOrder(String orderId, {String reason = ''}) async {
    try {
      final updated = await _repo.cancelOrder(orderId, reason: reason);
      _replaceInLists(updated);
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _checkoutError = e.message;
      notifyListeners();
      return false;
    }
  }

  // ── Admin ─────────────────

  /// Loads orders for the admin dashboard, optionally filtered by status.
  Future<void> loadAdminOrders({
    OrderStatus? status,
    bool refresh = true,
  }) async {
    if (refresh) {
      _adminOrders.clear();
      _adminStatusFilter = status;
    }
    _isLoadingAdmin = true;
    notifyListeners();
    try {
      final page = await _repo.getAllOrders(
        status: status ?? _adminStatusFilter,
      );
      _adminOrders
        ..clear()
        ..addAll(page.items);
    } on AppException catch (e) {
      developer.log('OrderProvider.loadAdminOrders error: ${e.message}');
    } catch (e, s) {
      developer.log(
        'OrderProvider.loadAdminOrders failed',
        error: e,
        stackTrace: s,
      );
    } finally {
      _isLoadingAdmin = false;
      notifyListeners();
    }
  }

  /// Admin: advances an order to [next] status.
  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus next, {
    String note = '',
  }) async {
    try {
      // Capture the previous status so the notification can mention the change.
      final previous = _findOrder(orderId)?.status ?? OrderStatus.pending;
      final updated = await _repo.updateStatus(orderId, next, note: note);
      _replaceInLists(updated);
      notifyListeners();
      // Fire the notification hook (best-effort; must never break the update).
      onStatusChanged?.call(updated, previous, next);
      return true;
    } on AppException catch (e) {
      developer.log('OrderProvider.updateOrderStatus error: ${e.message}');
      return false;
    }
  }

  /// Admin dashboard: total revenue.
  Future<double> getTotalRevenue() => _repo.getTotalRevenue();

  /// Admin dashboard: order count by status.
  Future<int> countByStatus(OrderStatus status) => _repo.countByStatus(status);

  /// Admin dashboard: total orders.
  Future<int> countOrders() => _repo.countOrders();

  // ── Helpers ───────────────

  /// Finds an order in either local list, falling back to [OrderStatus.pending].
  OrderModel? _findOrder(String orderId) {
    for (final o in _orders) {
      if (o.id == orderId) return o;
    }
    for (final o in _adminOrders) {
      if (o.id == orderId) return o;
    }
    return null;
  }

  void _replaceInLists(OrderModel updated) {
    for (var i = 0; i < _orders.length; i++) {
      if (_orders[i].id == updated.id) _orders[i] = updated;
    }
    for (var i = 0; i < _adminOrders.length; i++) {
      if (_adminOrders[i].id == updated.id) _adminOrders[i] = updated;
    }
  }

  void clearCheckoutError() {
    if (_checkoutError == null) return;
    _checkoutError = null;
    notifyListeners();
  }
}
