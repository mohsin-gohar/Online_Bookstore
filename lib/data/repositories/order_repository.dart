import 'dart:async';
import 'dart:developer' as developer;

import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/order_status.dart';
import '../models/page_result.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';
import 'user_repository.dart' show pollStream;

/// Reads and writes orders.
///
/// Backed by `GET /orders`, `GET /orders/{id}`, `POST /orders`,
/// `POST /orders/{id}/cancel` and the admin order endpoints.
///
/// The server owns the totals, the stock decrement and the status timeline —
/// the client never invents them.
class OrderRepository {
  OrderRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  /// Fetches one order by id, or null.
  Future<OrderModel?> getOrder(String orderId) async {
    if (orderId.isEmpty) throw const ValidationException('Missing order id.');
    try {
      final ApiResponse response = await _api.get(ApiConstants.order(orderId));
      if (response.data == null) return null;
      return OrderModel.fromMap(response.map, id: orderId);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log('OrderRepository.getOrder failed', error: e, stackTrace: s);
      throw const ServerException('Could not load the order.');
    }
  }

  /// The signed-in user's orders, newest first.
  Future<PageResult<OrderModel>> getUserOrders(
    String userId, {
    int pageSize = 20,
    Object? cursor,
  }) async {
    if (userId.isEmpty) throw const UnauthenticatedException();
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.orders,
        query: <String, dynamic>{
          'per_page': pageSize,
          if (cursor is int && cursor > 1) 'page': cursor,
        },
      );
      return response.toPageResult<OrderModel>(
        (Map<String, dynamic> m) => OrderModel.fromMap(m),
      );
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'OrderRepository.getUserOrders failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not load your orders.');
    }
  }

  /// All orders (admin), newest first, optionally filtered by [status].
  Future<PageResult<OrderModel>> getAllOrders({
    OrderStatus? status,
    int pageSize = 20,
    Object? cursor,
  }) async {
    try {
      final ApiResponse response = await _api.get(
        ApiConstants.adminOrders,
        query: <String, dynamic>{
          'per_page': pageSize,
          if (status != null) 'status': status.value,
          if (cursor is int && cursor > 1) 'page': cursor,
        },
      );
      return response.toPageResult<OrderModel>(
        (Map<String, dynamic> m) => OrderModel.fromMap(m),
      );
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'OrderRepository.getAllOrders failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not load orders.');
    }
  }

  /// Live view of a single order — used by the delivery-tracking screen.
  ///
  /// Polls every five seconds so the timeline advances while the customer
  /// watches it.
  Stream<OrderModel?> watchOrder(String orderId) {
    return pollStream<OrderModel?>(
      fetch: () => getOrder(orderId),
      interval: const Duration(seconds: 5),
    );
  }

  /// Total number of orders (admin dashboard).
  Future<int> countOrders() async {
    final ApiResponse response = await _api.get(
      ApiConstants.adminOrders,
      query: <String, dynamic>{'per_page': 1},
    );
    return response.pagination.total;
  }

  /// Count of orders at a given [status] (admin dashboard).
  Future<int> countByStatus(OrderStatus status) async {
    final ApiResponse response = await _api.get(
      ApiConstants.adminOrders,
      query: <String, dynamic>{'per_page': 1, 'status': status.value},
    );
    return response.pagination.total;
  }

  /// Total revenue across the non-cancelled orders (admin dashboard).
  ///
  /// The server is the source of truth; the figure comes from
  /// `GET /admin/stats`.
  Future<double> getTotalRevenue() async {
    final ApiResponse response = await _api.get(ApiConstants.adminStats);
    final Object? revenue = response.map['revenue'];
    return revenue is num ? revenue.toDouble() : 0;
  }

  // ── Writes ────────────────────────────────

  /// Places a new order and returns the created order (with its id set).
  Future<OrderModel> placeOrder(OrderModel order) async {
    _validate(order);

    try {
      final ApiResponse response = await _api.post(
        ApiConstants.orders,
        body: <String, dynamic>{
          'address': order.address,
          'payment_method': order.paymentMethod,
          'items': order.items
              .map((OrderItemModel e) => e.toMap())
              .toList(growable: false),
          if (order.promoCode.isNotEmpty) 'promo_code': order.promoCode,
        },
      );

      if (response.data == null) {
        throw const ServerException('The order could not be created.');
      }
      return OrderModel.fromMap(response.map);
    } on AppException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'OrderRepository.placeOrder failed',
        error: e,
        stackTrace: s,
      );
      throw const ServerException('Could not place your order.');
    }
  }

  /// Moves an order to [next] (admin).
  Future<OrderModel> updateStatus(
    String orderId,
    OrderStatus next, {
    String note = '',
    bool force = false,
  }) async {
    final OrderModel? order = await getOrder(orderId);
    if (order == null) throw const ServerException('Order not found.');

    if (!force && !order.status.canTransitionTo(next)) {
      throw ValidationException(
        'Cannot change status from ${order.status.label} to ${next.label}.',
      );
    }

    final ApiResponse response = await _api.patch(
      ApiConstants.adminOrderStatus(orderId),
      body: <String, dynamic>{'status': next.value, 'note': note},
    );

    return OrderModel.fromMap(response.map, id: orderId);
  }

  /// Cancels an order (customer).
  Future<OrderModel> cancelOrder(String orderId, {String reason = ''}) async {
    final ApiResponse response = await _api.post(
      ApiConstants.orderCancel(orderId),
      body: <String, dynamic>{
        'reason': reason.isEmpty ? 'Cancelled by user' : reason,
      },
    );
    return OrderModel.fromMap(response.map, id: orderId);
  }

  // ── Internals ─────────────────────────────

  void _validate(OrderModel order) {
    if (order.userId.isEmpty) {
      throw const UnauthenticatedException();
    }
    if (order.items.isEmpty) {
      throw const ValidationException('Your cart is empty.');
    }
    if (order.total <= 0) {
      throw const ValidationException('Order total is invalid.');
    }
  }
}
