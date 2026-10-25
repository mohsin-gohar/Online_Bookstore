import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../core/services/local_storage_service.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/app_exceptions.dart';

/// The authentication lifecycle, exposed to the UI.
enum AuthStatus {
  /// Startup: we don't yet know if a user is signed in.
  unknown,

  /// No user is signed in.
  unauthenticated,

  /// A user is signed in (see [AuthProvider.user]).
  authenticated,
}

/// Single source of truth for authentication state.
///
/// Implements the three-state contract: **loading** ([isBusy]), **error**
/// ([errorMessage]), and **data** ([user] + [status]). Screens listen via
/// `context.watch<AuthProvider>()` and drive their own loading/empty/error UI
/// from these fields.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.repository, required this.storage});

  final AuthRepository repository;
  final LocalStorageService storage;

  // ── State ─────────────────

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isBusy = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;

  /// True while a network operation (login/register/reset) is in flight.
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get uid => _user?.uid;

  // ── Lifecycle ─────────────────────────────

  Future<void>? _bootstrapFuture;

  /// Called at startup (from the app root and the splash screen). Resolves the
  /// stored session exactly once.
  ///
  /// Idempotent: deep links skip the splash screen, so the root also calls
  /// this; both callers share the same future instead of hitting `/me` twice.
  Future<void> bootstrap() => _bootstrapFuture ??= _bootstrap();

  Future<void> _bootstrap() async {
    try {
      final current = await repository.getCurrentUser();
      _applyAuthState(current);
    } on AppException catch (e) {
      _applyAuthState(null);
      _setError(e);
    } catch (e, s) {
      developer.log('bootstrap failed', error: e, stackTrace: s);
      _applyAuthState(null);
      _setError(const UnknownException());
    }
  }

  /// Applies an externally-received auth state.
  void _applyAuthState(UserModel? user) {
    _user = user;
    _status = user == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    // Remember/clear the last user id for faster cold starts.
    unawaited(storage.setLastUserId(user?.uid));
    notifyListeners();
  }

  // ── Actions ───────────────────────────────

  /// Registers a new customer. Returns true on success.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) {
    return _run(() async {
      final created = await repository.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _applyAuthState(created);
    });
  }

  /// Signs in with email/password. Returns true on success.
  Future<bool> login({required String email, required String password}) {
    return _run(() async {
      final user = await repository.signIn(email: email, password: password);
      _applyAuthState(user);
    });
  }

  /// Signs in with Google. Returns true on success.
  ///
  /// A user-cancelled Google flow is treated as a no-op (no error shown).
  Future<bool> loginWithGoogle() async {
    _setBusy(true);
    _clearError();
    try {
      final user = await repository.signInWithGoogle();
      _applyAuthState(user);
      return true;
    } on GoogleSignInCancelledException {
      return false; // user dismissed the sheet — not an error
    } on AppException catch (e) {
      _setError(e);
      return false;
    } catch (e, s) {
      developer.log('loginWithGoogle failed', error: e, stackTrace: s);
      _setError(const UnknownException());
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Sends a password-reset email. Returns true on success.
  Future<bool> sendPasswordReset(String email) {
    return _run(() => repository.sendPasswordReset(email));
  }

  /// Signs the current user out and clears local state.
  ///
  /// Returns true on success; on failure the error is stored in
  /// [errorMessage] so screens can surface it instead of failing silently.
  Future<bool> logout() async {
    _setBusy(true);
    _clearError();
    try {
      await repository.signOut();
      _applyAuthState(null);
      return true;
    } on AppException catch (e) {
      _setError(e);
      return false;
    } catch (e, s) {
      developer.log('logout failed', error: e, stackTrace: s);
      _setError(const UnknownException());
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Updates the in-memory user after an edit-profile flow (Phase 10) without
  /// a full reload.
  void updateLocalUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────

  /// Runs [action] with busy/error bookkeeping and returns success/failure.
  Future<bool> _run(Future<void> Function() action) async {
    _setBusy(true);
    _clearError();
    try {
      await action();
      return true;
    } on AppException catch (e) {
      _setError(e);
      return false;
    } catch (e, s) {
      developer.log('AuthProvider action failed', error: e, stackTrace: s);
      _setError(const UnknownException());
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    if (_isBusy == value) return;
    _isBusy = value;
    notifyListeners();
  }

  void _setError(AppException e) {
    _errorMessage = e.message;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;
}
