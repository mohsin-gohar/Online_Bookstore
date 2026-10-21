import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';

/// A tappable, non-editable search field used on the home screen.
///
/// It looks like a text field but is really a button that navigates to the
/// dedicated search screen (Phase 5) — this avoids focus/keyboard issues in the
/// scrolling home list.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () => context.push(AppRoutes.searchPath),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm + 2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              Gaps.hSm,
              Expanded(
                child: Text(
                  AppStrings.searchHint,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
