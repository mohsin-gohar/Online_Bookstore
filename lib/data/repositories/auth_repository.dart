import '../../core/constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../services/api_factory.dart';
import '../services/api_transport.dart';
import '../services/app_exceptions.dart';
import '../services/google_sign_in_service.dart';
import '../services/token_storage_service.dart';

/// Orchestrates authentication against the Laravel API and keeps the token in
/// secure storage.
///
/// Responsibilities:
///  • register / sign in (email + Google) and return a domain [UserModel],
///  • store the bearer token in the platform keystore,
///  • restore the stored session on launch,
///  • map every failure into an [AppException] so the provider stays thin.
///
/// The Google flow sends the **ID token** to the server, which verifies it
/// with Google. The client never trusts a client-supplied identity.
class AuthRepository {
  AuthRepository({
    ApiTransport? transport,
    TokenStorageService? tokenStorage,
    GoogleSignInService? googleSignInService,
  }) : _api = transport ?? ApiFactory.transport,
       _tokens = tokenStorage ?? ApiFactory.tokenStorage,
       _google = googleSignInService ?? GoogleSignInService();

  final ApiTransport _api;
  final TokenStorageService _tokens;
  final GoogleSignInService _google;

  /// The uid of the currently signed-in user, if any.
  String? get currentUid => _currentUid;
  String? _currentUid;

  // ── Sign up / sign in ─────────────────────

  /// Registers with email/password and stores the returned token.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      throw const ValidationException('Please fill in every required field.');
    }

    final ApiResponse response = await _api.post(
      ApiConstants.authRegister,
      body: <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'phone': phone.trim(),
      },
    );

    return _consumeAuthResponse(response);
  }

  /// Signs in with email/password and stores the returned token.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final ApiResponse response = await _api.post(
      ApiConstants.authLogin,
      body: <String, dynamic>{'email': email.trim(), 'password': password},
    );

    return _consumeAuthResponse(response);
  }

  /// Signs in with Google.
  ///
  /// The Google **ID token** is obtained locally and then verified by the
  /// server, which is the only party that can decide who the user is.
  Future<UserModel> signInWithGoogle() async {
    final String idToken = await _google.requestIdToken();

    final ApiResponse response = await _api.post(
      ApiConstants.authGoogle,
      body: <String, dynamic>{'id_token': idToken},
    );

    return _consumeAuthResponse(response);
  }

  // ── Password reset ────────────────────────

  /// Requests a six-digit verification code for [email].
  ///
  /// Resolves regardless of whether the address exists, to avoid
  /// account-enumeration.
  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw const ValidationException('Enter your email first.');
    }
    await _api.post(
      ApiConstants.authForgotPassword,
      body: <String, dynamic>{'email': email.trim()},
    );
  }

  /// Verifies the six-digit [code] that was emailed to [email].
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await _api.post(
      ApiConstants.authVerifyCode,
      body: <String, dynamic>{'email': email.trim(), 'code': code.trim()},
    );
  }

  /// Sets a new password using the emailed [code].
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _api.post(
      ApiConstants.authResetPassword,
      body: <String, dynamic>{
        'email': email.trim(),
        'code': code.trim(),
        'password': password,
      },
    );
  }

  // ── Session ───────────────────────────────

  /// Signs the current user out and clears the stored token.
  Future<void> signOut() async {
    try {
      await _api.post(ApiConstants.authLogout);
    } on AppException {
      // The local session is cleared even when the server call fails.
    } finally {
      await _tokens.clear();
      _currentUid = null;
    }
  }

  /// Loads the profile of the currently-authenticated user.
  Future<UserModel?> getCurrentUser() async {
    final String? token = await _tokens.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final ApiResponse response = await _api.get(ApiConstants.me);
      if (response.data == null) return null;
      final UserModel user = UserModel.fromMap(response.map);
      _currentUid = user.uid;
      return user;
    } on UnauthenticatedException {
      await _tokens.clear();
      _currentUid = null;
      return null;
    }
  }

  // ── Internals ─────────────────────────────

  /// Stores the token from an auth response and resolves the profile.
  Future<UserModel> _consumeAuthResponse(ApiResponse response) async {
    final Map<String, dynamic> payload = response.map;

    final String token = _stringOf(payload['token'] ?? payload['access_token']);
    if (token.isEmpty) {
      throw const ServerException('The server did not return a session token.');
    }

    await _tokens.writeToken(token);

    final Object? rawUser = payload['user'];
    final UserModel user = rawUser is Map
        ? UserModel.fromMap(rawUser.cast<String, dynamic>())
        : UserModel.fromMap(payload);

    if (user.isBlocked) {
      await _tokens.clear();
      throw const AccountBlockedException();
    }

    _currentUid = user.uid;
    return user;
  }

  static String _stringOf(Object? value) => (value ?? '').toString().trim();
}
