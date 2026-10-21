import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import 'brand_mark.dart';

/// A compact brand lockup (mark + wordmark) used on the auth screens.
///
/// [showWordmark] hides the text when space is tight. The mark mirrors the
/// splash screen so the brand feels consistent across the funnel.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.showWordmark = true,
    this.showTagline = false,
  });

  final double size;
  final bool showWordmark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size),
        if (showWordmark) ...[
          const SizedBox(height: 12),
          Text(
            AppStrings.appName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: AppTheme.displayFontFamily,
              fontFamilyFallback: AppTheme.displayFontFallback,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
        if (showTagline) ...[
          const SizedBox(height: 6),
          const BrassRule(),
          const SizedBox(height: 8),
          Text(
            AppStrings.appTagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
