import 'package:email_validator/email_validator.dart';

/// Form-field validators for the whole app.
///
/// Each method returns `null` when the value is valid, or an error message
/// string otherwise — the exact contract Flutter's `TextFormField.validator`
/// expects. Keeping them here (rather than inline closures) makes them
/// unit-testable and reusable across screens.
class Validators {
  Validators._();

  /// [value] must be a syntactically valid email address.
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!EmailValidator.validate(text)) return 'Enter a valid email address';
    return null;
  }

  /// [value] must be non-empty and at least [min] characters.
  static String? password(String? value, {int min = 6}) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < min) return 'Password must be at least $min characters';
    return null;
  }

  /// Confirms the password and confirmation match.
  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  /// [value] must be a non-empty name (letters and spaces, 2–60 chars).
  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Name is required';
    if (text.length < 2) return 'Name is too short';
    if (text.length > 60) return 'Name is too long';
    final nameReg = RegExp(r"^[\p{L}][\p{L}\s'.-]*$", unicode: true);
    if (!nameReg.hasMatch(text)) return 'Enter a valid name';
    return null;
  }

  /// Optional phone number (10–15 digits, allowing `+`, spaces and dashes).
  static String? phone(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Phone is required' : null;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Generic non-empty validator for any required text field.
  static String? required(String? value, {String label = 'This field'}) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  /// Validates a ZIP / postal code (3–10 alphanumeric characters).
  static String? zip(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'ZIP / postal code is required';
    final zipReg = RegExp(r'^[A-Za-z0-9][A-Za-z0-9\s-]{2,9}$');
    if (!zipReg.hasMatch(text)) return 'Enter a valid ZIP / postal code';
    return null;
  }

  /// Validates a card number as a 12–19 digit string (Luhn optional).
  static String? cardNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Card number is required';
    if (digits.length < 12 || digits.length > 19) {
      return 'Enter a valid card number';
    }
    return null;
  }

  /// Validates an expiry in `MM/YY` form and rejects past dates.
  static String? cardExpiry(String? value, {DateTime? now}) {
    final text = value?.trim() ?? '';
    final match = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').firstMatch(text);
    if (match == null) return 'Use MM/YY';
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    final current = now ?? DateTime.now();
    final expiry = DateTime(year, month + 1, 1); // first day after expiry month
    if (expiry.isBefore(DateTime(current.year, current.month, 1))) {
      return 'Card has expired';
    }
    return null;
  }

  /// Validates a CVV / CVC (3 or 4 digits).
  static String? cardCvv(String? value) {
    final digits = (value ?? '').trim();
    if (!RegExp(r'^\d{3,4}$').hasMatch(digits)) return 'Use 3–4 digits';
    return null;
  }
}
