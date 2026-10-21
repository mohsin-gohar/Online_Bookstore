import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/address_model.dart';

/// Bottom sheet form for adding/editing an [AddressModel].
///
/// Returns the saved address via `Navigator.pop`, or null when cancelled.
class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({
    super.key,
    this.existing,
    this.makeDefaultFirst = false,
  });

  /// When provided, the form is pre-filled and edits this address.
  final AddressModel? existing;

  /// When true and no addresses exist yet, the new one becomes the default.
  final bool makeDefaultFirst;

  static Future<AddressModel?> show(
    BuildContext context, {
    AddressModel? existing,
    bool makeDefaultFirst = false,
  }) {
    return showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddressFormSheet(
        existing: existing,
        makeDefaultFirst: makeDefaultFirst,
      ),
    );
  }

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _label;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _zip;
  late final TextEditingController _phone;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _label = TextEditingController(text: a?.label ?? 'Home');
    _line1 = TextEditingController(text: a?.line1 ?? '');
    _line2 = TextEditingController(text: a?.line2 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _zip = TextEditingController(text: a?.zip ?? '');
    _phone = TextEditingController(text: a?.phone ?? '');
    _isDefault = a?.isDefault ?? widget.makeDefaultFirst;
  }

  @override
  void dispose() {
    _label.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _zip.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final address = AddressModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      label: _label.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      city: _city.text.trim(),
      zip: _zip.text.trim(),
      phone: _phone.text.trim(),
      isDefault: _isDefault,
    );
    Navigator.of(context).pop(address);
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
                isEditing ? 'Edit Address' : 'Add Address',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              Gaps.lg,
              _field(
                _label,
                'Label',
                'Home / Office',
                Icons.label_outline_rounded,
                validator: (v) => Validators.required(v, label: 'Label'),
              ),
              Gaps.md,
              _field(
                _line1,
                'Address line 1',
                '123 Main Street',
                Icons.home_outlined,
                validator: (v) => Validators.required(v, label: 'Address'),
              ),
              Gaps.md,
              _field(
                _line2,
                'Address line 2 (optional)',
                'Apt, suite, floor…',
                Icons.home_work_outlined,
              ),
              Gaps.md,
              _field(
                _city,
                'City',
                'New York',
                Icons.location_city_rounded,
                validator: (v) => Validators.required(v, label: 'City'),
              ),
              Gaps.md,
              _field(
                _zip,
                'ZIP / Postal code',
                '10001',
                Icons.markunread_mailbox_outlined,
                validator: Validators.zip,
              ),
              Gaps.md,
              _field(
                _phone,
                'Phone',
                '+1 555 010 1234',
                Icons.phone_outlined,
                keyboard: TextInputType.phone,
                validator: (v) => Validators.phone(v, required: true),
              ),
              Gaps.sm,
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default address'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
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
                      child: Text(isEditing ? AppStrings.save : 'Add Address'),
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

  Widget _field(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        Gaps.xs,
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: AppSizes.iconMd),
          ),
        ),
      ],
    );
  }
}
