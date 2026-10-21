import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/models/address_model.dart';
import '../data/models/payment_method_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/app_exceptions.dart';

/// Manages the signed-in user's profile data: name/phone/photo, saved addresses
/// and payment methods. All of these live on the `users/{uid}` document.
///
/// Keeps a local mirror of the [UserModel] so screens update instantly, while
/// persisting changes to the API.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required UserRepository repository}) : _repo = repository;

  final UserRepository _repo;

  UserModel? _user;
  bool _isSaving = false;
  String? _error;

  // ── State ─────────────────

  UserModel? get user => _user;
  bool get isSaving => _isSaving;
  String? get error => _error;

  List<AddressModel> get addresses => _user?.addresses ?? const [];
  List<PaymentMethodModel> get paymentMethods =>
      _user?.paymentMethods ?? const [];

  AddressModel? get defaultAddress => _user?.defaultAddress;
  PaymentMethodModel? get defaultPaymentMethod => _user?.defaultPaymentMethod;

  // ── Lifecycle ─────────────

  /// Seeds the local mirror from an already-loaded [UserModel] (e.g. from
  /// AuthProvider at login) without a network round-trip.
  void seed(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  /// Reloads the profile from the API.
  Future<void> load(String uid) async {
    try {
      _user = await _repo.getUser(uid);
      notifyListeners();
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // ── Profile edits ─────────

  /// Updates name/phone/photo on both the API and the local mirror.
  Future<bool> updateBasicProfile({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    return _run(() async {
      await _repo.updateProfile(
        uid,
        name: name,
        phone: phone,
        photoUrl: photoUrl,
      );
      _user = _user?.copyWith(name: name, phone: phone, photoUrl: photoUrl);
    });
  }

  // ── Addresses ─────────────

  /// Adds or replaces an address, honouring the `isDefault` flag (only one
  /// default at a time).
  Future<bool> saveAddress(String uid, AddressModel address) async {
    if (_user == null) return false;
    return _run(() async {
      final list = [...addresses];
      final index = list.indexWhere((a) => a.id == address.id);

      // If this one is default, clear the flag on all others.
      List<AddressModel> normalized = list.map((a) {
        if (address.isDefault && a.isDefault && a.id != address.id) {
          return a.copyWith(isDefault: false);
        }
        return a;
      }).toList();

      if (index >= 0) {
        normalized[index] = address;
      } else {
        normalized.add(address);
      }

      // Ensure exactly one default exists.
      normalized = _ensureSingleDefault(normalized);

      _user = _user?.copyWith(addresses: normalized);
      await _repo.upsertUser(_user!);
    });
  }

  /// Deletes an address by id (promotes another to default if needed).
  Future<bool> deleteAddress(String uid, String addressId) async {
    if (_user == null) return false;
    return _run(() async {
      final list = addresses.where((a) => a.id != addressId).toList();
      final normalized = _ensureSingleDefault(list);
      _user = _user?.copyWith(addresses: normalized);
      await _repo.upsertUser(_user!);
    });
  }

  /// Marks [addressId] as the sole default.
  Future<bool> setDefaultAddress(String uid, String addressId) async {
    if (_user == null) return false;
    return _run(() async {
      final list = addresses
          .map((a) => a.copyWith(isDefault: a.id == addressId))
          .toList();
      _user = _user?.copyWith(addresses: list);
      await _repo.upsertUser(_user!);
    });
  }

  // ── Payment methods ───────

  /// Adds or replaces a payment method.
  Future<bool> savePaymentMethod(String uid, PaymentMethodModel method) async {
    if (_user == null) return false;
    return _run(() async {
      final list = [...paymentMethods];
      final index = list.indexWhere((p) => p.id == method.id);

      var normalized = list.map((p) {
        if (method.isDefault && p.isDefault && p.id != method.id) {
          return p.copyWith(isDefault: false);
        }
        return p;
      }).toList();

      if (index >= 0) {
        normalized[index] = method;
      } else {
        normalized.add(method);
      }

      normalized = _ensureSingleDefaultPayment(normalized);

      _user = _user?.copyWith(paymentMethods: normalized);
      await _repo.upsertUser(_user!);
    });
  }

  /// Deletes a payment method by id.
  Future<bool> deletePaymentMethod(String uid, String methodId) async {
    if (_user == null) return false;
    return _run(() async {
      final list = paymentMethods.where((p) => p.id != methodId).toList();
      final normalized = _ensureSingleDefaultPayment(list);
      _user = _user?.copyWith(paymentMethods: normalized);
      await _repo.upsertUser(_user!);
    });
  }

  /// Marks [methodId] as the sole default.
  Future<bool> setDefaultPaymentMethod(String uid, String methodId) async {
    if (_user == null) return false;
    return _run(() async {
      final list = paymentMethods
          .map((p) => p.copyWith(isDefault: p.id == methodId))
          .toList();
      _user = _user?.copyWith(paymentMethods: list);
      await _repo.upsertUser(_user!);
    });
  }

  // ── Helpers ───────────────

  /// Guarantees a single default address (defaults the first if none set).
  List<AddressModel> _ensureSingleDefault(List<AddressModel> list) {
    if (list.isEmpty) return list;
    if (list.any((a) => a.isDefault)) return list;
    return [list.first.copyWith(isDefault: true), ...list.skip(1)];
  }

  /// Guarantees a single default payment method.
  List<PaymentMethodModel> _ensureSingleDefaultPayment(
    List<PaymentMethodModel> list,
  ) {
    if (list.isEmpty) return list;
    if (list.any((p) => p.isDefault)) return list;
    return [list.first.copyWith(isDefault: true), ...list.skip(1)];
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (e, s) {
      developer.log('ProfileProvider action failed', error: e, stackTrace: s);
      _error = const UnknownException().message;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
