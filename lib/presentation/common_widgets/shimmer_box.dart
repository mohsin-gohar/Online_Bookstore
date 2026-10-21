import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// A single shimmering block used to build skeleton loaders.
///
/// Wrap a layout of these in place of real content while data loads. The base
/// and highlight colours adapt to light/dark themes automatically.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppSizes.radiusMd,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _base(context),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Skeleton for a book card (cover + two text lines).
class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({super.key, this.width = AppSizes.coverWidth});

  final double width;

  @override
  Widget build(BuildContext context) {
    final coverHeight = width / AppSizes.coverAspect;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: width, height: coverHeight),
          Gaps.xs,
          ShimmerBox(width: width * 0.9, height: 12, radius: 6),
          Gaps.xxs,
          ShimmerBox(width: width * 0.6, height: 12, radius: 6),
        ],
      ),
    );
  }
}

/// Horizontal row of [count] book-card skeletons (bestseller carousel).
class BookRowSkeleton extends StatelessWidget {
  const BookRowSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (AppSizes.coverWidth / AppSizes.coverAspect) + 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: count,
        separatorBuilder: (_, _) => Gaps.hSm,
        itemBuilder: (_, _) => const BookCardSkeleton(),
      ),
    );
  }
}

/// Skeleton for a category chip/pill row.
class CategoryRowSkeleton extends StatelessWidget {
  const CategoryRowSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: count,
        separatorBuilder: (_, _) => Gaps.hSm,
        itemBuilder: (_, _) => const Column(
          children: [
            ShimmerBox(width: 64, height: 64, radius: 32),
            Gaps.xs,
            ShimmerBox(width: 52, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}

/// Grid of book-card skeletons (new arrivals / catalog).
class BookGridSkeleton extends StatelessWidget {
  const BookGridSkeleton({super.key, this.count = 6, this.crossAxisCount = 2});

  final int count;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      // Responsive: matches the real book grid (2 cols on phones, more on
      // tablets), so skeletons align with the loaded cards.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        crossAxisSpacing: AppSizes.sm,
        mainAxisSpacing: AppSizes.md,
        childAspectRatio: 0.52,
      ),
      itemBuilder: (_, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ShimmerBox(width: double.infinity, height: 200)),
          Gaps.xs,
          ShimmerBox(width: 120, height: 12, radius: 6),
        ],
      ),
    );
  }
}

// ── Shared shimmer wrapper + palette ──────────────────────

Color _base(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppColors.darkSurfaceVariant
    : AppColors.lightSurfaceVariant;

Color _highlight(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF334038)
    : const Color(0xFFF8F4EC);

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      child: child,
    );
  }
}
