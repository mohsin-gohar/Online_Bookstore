import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Centralised SnackBar feedback with consistent styling and behaviour.
///
/// All app feedback funnels through here so we never show two SnackBars at
/// once and every message looks the same. Call these from UI code:
/// ```dart
/// SnackbarHelper.showError(context, 'Invalid email or password');
/// ```
class SnackbarHelper {
  SnackbarHelper._();

  /// Shows a neutral/informational message.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      accent: AppColors.info,
      duration: duration,
    );
  }

  /// Shows a success message (e.g. "Order placed").
  ///
  /// An optional [actionLabel]/[onAction] pair renders a tappable action
  /// (e.g. "View" after a book is added, to open its public page).
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      accent: AppColors.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows an error message (e.g. failed login). Longer default duration so
  /// the user can read what went wrong.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      accent: AppColors.danger,
      duration: duration,
    );
  }

  /// Shows a warning message (e.g. "Out of stock").
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      accent: AppColors.warning,
      duration: duration,
    );
  }

  // ── Internal ─────────────────────────────

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color accent,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final hasAction = actionLabel != null && onAction != null;

    // Replace any visible SnackBar so rapid actions don't queue up.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          content: Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
          action: hasAction
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }
}
