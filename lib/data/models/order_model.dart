import 'model_helpers.dart';
import 'order_item_model.dart';
import 'order_status.dart';
import 'order_status_event.dart';

/// A placed order.
///
/// Mirrors `orders/{orderId}`:
/// `userId, userName, items[], subtotal, shipping, total, status, address,
/// paymentMethod, orderDate, deliveryDate` (+ a `timeline[]` of status events).
///
/// The address and payment method are stored as **snapshots** (plain strings /
/// maps) so a later edit to the user's saved address never changes an order
/// that has already been placed.
class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.items = const [],
    this.subtotal = 0,
    this.shipping = 0,
    this.discount = 0,
    this.promoCode = '',
    this.total = 0,
    this.status = OrderStatus.pending,
    this.address = '',
    this.paymentMethod = '',
    this.orderDate,
    this.deliveryDate,
    this.timeline = const [],
    this.cancelledReason = '',
  });

  final String id;
  final String userId;
  final String userName;
  final List<OrderItemModel> items;

  final double subtotal;
  final double shipping;
  final double discount;

  /// Code applied at checkout, empty when none was used.
  final String promoCode;

  final double total;

  final OrderStatus status;

  /// One-line snapshot of the shipping address at purchase time.
  final String address;

  /// Payment method label, e.g. "Visa •••• 4242" or "Cash on Delivery".
  final String paymentMethod;

  final DateTime? orderDate;
  final DateTime? deliveryDate;

  /// Status history for the tracking screen.
  final List<OrderStatusEvent> timeline;

  /// Reason captured when an order is cancelled.
  final String cancelledReason;

  // ── Convenience ───────────────────────────

  int get itemCount => items.fold<int>(0, (sum, i) => sum + i.qty);
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isActive => !status.isTerminal;

  /// Progress (0..1) through the happy-path timeline, for the tracker UI.
  double get progress {
    if (status == OrderStatus.cancelled) return 0;
    final step = status.timelineIndex;
    if (step <= 0) return 0;
    return step / (OrderStatus.timeline.length - 1);
  }

  // ── Shipping rule ─────────────────────────
  //
  // Single source of truth for order totals, shared by the cart and checkout
  // screens and covered by unit tests.

  /// Orders at or above this subtotal ship free.
  static const double freeShippingThreshold = 50;

  /// Flat shipping fee applied below [freeShippingThreshold].
  static const double flatShippingFee = 5.99;

  /// Shipping charge for [subtotal], following the documented rule:
  /// `subtotal >= $50 → free`, otherwise a flat $5.99 fee. An empty cart
  /// (subtotal 0) never charges shipping.
  static double computeShipping(double subtotal) =>
      (subtotal <= 0 || subtotal >= freeShippingThreshold)
      ? 0
      : flatShippingFee;

  // ── Serialization ─────────────────────────

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return OrderModel(
      id: parseString(m['id'] ?? id),
      userId: parseString(m['userId']),
      userName: parseString(m['userName']),
      items: parseList(m['items'], OrderItemModel.fromMap),
      subtotal: parseDouble(m['subtotal']),
      shipping: parseDouble(m['shipping']),
      discount: parseDouble(m['discount']),
      promoCode: parseString(m['promoCode']),
      total: parseDouble(m['total']),
      status: OrderStatus.fromString(parseString(m['status'])),
      address: parseString(m['address']),
      paymentMethod: parseString(m['paymentMethod']),
      orderDate: parseDate(m['orderDate']),
      deliveryDate: parseDate(m['deliveryDate']),
      timeline: parseList(m['timeline'], OrderStatusEvent.fromMap),
      cancelledReason: parseString(m['cancelledReason']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'user_name': userName,
    'items': items.map((i) => i.toMap()).toList(),
    'subtotal': subtotal,
    'shipping': shipping,
    'discount': discount,
    'promo_code': promoCode,
    'total': total,
    'status': status.value,
    'address': address,
    'payment_method': paymentMethod,
    'order_date': orderDate?.toIso8601String(),
    'delivery_date': deliveryDate?.toIso8601String(),
    'timeline': timeline.map((e) => e.toMap()).toList(),
    'cancelled_reason': cancelledReason,
  };

  /// API write payload (id is the path segment, not a field).
  Map<String, dynamic> toApi() {
    final map = toMap();
    map.remove('id');
    return map;
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    List<OrderItemModel>? items,
    double? subtotal,
    double? shipping,
    double? discount,
    String? promoCode,
    double? total,
    OrderStatus? status,
    String? address,
    String? paymentMethod,
    DateTime? orderDate,
    DateTime? deliveryDate,
    List<OrderStatusEvent>? timeline,
    String? cancelledReason,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shipping: shipping ?? this.shipping,
      discount: discount ?? this.discount,
      promoCode: promoCode ?? this.promoCode,
      total: total ?? this.total,
      status: status ?? this.status,
      address: address ?? this.address,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      timeline: timeline ?? this.timeline,
      cancelledReason: cancelledReason ?? this.cancelledReason,
    );
  }

  @override
  bool operator ==(Object other) => other is OrderModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
