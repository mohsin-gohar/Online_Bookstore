import 'model_helpers.dart';

/// A single entry in an order's status timeline.
///
/// Stored in `orders/{orderId}.timeline[]` as `{status, at, note}`. Powers the
/// "Track Order" screen by recording when each status was reached.
class OrderStatusEvent {
  const OrderStatusEvent({
    required this.status,
    required this.at,
    this.note = '',
  });

  /// Status value string (matches `OrderStatus.value`).
  final String status;

  /// When the status was reached.
  final DateTime at;

  /// Optional admin note, e.g. "Handed to courier".
  final String note;

  factory OrderStatusEvent.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return OrderStatusEvent(
      status: parseString(m['status']),
      at: parseDate(m['at']) ?? DateTime.now(),
      note: parseString(m['note']),
    );
  }

  Map<String, dynamic> toMap() => {
    'status': status,
    'at': at.toIso8601String(),
    'note': note,
  };

  OrderStatusEvent copyWith({String? status, DateTime? at, String? note}) {
    return OrderStatusEvent(
      status: status ?? this.status,
      at: at ?? this.at,
      note: note ?? this.note,
    );
  }
}
