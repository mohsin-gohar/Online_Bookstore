import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// The **Folio** brand mark — a hand-drawn open book on a pine tile with a
/// brass foil band.
///
/// This replaces the stock Material `menu_book_rounded` icon that earlier
/// versions used, so the product has a distinct, ownable identity rather than
/// a generic "book app" glyph.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72, this.onDark = false});

  /// Edge length of the square mark.
  final double size;

  /// When true the mark is drawn for a dark (brand-green) backdrop, i.e. the
  /// tile becomes cream and the artwork becomes green.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(onDark: onDark),
        isComplex: true,
      ),
    );
  }
}

/// The wordmark ("Folio") plus optional tagline, used on the splash screen
/// and the auth screens.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.name,
    this.tagline,
    this.onDark = false,
    this.fontSize = 34,
  });

  final String? name;
  final String? tagline;
  final bool onDark;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.headlineMedium?.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: onDark ? AppColors.white : theme.colorScheme.onSurface,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name ?? 'Folio', style: nameStyle),
        if (tagline != null) ...[
          const SizedBox(height: 6),
          // A short brass rule under the wordmark — the "foil" detail.
          Container(
            width: 42,
            height: 2,
            decoration: BoxDecoration(
              color: onDark ? AppColors.accentLight : AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tagline!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onDark
                  ? AppColors.white.withValues(alpha: 0.85)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// A short brass hairline used to separate editorial sections.
class BrassRule extends StatelessWidget {
  const BrassRule({super.key, this.width = 44, this.height = 2});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}

/// Paints the brand tile + open-book artwork.
class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Offset center = Offset(s / 2, s / 2);

    // ── Tile ─────────────────────────────────
    final Rect tile = Offset.zero & size;
    final RRect tileRRect = RRect.fromRectAndRadius(
      tile,
      Radius.circular(s * 0.26),
    );

    final Paint tilePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: onDark
            ? const <Color>[Color(0xFFFFFDF8), Color(0xFFF0E9DC)]
            : AppColors.brandGradient,
      ).createShader(tile);
    canvas.drawRRect(tileRRect, tilePaint);

    // Brass hairline along the tile edge.
    canvas.drawRRect(
      tileRRect.deflate(s * 0.018),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..color = (onDark ? AppColors.accent : AppColors.accentLight)
            .withValues(alpha: 0.55),
    );

    final Color paper = onDark ? AppColors.brand : AppColors.white;
    final Color ink = onDark ? AppColors.white : AppColors.brand;

    // ── Open book ────────────────────────────
    final double halfW = s * 0.28;
    final double bottom = s * 0.70;
    final double midY = s * 0.485;

    final Path left = Path()
      ..moveTo(center.dx, midY - s * 0.05)
      ..cubicTo(
        center.dx - halfW * 0.55,
        midY - s * 0.135,
        center.dx - halfW * 0.95,
        midY - s * 0.115,
        center.dx - halfW,
        midY - s * 0.075,
      )
      ..lineTo(center.dx - halfW, bottom - s * 0.045)
      ..cubicTo(
        center.dx - halfW * 0.95,
        bottom - s * 0.105,
        center.dx - halfW * 0.55,
        bottom - s * 0.075,
        center.dx,
        bottom,
      )
      ..close();

    final Path right = Path()
      ..moveTo(center.dx, midY - s * 0.05)
      ..cubicTo(
        center.dx + halfW * 0.55,
        midY - s * 0.135,
        center.dx + halfW * 0.95,
        midY - s * 0.115,
        center.dx + halfW,
        midY - s * 0.075,
      )
      ..lineTo(center.dx + halfW, bottom - s * 0.045)
      ..cubicTo(
        center.dx + halfW * 0.95,
        bottom - s * 0.105,
        center.dx + halfW * 0.55,
        bottom - s * 0.075,
        center.dx,
        bottom,
      )
      ..close();

    canvas.drawPath(left, Paint()..color = paper);
    canvas.drawPath(right, Paint()..color = paper.withValues(alpha: 0.82));

    // Page lines (a hint of text on the left page).
    final Paint linePaint = Paint()
      ..color = ink.withValues(alpha: 0.22)
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final double y = midY + s * 0.005 + i * s * 0.052;
      canvas.drawLine(
        Offset(center.dx - halfW * 0.82, y),
        Offset(center.dx - halfW * 0.16, y - s * 0.012),
        linePaint,
      );
    }

    // Spine.
    canvas.drawLine(
      Offset(center.dx, midY - s * 0.05),
      Offset(center.dx, bottom),
      Paint()
        ..color = onDark ? AppColors.accentDark : AppColors.brandDark
        ..strokeWidth = s * 0.022
        ..strokeCap = StrokeCap.round,
    );

    // ── Brass foil band ──────────────────────
    final Rect band = Rect.fromLTWH(
      center.dx - s * 0.17,
      s * 0.795,
      s * 0.34,
      s * 0.045,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, Radius.circular(s * 0.023)),
      Paint()..color = onDark ? AppColors.accent : AppColors.accentLight,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) =>
      oldDelegate.onDark != onDark;
}

/// Convenience wrapper that stacks the mark, wordmark and tagline.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.name,
    this.tagline,
    this.onDark = false,
    this.markSize = 84,
  });

  final String? name;
  final String? tagline;
  final bool onDark;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize, onDark: onDark),
        Gaps.md,
        BrandWordmark(name: name, tagline: tagline, onDark: onDark),
      ],
    );
  }
}
