import 'model_helpers.dart';

/// An in-app notification.
///
/// Mirrors `notifications/{userId}/items/{notifId}`:
/// `title, message, read, createdAt` (+ a `type` for icon selection and an
/// optional `orderId` for deep-linking).
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.read = false,
    this.createdAt,
    this.type = 'general',
    this.orderId = '',
  });

  final String id;
  final String title;
  final String message;
  final bool read;
  final DateTime? createdAt;

  /// One of: `general`, `order`, `promo`, `account`.
  final String type;

  /// Related order id, when this notification concerns an order.
  final String orderId;

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return NotificationModel(
      id: parseString(m['id'] ?? id),
      title: parseString(m['title']),
      message: parseString(m['message']),
      read: parseBool(m['read']),
      createdAt: parseDate(m['createdAt']),
      type: parseString(m['type']).isEmpty ? 'general' : parseString(m['type']),
      orderId: parseString(m['orderId']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'message': message,
    'read': read,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    'type': type,
    'order_id': orderId,
  };

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    bool? read,
    DateTime? createdAt,
    String? type,
    String? orderId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
