import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import 'custom_button.dart';

/// An error-state placeholder with a retry action.
///
/// Shown when a screen's initial load fails (offline, permission denied, …).
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = Icons.cloud_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 112,
              width: 112,
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: scheme.error),
            ),
            Gaps.lg,
            Text(
              AppStrings.somethingWentWrong,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            Gaps.xs,
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              Gaps.lg,
              SizedBox(
                width: 220,
                child: CustomButton(
                  label: retryLabel,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
