import 'model_helpers.dart';

/// A (dummy) payment method saved by the user.
///
/// The app never stores real card data: only the brand, the last four digits,
/// the holder name and an expiry string. This mirrors what a PCI-compliant
/// backend would persist. CVV is never sent to, or accepted from, the server.
class PaymentMethodModel {
  const PaymentMethodModel({
    required this.id,
    required this.type,
    required this.last4,
    required this.holderName,
    this.expiry = '',
    this.isDefault = false,
  });

  final String id;

  /// Card network: 'Visa', 'Mastercard', 'Amex', or 'Cash on Delivery'.
  final String type;

  final String last4;
  final String holderName;

  /// `MM/YY`; empty for cash-on-delivery.
  final String expiry;

  final bool isDefault;

  // ── Serialization ─────────────────────────

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: parseString(map['id']),
      type: parseString(map['type']).isEmpty
          ? 'Visa'
          : parseString(map['type']),
      last4: parseString(map['last4']),
      holderName: parseString(map['holderName']),
      expiry: parseString(map['expiry']),
      isDefault: parseBool(map['isDefault']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'last4': last4,
    'holder_name': holderName,
    'expiry': expiry,
    'is_default': isDefault,
  };

  PaymentMethodModel copyWith({
    String? id,
    String? type,
    String? last4,
    String? holderName,
    String? expiry,
    bool? isDefault,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      holderName: holderName ?? this.holderName,
      expiry: expiry ?? this.expiry,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// True for the cash-on-delivery pseudo-method (no card details).
  bool get isCashOnDelivery => type.toLowerCase().contains('cash');

  @override
  bool operator ==(Object other) =>
      other is PaymentMethodModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
