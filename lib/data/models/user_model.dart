import 'package:characters/characters.dart';

import 'address_model.dart';
import 'model_helpers.dart';
import 'payment_method_model.dart';

/// The three roles the app understands.
///
/// Stored on the Laravel `users` table as the lowercase string
/// ('guest' | 'customer' | 'admin'). Guests are never persisted — the role
/// exists only for routing clarity, so a [UserModel] will always be
/// `customer` or `admin`.
enum UserRole {
  guest,
  customer,
  admin;

  /// Parses a stored value, defaulting to [customer] for anything unrecognised.
  static UserRole fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'guest':
        return UserRole.guest;
      default:
        return UserRole.customer;
    }
  }

  String get value => name;

  bool get isAdmin => this == UserRole.admin;
  bool get isCustomer => this == UserRole.customer;
}

/// A registered user of the store.
///
/// Mirrors the `GET /me` payload:
/// `id, name, email, phone, photo_url, role, created_at, addresses[],
/// payment_methods[], is_blocked`.
class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    this.role = UserRole.customer,
    this.createdAt,
    this.addresses = const [],
    this.paymentMethods = const [],
    this.isBlocked = false,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final UserRole role;
  final DateTime? createdAt;
  final List<AddressModel> addresses;
  final List<PaymentMethodModel> paymentMethods;

  /// Admins can block abusive accounts; blocked users are signed out.
  final bool isBlocked;

  // ── Convenience ───────────────────────────

  bool get isAdmin => role.isAdmin;
  bool get isBlockedAccount => isBlocked;

  /// First letter of the name, used for the avatar fallback.
  String get initial =>
      name.trim().isNotEmpty ? name.trim().characters.first.toUpperCase() : '?';

  /// The address flagged as default, or the first one, or null.
  AddressModel? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }

  /// The payment method flagged as default, or the first one, or null.
  PaymentMethodModel? get defaultPaymentMethod {
    if (paymentMethods.isEmpty) return null;
    return paymentMethods.firstWhere(
      (p) => p.isDefault,
      orElse: () => paymentMethods.first,
    );
  }

  // ── Serialization ─────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    final Map<String, dynamic> m = normalizeKeys(map);
    return UserModel(
      uid: parseString(m['uid'] ?? m['id'] ?? uid),
      name: parseString(m['name']),
      email: parseString(m['email']),
      phone: parseString(m['phone']),
      photoUrl: parseString(m['photoUrl']),
      role: UserRole.fromString(parseString(m['role'])),
      createdAt: parseDate(m['createdAt']),
      addresses: parseList(m['addresses'], AddressModel.fromMap),
      paymentMethods: parseList(
        m['paymentMethods'],
        PaymentMethodModel.fromMap,
      ),
      isBlocked: parseBool(m['isBlocked']),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'photo_url': photoUrl,
    'role': role.value,
    'created_at': createdAt?.toIso8601String(),
    'addresses': addresses.map((a) => a.toMap()).toList(),
    'payment_methods': paymentMethods.map((p) => p.toMap()).toList(),
    'is_blocked': isBlocked,
  };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    List<AddressModel>? addresses,
    List<PaymentMethodModel>? paymentMethods,
    bool? isBlocked,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      addresses: addresses ?? this.addresses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
