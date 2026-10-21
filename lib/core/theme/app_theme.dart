import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Material 3 themes for **Bookstore**.
///
/// Luxury Dark Midnight Blue and Warm Sand Gold theme matching the premium
/// bookstore aesthetic.
class AppTheme {
  AppTheme._();

  /// Serif stack used for editorial headings.
  static const String displayFontFamily = 'Georgia';
  static const List<String> displayFontFallback = <String>[
    'serif',
    'Times New Roman',
  ];

  /// Light theme — clean parchment and gold.
  static ThemeData get light => _base(
    brightness: Brightness.light,
    scheme: _lightScheme,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    background: AppColors.lightBackground,
    outline: const Color(0xFFCBD5E1),
    outlineVariant: const Color(0xFFE2E8F0),
    onSurface: AppColors.grey900,
    onSurfaceVariant: AppColors.grey600,
    hairline: const Color(0xFFE2E8F0),
    shadow: const Color(0x14000000),
  );

  /// Dark theme — luxury Midnight Blue and Warm Sand Gold.
  static ThemeData get dark => _base(
    brightness: Brightness.dark,
    scheme: _darkScheme,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    background: AppColors.darkBackground,
    outline: const Color(0xFF2A3C6A),
    outlineVariant: const Color(0xFF1E2E54),
    onSurface: AppColors.grey50,
    onSurfaceVariant: const Color(0xFF94A3B8),
    hairline: const Color(0xFF1E2D54),
    shadow: const Color(0x40000000),
  );

  // ─────────────────────────────
  // Colour schemes
  // ─────────────────────────────

  static final ColorScheme _lightScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brand,
    onPrimary: AppColors.white,
    primaryContainer: Color(0xFF142247),
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.accent,
    onSecondary: AppColors.brandDark,
    secondaryContainer: Color(0xFFF3E2C4),
    onSecondaryContainer: Color(0xFF5C4110),
    tertiary: AppColors.terracotta,
    onTertiary: AppColors.white,
    error: AppColors.danger,
    onError: AppColors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.grey900,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: AppColors.lightSurfaceVariant,
    surfaceContainerHigh: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFFCBD5E1),
    surfaceTint: Colors.transparent,
    outline: Color(0xFFCBD5E1),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static final ColorScheme _darkScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accent, // Warm Sand Gold as primary in dark mode
    onPrimary: AppColors.brandDark, // Dark Navy text on Gold
    primaryContainer: Color(0xFF1B2C58),
    onPrimaryContainer: AppColors.accentLight,
    secondary: AppColors.accentLight,
    onSecondary: AppColors.brandDark,
    secondaryContainer: Color(0xFF253766),
    onSecondaryContainer: AppColors.accentLight,
    tertiary: AppColors.terracotta,
    onTertiary: AppColors.white,
    error: AppColors.danger,
    onError: AppColors.white,
    surface: AppColors.darkSurface, // Deep Navy Container
    onSurface: AppColors.grey50, // Cream / Ivory text
    surfaceContainerLowest: Color(0xFF070C1B),
    surfaceContainerLow: Color(0xFF0B132B),
    surfaceContainer: AppColors.darkSurfaceVariant,
    surfaceContainerHigh: Color(0xFF223462),
    surfaceContainerHighest: Color(0xFF2A3E74),
    surfaceTint: Colors.transparent,
    outline: Color(0xFF2A3C6A),
    outlineVariant: Color(0xFF1E2E54),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // ─────────────────────────────
  // Internals
  // ─────────────────────────────

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color surface,
    required Color surfaceVariant,
    required Color background,
    required Color outline,
    required Color outlineVariant,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color hairline,
    required Color shadow,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final TextTheme textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      fontFamily: null,

      // ── AppBar ──────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // ── Cards ────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: hairline),
        ),
      ),

      // ── Buttons ──────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : scheme.primary,
          foregroundColor: isDark ? AppColors.brandDark : scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : scheme.primary,
          foregroundColor: isDark ? AppColors.brandDark : scheme.onPrimary,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.accent : scheme.onSurface,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          side: BorderSide(color: isDark ? AppColors.accent : outline),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.accent : scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Inputs ───────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant.withValues(alpha: 0.7),
        ),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(hairline),
        focusedBorder: _inputBorder(
          isDark ? AppColors.accent : scheme.primary,
          width: 1.6,
        ),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.6),
      ),

      // ── Chips ────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: AppColors.accent,
        labelStyle:
            textTheme.labelMedium?.copyWith(color: onSurface) ??
            const TextStyle(),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.brandDark,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
      ),

      // ── Navigation bar (customer bottom tabs) ─
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? (isDark ? AppColors.accent : scheme.primary)
                : onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? (isDark ? AppColors.accent : scheme.primary)
                : onSurfaceVariant,
          );
        }),
      ),

      // ── Bottom sheet ─────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
      ),

      // ── Dialog ───────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: hairline),
        ),
      ),

      // ── Misc ────────────────────────────────
      dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.grey900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.accent : scheme.primary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? AppColors.accent : scheme.primary,
        foregroundColor: isDark ? AppColors.brandDark : scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final Color on = scheme.onSurface;

    TextStyle display({
      required double size,
      required FontWeight weight,
      double spacing = 0,
    }) {
      return TextStyle(
        fontFamily: displayFontFamily,
        fontFamilyFallback: displayFontFallback,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: 1.15,
        color: on,
      );
    }

    return TextTheme(
      displaySmall: display(size: 34, weight: FontWeight.w700, spacing: -0.4),
      headlineMedium: display(size: 28, weight: FontWeight.w700, spacing: -0.3),
      headlineSmall: display(size: 24, weight: FontWeight.w700),
      titleLarge: display(size: 20, weight: FontWeight.w700, spacing: 0.1),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: on,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: on),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
      labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}
