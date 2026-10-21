import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'custom_button.dart';

/// A friendly empty-state placeholder: icon-in-a-circle, title, message and an
/// optional action button.
///
/// Used wherever a list can legitimately be empty (cart, wishlist, orders,
/// search results). Kept asset-free (icon based) so it renders correctly before
/// custom illustrations are bundled.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Reduces vertical padding for use inside fixed-height containers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: compact ? AppSizes.lg : AppSizes.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 112,
              width: 112,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: scheme.primary),
            ),
            Gaps.lg,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            Gaps.xs,
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              Gaps.lg,
              SizedBox(
                width: 220,
                child: CustomButton(label: actionLabel!, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
