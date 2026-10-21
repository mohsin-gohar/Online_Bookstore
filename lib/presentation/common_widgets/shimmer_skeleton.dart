import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// Smooth, dependency-free shimmer loading skeleton.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        widget.baseColor ??
        (isDark ? const Color(0xFF162344) : const Color(0xFFE2E8F0));
    final highlight =
        widget.highlightColor ??
        (isDark ? const Color(0xFF263763) : const Color(0xFFF8FAFC));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              colors: [base, base, highlight, base, base],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}

/// A rounded placeholder box for shimmer loading.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B2C58)
            : const Color(0xFFE2E8F0),
        borderRadius: borderRadius ?? BorderRadius.circular(AppSizes.radiusSm),
      ),
    );
  }
}

/// Shimmer placeholder rail for books.
class BookCardSkeletonRail extends StatelessWidget {
  const BookCardSkeletonRail({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SizedBox(
        height: 250,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, _) => Gaps.hMd,
          itemBuilder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: 130,
                height: 180,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              Gaps.xs,
              const ShimmerBox(width: 110, height: 14),
              Gaps.xxs,
              const ShimmerBox(width: 70, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
