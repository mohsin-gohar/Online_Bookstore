import 'package:intl/intl.dart';

/// Display formatting helpers (currency, dates, numbers).
///
/// A single currency symbol/code is defined here; change [_currencyCode] to
/// re-brand pricing across the whole app.
class Formatters {
  Formatters._();

  /// ISO-4217 currency code used for all prices.
  static const String _currencyCode = 'USD';

  /// Public accessor for the configured currency code (e.g. shown on receipts).
  static String get currencyCode => _currencyCode;

  /// Currency symbol shown before amounts (kept in sync with [_currencyCode]).
  static const String currencySymbol = r'$';

  static final NumberFormat _currency = NumberFormat.currency(
    symbol: currencySymbol,
    decimalDigits: 2,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    symbol: currencySymbol,
    decimalDigits: 0,
  );

  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDate = DateFormat('dd MMM');

  /// `$12.50`
  static String price(num value) => _currency.format(value);

  /// `$1.2K` — compact form for dashboard stat cards.
  static String compactPrice(num value) => _compact.format(value);

  /// `12 Mar 2025`
  static String date(DateTime value) => _date.format(value);

  /// `12 Mar 2025, 04:30 PM`
  static String dateTime(DateTime value) => _dateTime.format(value);

  /// `12 Mar`
  static String shortDate(DateTime value) => _shortDate.format(value);

  /// `3 days ago`, `Today`, `Yesterday`, or an absolute date for older items.
  static String relativeDate(DateTime value, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(value);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && current.day == value.day) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return date(value);
  }

  /// Formats a whole-number rating, e.g. `4.5`.
  static String rating(double value) => value.toStringAsFixed(1);

  /// `1 item` / `3 items`.
  static String itemCount(int count) => count == 1 ? '1 item' : '$count items';

  /// Masks a card number down to its last four digits, e.g. `•• 4242`.
  static String maskedCard(String last4) => '•• ${last4.padLeft(4, '•')}';

  /// Turns a full card number into its `last4`.
  static String last4(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return digits;
    return digits.substring(digits.length - 4);
  }

  /// Formats an order number like `#BS-20250312-0042`.
  static String orderNumber(String id) {
    final now = DateTime.now();
    final stamp = DateFormat('yyyyMMdd').format(now);
    final suffix = id.length >= 4 ? id.substring(id.length - 4) : id;
    return '#BS-$stamp-${suffix.toUpperCase()}';
  }
}
