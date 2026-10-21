import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/book_repository.dart';

/// The value produced by the filter sheet.
class FilterResult {
  const FilterResult({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sort,
    this.inStockOnly = false,
  });

  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final BookSort? sort;
  final bool inStockOnly;
}

/// A luxury dark navy & gold bottom sheet for filtering and sorting the catalog.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.categories,
    required this.initialSort,
    this.initialCategoryId,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinRating,
    this.initialInStockOnly = false,
  });

  final List<CategoryModel> categories;
  final BookSort initialSort;
  final String? initialCategoryId;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final double? initialMinRating;
  final bool initialInStockOnly;

  static Future<FilterResult?> show(
    BuildContext context, {
    required List<CategoryModel> categories,
    required BookSort initialSort,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool inStockOnly = false,
  }) {
    return showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      builder: (_) => FilterSheet(
        categories: categories,
        initialSort: initialSort,
        initialCategoryId: categoryId,
        initialMinPrice: minPrice,
        initialMaxPrice: maxPrice,
        initialMinRating: minRating,
        initialInStockOnly: inStockOnly,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  static const double _priceMin = 0;
  static const double _priceMax = 200;

  late RangeValues _priceRange;
  late BookSort _sort;
  String? _categoryId;
  double? _minRating;
  late bool _inStockOnly;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      (widget.initialMinPrice ?? _priceMin).clamp(_priceMin, _priceMax),
      (widget.initialMaxPrice ?? _priceMax).clamp(_priceMin, _priceMax),
    );
    _sort = widget.initialSort;
    _categoryId = widget.initialCategoryId;
    _minRating = widget.initialMinRating;
    _inStockOnly = widget.initialInStockOnly;
  }

  void _reset() {
    setState(() {
      _priceRange = const RangeValues(_priceMin, _priceMax);
      _sort = BookSort.newest;
      _categoryId = null;
      _minRating = null;
      _inStockOnly = false;
    });
  }

  void _apply() {
    final min = _priceRange.start <= _priceMin ? null : _priceRange.start;
    final max = _priceRange.end >= _priceMax ? null : _priceRange.end;

    Navigator.of(context).pop(
      FilterResult(
        categoryId: _categoryId,
        minPrice: min,
        maxPrice: max,
        minRating: _minRating,
        sort: _sort,
        inStockOnly: _inStockOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.xs,
              AppSizes.sm,
              AppSizes.xs,
            ),
            child: Row(
              children: [
                Text(
                  AppStrings.filters,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    AppStrings.reset,
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Scrollable body ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort
                  _Label(AppStrings.sortBy),
                  Gaps.xs,
                  Wrap(
                    spacing: AppSizes.xs,
                    runSpacing: AppSizes.xs,
                    children: BookSort.values
                        .map(
                          (s) => ChoiceChip(
                            label: Text(s.label),
                            selected: _sort == s,
                            selectedColor: AppColors.accent,
                            labelStyle: TextStyle(
                              color: _sort == s
                                  ? AppColors.brandDark
                                  : AppColors.grey300,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) => setState(() => _sort = s),
                          ),
                        )
                        .toList(),
                  ),
                  Gaps.lg,

                  // Category / Genre
                  _Label('Genre / Category'),
                  Gaps.xs,
                  Wrap(
                    spacing: AppSizes.xs,
                    runSpacing: AppSizes.xs,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _categoryId == null,
                        selectedColor: AppColors.accent,
                        labelStyle: TextStyle(
                          color: _categoryId == null
                              ? AppColors.brandDark
                              : AppColors.grey300,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setState(() => _categoryId = null),
                      ),
                      ...widget.categories.map(
                        (c) => ChoiceChip(
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          selectedColor: AppColors.accent,
                          labelStyle: TextStyle(
                            color: _categoryId == c.id
                                ? AppColors.brandDark
                                : AppColors.grey300,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) => setState(() => _categoryId = c.id),
                        ),
                      ),
                    ],
                  ),
                  Gaps.lg,

                  // Price range
                  Row(
                    children: [
                      _Label(AppStrings.priceRange),
                      const Spacer(),
                      Text(
                        '${Formatters.price(_priceRange.start)} – '
                        '${Formatters.price(_priceRange.end)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.darkSurfaceVariant,
                      thumbColor: AppColors.accent,
                    ),
                    child: RangeSlider(
                      min: _priceMin,
                      max: _priceMax,
                      divisions: 40,
                      values: _priceRange,
                      labels: RangeLabels(
                        Formatters.price(_priceRange.start),
                        Formatters.price(_priceRange.end),
                      ),
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                  ),
                  Gaps.sm,

                  // Rating
                  _Label(AppStrings.rating),
                  Gaps.xs,
                  Wrap(
                    spacing: AppSizes.xs,
                    children: [
                      _ratingChip(null, 'Any'),
                      _ratingChip(3, '3★+'),
                      _ratingChip(4, '4★+'),
                      _ratingChip(4.5, '4.5★+'),
                    ],
                  ),
                  Gaps.lg,

                  // In stock
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('In stock only'),
                    activeThumbColor: AppColors.accent,
                    value: _inStockOnly,
                    onChanged: (v) => setState(() => _inStockOnly = v),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ──
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text(AppStrings.clearAll),
                    ),
                  ),
                  Gaps.hSm,
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _apply,
                      child: const Text(AppStrings.apply),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingChip(double? value, String label) {
    final selected = _minRating == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(
        color: selected ? AppColors.brandDark : AppColors.grey300,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => setState(() => _minRating = value),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.accent,
      ),
    );
  }
}
