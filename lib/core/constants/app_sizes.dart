import 'package:flutter/material.dart';

/// Spacing, radius and sizing tokens.
///
/// Using a fixed scale (4/8/12/16…) keeps the UI visually consistent and makes
/// responsive tweaks a single-file change. [AppSizes] holds constants while
/// [Gaps] provides ready-made spacers for brevity in widgets.
class AppSizes {
  AppSizes._();

  // ── Spacing scale ──────────────────────
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // ── Radii ──────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  // ── Components ─────────────────────────
  static const double buttonHeight = 52;
  static const double inputHeight = 56;
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;

  // ── Book covers ────────────────────────
  static const double coverAspect = 2 / 3; // width:height
  static const double coverWidth = 130;
  static const double coverHeight = coverWidth / coverAspect;

  // ── Responsive breakpoints ─────────────
  /// Width below which the layout is considered a phone.
  static const double tabletBreakpoint = 600;

  /// Max content width so large tablets don't stretch content edge-to-edge.
  static const double maxContentWidth = 720;

  // ── Shadows ────────────────────────────
  static List<BoxShadow> get softShadow => const [
    BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> get mediumShadow => const [
    BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

/// Convenience spacers so widgets read `Gaps.md` instead of `SizedBox(height: 16)`.
///
/// Named `Gaps` (not `Gap`) to avoid clashing with Flutter's built-in `Gap`
/// sliver widget exported by `package:flutter/material.dart`.
class Gaps {
  Gaps._();

  static const Widget xxs = SizedBox(height: AppSizes.xxs, width: AppSizes.xxs);
  static const Widget xs = SizedBox(height: AppSizes.xs, width: AppSizes.xs);
  static const Widget sm = SizedBox(height: AppSizes.sm, width: AppSizes.sm);
  static const Widget md = SizedBox(height: AppSizes.md, width: AppSizes.md);
  static const Widget lg = SizedBox(height: AppSizes.lg, width: AppSizes.lg);
  static const Widget xl = SizedBox(height: AppSizes.xl, width: AppSizes.xl);
  static const Widget xxl = SizedBox(height: AppSizes.xxl, width: AppSizes.xxl);

  static const Widget hXs = SizedBox(width: AppSizes.xs);
  static const Widget hSm = SizedBox(width: AppSizes.sm);
  static const Widget hMd = SizedBox(width: AppSizes.md);
  static const Widget hLg = SizedBox(width: AppSizes.lg);
  static const Widget hXl = SizedBox(width: AppSizes.xl);
}
