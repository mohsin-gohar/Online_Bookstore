import 'dart:async';
import 'dart:developer' as developer;

import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/api_constants.dart';
import 'app_exceptions.dart';

/// Obtains a Google **ID token** for the signed-in account.
///
/// The token is sent to the Laravel backend, which verifies it with Google
/// before issuing a session token. The client never asserts an identity of
/// its own — the server is the only party that can decide who the user is.
///
/// ## Setup
///
/// Google Sign-In needs an OAuth **web** client id from the Google Cloud
/// console:
///
/// * Pass it at build time —
///   `--dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com`
///   (and `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` for Android), or
/// * put it in `android/app/src/main/res/values/strings.xml` as
///   `default_web_client_id` and in `ios/Runner/Info.plist` as `GIDClientID`.
class GoogleSignInService {
  const GoogleSignInService();

  /// The plugin is a process-wide singleton, so the init guard is too.
  static bool _initialized = false;

  /// Prepares the plugin with the configured client ids (idempotent).
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await GoogleSignIn.instance.initialize(
      clientId: ApiConstants.googleClientId.isEmpty
          ? null
          : ApiConstants.googleClientId,
      serverClientId: ApiConstants.googleServerClientId.isEmpty
          ? null
          : ApiConstants.googleServerClientId,
    );
  }

  /// Runs the Google sign-in flow and returns the ID token.
  ///
  /// Throws [GoogleSignInCancelledException] when the user dismisses the
  /// sheet, [GoogleSignInNotConfiguredException] when the project has no
  /// OAuth client id, and [ValidationException] for any other failure.
  Future<String> requestIdToken() async {
    try {
      await _ensureInitialized();

      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate(scopeHint: const <String>['email']);

      final String? idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const ValidationException(
          'Google did not return an ID token. Try again.',
        );
      }

      // Dismiss the account sheet as soon as we have the token.
      unawaited(GoogleSignIn.instance.signOut());

      return idToken;
    } on GoogleSignInException catch (e, s) {
      developer.log('Google sign-in failed', error: e, stackTrace: s);
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelledException();
      }
      if (!ApiConstants.hasGoogleClient &&
          e.code == GoogleSignInExceptionCode.unknownError) {
        throw const GoogleSignInNotConfiguredException();
      }
      throw const ValidationException(
        'Google sign-in failed. Check your connection and try again.',
      );
    }
  }
}
