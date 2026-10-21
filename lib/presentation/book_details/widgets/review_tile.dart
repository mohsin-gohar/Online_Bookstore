import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/review_model.dart';

/// A single review card: avatar, name, star rating, comment, like button and
/// (for the author) edit/delete actions.
class ReviewTile extends StatelessWidget {
  const ReviewTile({
    super.key,
    required this.review,
    required this.currentUserId,
    this.isAdmin = false,
    this.onToggleLike,
    this.onEdit,
    this.onDelete,
  });

  final ReviewModel review;
  final String? currentUserId;
  final bool isAdmin;
  final VoidCallback? onToggleLike;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  bool get _isOwner => currentUserId != null && review.userId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liked = currentUserId != null && review.isLikedBy(currentUserId!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: review.userName, photoUrl: review.userPhoto),
              Gaps.hSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RatingBarIndicator(
                      rating: review.rating,
                      itemCount: 5,
                      itemSize: 14,
                      itemBuilder: (_, _) => const Icon(
                        Icons.star_rounded,
                        color: AppColors.rating,
                      ),
                    ),
                  ],
                ),
              ),
              if (review.createdAt != null)
                Text(
                  Formatters.relativeDate(review.createdAt!),
                  style: theme.textTheme.bodySmall,
                ),
              if (_isOwner || isAdmin)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    if (_isOwner)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          Gaps.xs,
          Text(review.comment, style: theme.textTheme.bodyMedium),
          Gaps.xs,
          Row(
            children: [
              TextButton.icon(
                onPressed: onToggleLike,
                icon: Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: liked ? AppColors.danger : null,
                ),
                label: Text(
                  review.likes > 0 ? '${review.likes}' : 'Like',
                  style: TextStyle(color: liked ? AppColors.danger : null),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photoUrl = ''});

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: CachedNetworkImageProvider(photoUrl),
      );
    }

    final initial = name.trim().isNotEmpty
        ? name.trim().characters.first.toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 18,
      backgroundColor: scheme.primary.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(
          color: scheme.brightness == Brightness.dark
              ? AppColors.white
              : AppColors.brand,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
