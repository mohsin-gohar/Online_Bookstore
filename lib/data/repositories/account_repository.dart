import 'dart:async';

import '../../core/constants/api_constants.dart';
import '../models/address_model.dart';
import '../models/api_response.dart';
import '../models/payment_method_model.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';

/// Manages the signed-in user's shipping addresses and saved payment methods.
///
/// Backed by `CRUD /addresses` and `CRUD /payment-methods`.
///
/// Only payment **metadata** is stored — brand, last four digits, holder name
/// and expiry. Full card numbers and CVV are never accepted or sent.
class AccountRepository {
  AccountRepository({ApiTransport? transport})
    : _api = transport ?? ApiFactory.transport;

  final ApiTransport _api;

  // ── Addresses ─────────────────────────────

  /// The user's shipping addresses.
  Future<List<AddressModel>> getAddresses() async {
    final ApiResponse response = await _api.get(ApiConstants.addresses);
    return response.list
        .map((Map<String, dynamic> m) => AddressModel.fromMap(m))
        .toList(growable: false);
  }

  /// Saves a new address and returns it (with its server id).
  Future<AddressModel> addAddress(AddressModel address) async {
    _validateAddress(address);
    final ApiResponse response = await _api.post(
      ApiConstants.addresses,
      body: address.toMap(),
    );
    return AddressModel.fromMap(response.map);
  }

  /// Updates an address.
  Future<AddressModel> updateAddress(AddressModel address) async {
    if (address.id.isEmpty) {
      throw const ValidationException('Missing address id.');
    }
    _validateAddress(address);
    final ApiResponse response = await _api.put(
      ApiConstants.address(address.id),
      body: address.toMap(),
    );
    return AddressModel.fromMap(response.map);
  }

  /// Deletes an address.
  Future<void> deleteAddress(String addressId) async {
    if (addressId.isEmpty) return;
    await _api.delete(ApiConstants.address(addressId));
  }

  // ── Payment methods ───────────────────────

  /// The user's saved payment methods (metadata only).
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    final ApiResponse response = await _api.get(ApiConstants.paymentMethods);
    return response.list
        .map((Map<String, dynamic> m) => PaymentMethodModel.fromMap(m))
        .toList(growable: false);
  }

  /// Saves a payment method.
  ///
  /// Only metadata is accepted — the server must reject a full card number.
  Future<PaymentMethodModel> addPaymentMethod(PaymentMethodModel method) async {
    _validatePaymentMethod(method);
    final ApiResponse response = await _api.post(
      ApiConstants.paymentMethods,
      body: method.toMap(),
    );
    return PaymentMethodModel.fromMap(response.map);
  }

  /// Updates a payment method.
  Future<PaymentMethodModel> updatePaymentMethod(
    PaymentMethodModel method,
  ) async {
    if (method.id.isEmpty) {
      throw const ValidationException('Missing payment method id.');
    }
    _validatePaymentMethod(method);
    final ApiResponse response = await _api.put(
      ApiConstants.paymentMethod(method.id),
      body: method.toMap(),
    );
    return PaymentMethodModel.fromMap(response.map);
  }

  /// Deletes a payment method.
  Future<void> deletePaymentMethod(String methodId) async {
    if (methodId.isEmpty) return;
    await _api.delete(ApiConstants.paymentMethod(methodId));
  }

  // ── Validation ────────────────────────────

  void _validateAddress(AddressModel address) {
    if (address.line1.trim().isEmpty) {
      throw const ValidationException('Street address is required.');
    }
    if (address.city.trim().isEmpty) {
      throw const ValidationException('City is required.');
    }
    if (address.zip.trim().isEmpty) {
      throw const ValidationException('Postal code is required.');
    }
  }

  void _validatePaymentMethod(PaymentMethodModel method) {
    if (method.type.trim().isEmpty) {
      throw const ValidationException('Card type is required.');
    }
    if (method.last4.trim().isEmpty && !method.isCashOnDelivery) {
      throw const ValidationException('The last four digits are required.');
    }
    if (method.last4.trim().length > 4) {
      throw const ValidationException(
        'Only the last four digits may be stored.',
      );
    }
  }
}
