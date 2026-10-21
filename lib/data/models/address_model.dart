import 'model_helpers.dart';

/// A saved shipping address belonging to a user.
///
/// Addresses are a first-class resource on the Laravel API (`/addresses`) and
/// are also embedded in the `me` payload, so they are plain value objects.
class AddressModel {
  const AddressModel({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.zip,
    required this.phone,
    this.line2 = '',
    this.isDefault = false,
  });

  /// Stable identifier (client-generated UUID) used for edit/delete by id.
  final String id;

  /// User-facing label, e.g. "Home", "Office".
  final String label;

  final String line1;
  final String line2;
  final String city;
  final String zip;
  final String phone;
  final bool isDefault;

  // ── Serialization ─────────────────────────

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return AddressModel(
      id: parseString(m['id']),
      label: parseString(m['label']).isEmpty ? 'Home' : parseString(m['label']),
      line1: parseString(m['line1']),
      line2: parseString(m['line2']),
      city: parseString(m['city']),
      zip: parseString(m['zip']),
      phone: parseString(m['phone']),
      isDefault: parseBool(m['isDefault']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'line1': line1,
    'line2': line2,
    'city': city,
    'zip': zip,
    'phone': phone,
    'is_default': isDefault,
  };

  AddressModel copyWith({
    String? id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? zip,
    String? phone,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      zip: zip ?? this.zip,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Single-line summary used on order cards and address tiles.
  String get summary {
    final parts = <String>[line1, if (line2.isNotEmpty) line2, city, zip];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  @override
  bool operator ==(Object other) => other is AddressModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
