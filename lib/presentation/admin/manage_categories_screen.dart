import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../logic/book_provider.dart';
import '../common_widgets/custom_appbar.dart';
import '../common_widgets/empty_state.dart';
import 'widgets/category_form_sheet.dart';

/// Admin: CRUD for categories.
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  Future<void> _add() async {
    final category = await CategoryFormSheet.show(context);
    if (category == null || !mounted) return;
    try {
      await context.read<CategoryRepository>().createCategory(category);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Category added');
      _reload();
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, e.toString());
    }
  }

  Future<void> _edit(CategoryModel category) async {
    final updated = await CategoryFormSheet.show(context, existing: category);
    if (updated == null || !mounted) return;
    try {
      await context.read<CategoryRepository>().updateCategory(updated);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Category updated');
      _reload();
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, e.toString());
    }
  }

  Future<void> _delete(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "${category.name}"? Books keep their stored name.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<CategoryRepository>().deleteCategory(category.id);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Category deleted');
      _reload();
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, e.toString());
    }
  }

  void _reload() {
    context.read<BookProvider>().loadHome();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookProvider>();
    final state = books.categories;

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.manageCategories,
        showCart: false,
        showHome: false,
        fallbackRoute: AppRoutes.adminDashboardPath,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: state.isLoading && !state.hasLoadedOnce
          ? const Center(child: CircularProgressIndicator())
          : (state.data ?? const []).isEmpty
          ? const EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories',
              message: 'Tap "Add" to create your first category.',
            )
          : RefreshIndicator(
              onRefresh: () => books.loadHome(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md,
                  AppSizes.md,
                  AppSizes.md,
                  AppSizes.xxl * 2,
                ),
                itemCount: state.data!.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = state.data![i];
                  return _CategoryRow(
                    category: c,
                    onEdit: () => _edit(c),
                    onDelete: () => _delete(c),
                  );
                },
              ),
            ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: category.image.isEmpty
                  ? Container(
                      color: scheme.primary.withValues(alpha: 0.12),
                      child: Center(
                        child: Text(
                          category.name.isNotEmpty
                              ? category.name.characters.first.toUpperCase()
                              : '#',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: category.image,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: scheme.surfaceContainerHighest),
                      errorWidget: (_, _, _) =>
                          Icon(Icons.menu_book_rounded, color: scheme.primary),
                    ),
            ),
          ),
          Gaps.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (category.description.isNotEmpty)
                  Text(
                    category.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
