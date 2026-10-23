import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Ultra-resilient, luxury book cover widget with elegant fallback styling.
///
/// Prevents red error boxes and broken images under any network condition:
/// - Handles empty, invalid, or 404 image URLs.
/// - Shows a refined subtle loading indicator while downloading.
/// - Renders an authentic hardcover book spine with gold accents and title
///   when the remote image fails or is unavailable.
class BookCoverImage extends StatelessWidget {
  const BookCoverImage({
    super.key,
    required this.imageUrl,
    this.title,
    this.author,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.icon,
    this.heroTag,
  });

  final String imageUrl;
  final String? title;
  final String? author;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData? icon;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppSizes.radiusMd);

    Widget imageContent;

    final trimmedUrl = imageUrl.trim();
    final hasValidUrl = trimmedUrl.isNotEmpty &&
        (trimmedUrl.startsWith('http://') ||
            trimmedUrl.startsWith('https://'));

    if (!hasValidUrl) {
      // No valid URL — use a reliable Unsplash placeholder based on title hash
      imageContent = CachedNetworkImage(
        imageUrl: _defaultPlaceholderUrl(title ?? 'book'),
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, _) => _buildShimmer(effectiveRadius),
        errorWidget: (_, _, _) => _buildFallback(context, effectiveRadius),
      );
    } else {
      imageContent = CachedNetworkImage(
        imageUrl: trimmedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, _) => _buildShimmer(effectiveRadius),
        errorWidget: (_, _, _) => CachedNetworkImage(
          imageUrl: _defaultPlaceholderUrl(title ?? 'book'),
          width: width,
          height: height,
          fit: fit,
          errorWidget: (_, _, _) => _buildFallback(context, effectiveRadius),
        ),
      );
    }

    final clipped = ClipRRect(
      borderRadius: effectiveRadius,
      child: SizedBox(width: width, height: height, child: imageContent),
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(tag: heroTag!, child: clipped);
    }
    return clipped;
  }

  Widget _buildShimmer(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: radius,
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  /// Generates a consistent Unsplash placeholder URL based on the book title.
  /// Uses a hash of the title so the same book always gets the same image.
  String _defaultPlaceholderUrl(String title) {
    final hash = title.hashCode.abs() % 1000;
    // Use Unsplash source with book/library keywords for relevant placeholders.
    return 'https://images.unsplash.com/photo-'
        '1507842217228-2a47709b9d60?w=400&h=600&fit=crop&auto=format'
        '&seed=$hash';
  }

  Widget _buildFallback(BuildContext context, BorderRadius radius) {
    final displayTitle = title?.trim() ?? '';
    final displayAuthor = author?.trim() ?? '';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2D54), Color(0xFF0F172A)],
        ),
        borderRadius: radius,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Simulated Hardcover Book Spine Crease on left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 7,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Fallback Artwork & Typography
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon ?? Icons.auto_stories_rounded,
                    size: (width != null && width! < 80) ? 20 : 26,
                    color: AppColors.accent,
                  ),
                  if (displayTitle.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      displayTitle,
                      maxLines: (height != null && height! < 120) ? 2 : 3,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: (width != null && width! < 80) ? 9 : 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ],
                  if (displayAuthor.isNotEmpty &&
                      (height == null || height! >= 130)) ...[
                    const SizedBox(height: 3),
                    Text(
                      displayAuthor,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        color: AppColors.accent.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
