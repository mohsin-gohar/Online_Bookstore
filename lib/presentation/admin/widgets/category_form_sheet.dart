import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/category_model.dart';

/// Bottom sheet form for creating/editing a [CategoryModel].
class CategoryFormSheet extends StatefulWidget {
  const CategoryFormSheet({super.key, this.existing});

  final CategoryModel? existing;

  static Future<CategoryModel?> show(
    BuildContext context, {
    CategoryModel? existing,
  }) {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryFormSheet(existing: existing),
    );
  }

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _image;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _description = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    _image = TextEditingController(text: widget.existing?.image ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _image.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final category = CategoryModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      image: _image.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.xs,
        AppSizes.md,
        AppSizes.md + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Category' : 'Add Category',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              Gaps.lg,
              Text('Name', style: _label(theme)),
              Gaps.xs,
              TextFormField(
                controller: _name,
                validator: (v) => Validators.required(v, label: 'Name'),
                decoration: const InputDecoration(hintText: 'e.g. Fiction'),
              ),
              Gaps.md,
              Text('Image URL (optional)', style: _label(theme)),
              Gaps.xs,
              TextFormField(
                controller: _image,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'https://…'),
              ),
              Gaps.md,
              Text('Description (optional)', style: _label(theme)),
              Gaps.xs,
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Short description',
                ),
              ),
              Gaps.lg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  Gaps.hSm,
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text(isEditing ? AppStrings.save : 'Add Category'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle? _label(ThemeData theme) =>
      theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
}
