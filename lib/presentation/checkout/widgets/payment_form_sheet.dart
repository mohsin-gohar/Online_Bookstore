import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/payment_method_model.dart';

/// Detects a card brand from its leading digits (display-only heuristic).
String detectCardBrand(String number) {
  final digits = number.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('4')) return 'Visa';
  if (RegExp(r'^5[1-5]').hasMatch(digits)) return 'Mastercard';
  if (RegExp(r'^3[47]').hasMatch(digits)) return 'Amex';
  if (RegExp(r'^6(?:011|5)').hasMatch(digits)) return 'Discover';
  return 'Card';
}

/// Bottom sheet form for adding a (dummy) [PaymentMethodModel].
///
/// Never stores full card numbers — only brand, last 4, holder and expiry.
class PaymentFormSheet extends StatefulWidget {
  const PaymentFormSheet({super.key, this.makeDefaultFirst = false});

  final bool makeDefaultFirst;

  static Future<PaymentMethodModel?> show(
    BuildContext context, {
    bool makeDefaultFirst = false,
  }) {
    return showModalBottomSheet<PaymentMethodModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaymentFormSheet(makeDefaultFirst: makeDefaultFirst),
    );
  }

  @override
  State<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends State<PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _isDefault = widget.makeDefaultFirst;
  }

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final method = PaymentMethodModel(
      id: const Uuid().v4(),
      type: detectCardBrand(_number.text),
      last4: Formatters.last4(_number.text),
      holderName: _holder.text.trim(),
      expiry: _expiry.text.trim(),
      isDefault: _isDefault,
    );
    Navigator.of(context).pop(method);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                'Add Payment Method',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              Gaps.xs,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  Gaps.hXs,
                  Text(
                    'Demo only — no real card data is stored',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Gaps.lg,
              _label('Card number'),
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                validator: Validators.cardNumber,
                decoration: const InputDecoration(
                  hintText: '4242 4242 4242 4242',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
              ),
              Gaps.md,
              _label('Cardholder name'),
              TextFormField(
                controller: _holder,
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required(v, label: 'Cardholder'),
                decoration: const InputDecoration(
                  hintText: 'Jane Doe',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              Gaps.md,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Expiry (MM/YY)'),
                        TextFormField(
                          controller: _expiry,
                          keyboardType: TextInputType.datetime,
                          validator: Validators.cardExpiry,
                          decoration: const InputDecoration(hintText: '12/28'),
                        ),
                      ],
                    ),
                  ),
                  Gaps.hSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('CVV'),
                        TextFormField(
                          controller: _cvv,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          validator: Validators.cardCvv,
                          decoration: const InputDecoration(hintText: '123'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Gaps.sm,
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default payment method'),
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
                      child: const Text('Add Card'),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.xs),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}
