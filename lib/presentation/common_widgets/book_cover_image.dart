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

    final trimmedUrl = imageUrl.trim();
    final hasValidUrl =
        trimmedUrl.isNotEmpty &&
        (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://'));

    final Widget imageContent;
    if (!hasValidUrl) {
      imageContent = _buildFallback(context, effectiveRadius);
    } else {
      imageContent = CachedNetworkImage(
        imageUrl: trimmedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, _) => _buildShimmer(effectiveRadius),
        // Some providers (e.g. OpenLibrary) answer missing covers with a 1x1
        // transparent GIF that "loads" fine but paints nothing, so validate
        // the decoded size before trusting the image.
        imageBuilder: (context, imageProvider) => _CoverGuard(
          key: ValueKey(trimmedUrl),
          imageProvider: imageProvider,
          fallback: _buildFallback(context, effectiveRadius),
          fit: fit,
          width: width,
          height: height,
        ),
        errorWidget: (_, _, _) => _buildFallback(context, effectiveRadius),
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
          // Fallback Artwork & Typography. Excluded from semantics because the
          // title/author are always rendered next to the cover as well.
          ExcludeSemantics(
            child: Center(
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
          ),
        ],
      ),
    );
  }
}

/// Displays a decoded cover only when it has real pixels; otherwise swaps in
/// the generated artwork.
class _CoverGuard extends StatefulWidget {
  const _CoverGuard({
    super.key,
    required this.imageProvider,
    required this.fallback,
    required this.fit,
    this.width,
    this.height,
  });

  final ImageProvider<Object> imageProvider;
  final Widget fallback;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  State<_CoverGuard> createState() => _CoverGuardState();
}

class _CoverGuardState extends State<_CoverGuard> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _isBlank = false;

  @override
  void initState() {
    super.initState();
    _stream = widget.imageProvider.resolve(const ImageConfiguration());
    _listener = ImageStreamListener(
      (info, _) {
        if (info.image.width <= 2 || info.image.height <= 2) {
          if (!mounted || _isBlank) return;
          setState(() => _isBlank = true);
        }
      },
      onError: (_, _) {
        if (!mounted || _isBlank) return;
        setState(() => _isBlank = true);
      },
    );
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBlank) return widget.fallback;
    return Image(
      image: widget.imageProvider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
