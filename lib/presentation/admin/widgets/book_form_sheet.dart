import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/category_model.dart';

/// Bottom sheet form for creating/editing a [BookModel].
///
/// Returns the assembled book (with a generated id when new) via
/// `Navigator.pop`. Cover images are entered as URLs; an admin can paste a
/// The cover image URL returned by the API. (Direct upload wiring lives in Phase 11's
/// storage service — this keeps the form usable immediately.)
class BookFormSheet extends StatefulWidget {
  const BookFormSheet({super.key, required this.categories, this.existing});

  final List<CategoryModel> categories;
  final BookModel? existing;

  static Future<BookModel?> show(
    BuildContext context, {
    required List<CategoryModel> categories,
    BookModel? existing,
  }) {
    return showModalBottomSheet<BookModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookFormSheet(categories: categories, existing: existing),
    );
  }

  @override
  State<BookFormSheet> createState() => _BookFormSheetState();
}

class _BookFormSheetState extends State<BookFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _isbn;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _cover;
  late final TextEditingController _publisher;
  late final TextEditingController _pages;

  String? _categoryId;
  bool _isBestseller = false;
  bool _isNewArrival = false;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _title = TextEditingController(text: b?.title ?? '');
    _author = TextEditingController(text: b?.author ?? '');
    _isbn = TextEditingController(text: b?.isbn ?? '');
    _description = TextEditingController(text: b?.description ?? '');
    _price = TextEditingController(text: b?.price.toString() ?? '');
    _stock = TextEditingController(text: b?.stock.toString() ?? '');
    _cover = TextEditingController(text: b?.coverImage ?? '');
    _publisher = TextEditingController(text: b?.publisher ?? '');
    _pages = TextEditingController(text: b?.pages.toString() ?? '');
    _categoryId = b?.categoryId.isNotEmpty == true ? b!.categoryId : null;
    _isBestseller = b?.isBestseller ?? false;
    _isNewArrival = b?.isNewArrival ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _author,
      _isbn,
      _description,
      _price,
      _stock,
      _cover,
      _publisher,
      _pages,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) return;

    final category = widget.categories.firstWhere(
      (c) => c.id == _categoryId,
      orElse: () => widget.categories.first,
    );
    final book = BookModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _title.text.trim(),
      author: _author.text.trim(),
      isbn: _isbn.text.trim(),
      description: _description.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      coverImage: _cover.text.trim(),
      categoryId: category.id,
      categoryName: category.name,
      publisher: _publisher.text.trim(),
      pages: int.tryParse(_pages.text.trim()) ?? 0,
      rating: widget.existing?.rating ?? 0,
      reviewCount: widget.existing?.reviewCount ?? 0,
      isBestseller: _isBestseller,
      isNewArrival: _isNewArrival,
      releaseDate: widget.existing?.releaseDate,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(book);
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Edit Book' : 'Add Book',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Gaps.md,
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(
                        _title,
                        'Title',
                        validator: (v) =>
                            Validators.required(v, label: 'Title'),
                      ),
                      Gaps.md,
                      _field(
                        _author,
                        'Author',
                        validator: (v) =>
                            Validators.required(v, label: 'Author'),
                      ),
                      Gaps.md,
                      _field(_isbn, 'ISBN'),
                      Gaps.md,
                      _field(
                        _cover,
                        'Cover image URL',
                        hint: 'https://…',
                        keyboard: TextInputType.url,
                      ),
                      Gaps.md,
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _price,
                              'Price',
                              keyboard: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                final p = double.tryParse(v.trim());
                                if (p == null || p < 0) return 'Invalid price';
                                return null;
                              },
                            ),
                          ),
                          Gaps.hSm,
                          Expanded(
                            child: _field(
                              _stock,
                              'Stock',
                              keyboard: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                final s = int.tryParse(v.trim());
                                if (s == null || s < 0) return 'Invalid stock';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      Gaps.md,
                      Text('Category', style: _labelStyle(theme)),
                      Gaps.xs,
                      DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        items: widget.categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) =>
                            v == null ? 'Select a category' : null,
                        decoration: const InputDecoration(
                          hintText: 'Select category',
                        ),
                      ),
                      Gaps.md,
                      Row(
                        children: [
                          Expanded(child: _field(_publisher, 'Publisher')),
                          Gaps.hSm,
                          Expanded(
                            child: _field(
                              _pages,
                              'Pages',
                              keyboard: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Gaps.md,
                      _field(_description, 'Description', maxLines: 4),
                      Gaps.sm,
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bestseller'),
                        value: _isBestseller,
                        onChanged: (v) => setState(() => _isBestseller = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('New arrival'),
                        value: _isNewArrival,
                        onChanged: (v) => setState(() => _isNewArrival = v),
                      ),
                      Gaps.md,
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
                              child: Text(
                                isEditing ? AppStrings.save : 'Add Book',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _labelStyle(ThemeData theme) =>
      theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(Theme.of(context))),
        Gaps.xs,
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          validator: validator,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
