import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../data/models/category_model.dart';

/// A circular category tile (image or initial) with a label underneath.
///
/// Used in the horizontal "Categories" row on the home screen. Falls back to a
/// coloured circle with the category's first letter when no image is set.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.25),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: category.image.isEmpty
                  ? Center(
                      child: Text(
                        category.name.isNotEmpty
                            ? category.name.characters.first.toUpperCase()
                            : '#',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: category.image,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: scheme.surfaceContainerHighest),
                      errorWidget: (_, _, _) => Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: scheme.primary,
                        ),
                      ),
                    ),
            ),
            Gaps.xs,
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
