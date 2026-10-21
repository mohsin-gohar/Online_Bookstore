/// Domain-level exception types.
///
/// Repositories/services translate low-level SDK errors (e.g.
/// `GoogleSignInException`, `DioException`) into one of these so the UI can
/// show friendly, consistent messages without knowing which backend is in
/// use.
///
/// Every exception carries a human-readable [message] plus an optional [code].
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

/// The user is not authenticated (or the session expired).
class UnauthenticatedException extends AppException {
  const UnauthenticatedException([
    super.message = 'You are not signed in. Please log in again.',
    String code = 'unauthenticated',
  ]) : super(code: code);
}

/// Credentials, email, or password were invalid.
class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException([
    super.message = 'Invalid email or password.',
    String code = 'invalid-credentials',
  ]) : super(code: code);
}

/// Sign-up was attempted with an email that already has an account.
class EmailAlreadyInUseException extends AppException {
  const EmailAlreadyInUseException([
    super.message = 'This email is already registered. Try logging in.',
    String code = 'email-in-use',
  ]) : super(code: code);
}

/// A required form field or payload was missing/invalid.
///
/// [fieldErrors] carries Laravel's HTTP 422 validation payload
/// (`{"email": ["The email has already been taken."]}`) flattened to one
/// message per field so a form can highlight the offending input.
class ValidationException extends AppException {
  const ValidationException([
    super.message = 'Please check the information you entered.',
    String code = 'validation',
  ]) : fieldErrors = const <String, String>{},
       super(code: code);

  /// The variant used for Laravel's HTTP 422 responses, which carry one
  /// message per invalid field.
  const ValidationException.withFields(super.message, this.fieldErrors)
    : super(code: 'validation');

  /// Field name → first validation message.
  final Map<String, String> fieldErrors;

  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  /// The message for [field], if the server reported one.
  String? messageFor(String field) => fieldErrors[field];
}

/// The account has been blocked by an administrator.
class AccountBlockedException extends AppException {
  const AccountBlockedException([
    super.message = 'Your account has been blocked. Contact support.',
    String code = 'account-blocked',
  ]) : super(code: code);
}

/// A network/connectivity problem occurred.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Network error. Check your connection and try again.',
    String code = 'network',
  ]) : super(code: code);
}

/// The Google sign-in flow was cancelled by the user (not an error per se).
class GoogleSignInCancelledException extends AppException {
  const GoogleSignInCancelledException([
    super.message = 'Google sign-in was cancelled.',
    String code = 'google-cancelled',
  ]) : super(code: code);
}

/// The project has no Google OAuth client id configured.
class GoogleSignInNotConfiguredException extends AppException {
  const GoogleSignInNotConfiguredException([
    super.message =
        'Google sign-in is not set up yet. Add a Google OAuth client id to '
        'continue.',
    String code = 'google-not-configured',
  ]) : super(code: code);
}

/// The Laravel API or any other server returned an unexpected failure.
class ServerException extends AppException {
  const ServerException([
    super.message = 'Something went wrong. Please try again.',
    String code = 'server',
  ]) : super(code: code);
}

/// A catch-all for bugs we didn't anticipate mapping.
class UnknownException extends AppException {
  const UnknownException([
    super.message = 'An unexpected error occurred.',
    String code = 'unknown',
  ]) : super(code: code);
}
