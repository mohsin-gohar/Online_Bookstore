import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../mock/mock_transport.dart';
import 'api_client.dart';
import 'api_transport.dart';
import 'token_storage_service.dart';

/// Builds and shares the app's singletons.
///
/// There is exactly **one** transport and **one** token store for the whole
/// app. That matters for mock mode: two transports would mean two separate
/// in-memory databases, and a book added to the cart on one screen would
/// vanish on another.
class ApiFactory {
  ApiFactory._();

  static TokenStorageService? _tokenStorage;
  static ApiTransport? _transport;

  /// The shared keystore-backed token store.
  static TokenStorageService get tokenStorage =>
      _tokenStorage ??= TokenStorageService();

  /// Called when the API rejects the stored token (HTTP 401).
  ///
  /// Wired by the app bootstrap so an expired session signs the user out
  /// instead of leaving the UI in a half-authenticated state.
  static void Function()? onUnauthorized;

  /// The shared transport for the active mode.
  static ApiTransport get transport {
    return _transport ??= ApiConstants.useMockMode
        ? MockApiTransport(tokenStorage: tokenStorage)
        : HttpApiTransport(
            ApiClient(
              tokenStorage: tokenStorage,
              onUnauthorized: () => onUnauthorized?.call(),
            ),
          );
  }

  /// Replaces the transport — used by tests to inject a fake.
  @visibleForTesting
  static void overrideTransport(ApiTransport? value) => _transport = value;

  /// Replaces the token store — used by tests.
  @visibleForTesting
  static void overrideTokenStorage(TokenStorageService? value) =>
      _tokenStorage = value;
}

/// Creates a **fresh** mock transport with its own in-memory catalogue.
///
/// Used by the tests so each test starts from an empty store, and by mock
/// mode when the app boots.
MockApiTransport createMockTransport(TokenStorageService tokens) {
  return MockApiTransport(tokenStorage: tokens);
}
