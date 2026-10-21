import 'package:flutter/material.dart';

/// Centralised colour palette for the **Bookstore** app.
///
/// Luxury Dark Midnight Blue and Warm Sand Gold palette matching the premium
/// bookstore aesthetic.
class AppColors {
  AppColors._();

  // ── Brand ───────────────────────────────
  /// Primary brand colour — Deep Midnight Navy.
  static const Color brand = Color(0xFF0B132B);
  static const Color brandDark = Color(0xFF070C1B);
  static const Color brandLight = Color(0xFF142247);

  /// Secondary brand colour — Warm Sand Gold.
  static const Color accent = Color(0xFFE2C08D);
  static const Color accentDark = Color(0xFFC69F65);
  static const Color accentLight = Color(0xFFF3E2C4);

  /// Tertiary colour — Warm Amber / Terracotta.
  static const Color terracotta = Color(0xFFD48B47);

  /// Two-stop gradient used by the brand mark, splash screen and hero banner.
  static const List<Color> brandGradient = <Color>[
    Color(0xFF0D1836),
    Color(0xFF070C1B),
  ];
  static const List<Color> accentGradient = <Color>[
    Color(0xFFE2C08D),
    Color(0xFFC69F65),
  ];

  // ── Neutrals ────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);

  // ── Light surfaces (Warm Parchment / Ivory) ──
  static const Color lightBackground = Color(0xFFF5F3EF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEFECE6);

  // ── Dark surfaces (Midnight Blue) ─────────────
  /// Page background — Midnight Blue.
  static const Color darkBackground = Color(0xFF0B132B);

  /// Cards and sheets — Deep Navy Container.
  static const Color darkSurface = Color(0xFF132042);

  /// Inputs, chips, dividers — Lifted Navy.
  static const Color darkSurfaceVariant = Color(0xFF1B2C58);

  // ── Semantic ────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  /// Star / rating gold.
  static const Color rating = Color(0xFFE2C08D);

  /// Approved payment / verified badge.
  static const Color verified = Color(0xFF38BDF8);

  // ── Order-status colours ────────────────
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusConfirmed = Color(0xFF3B82F6);
  static const Color statusShipped = Color(0xFF8B5CF6);
  static const Color statusDelivered = Color(0xFF34D399);
  static const Color statusCancelled = Color(0xFFEF4444);
}
