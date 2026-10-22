import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/payment_method_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/profile_provider.dart';
import 'checkout/widgets/payment_form_sheet.dart';
import 'common_widgets/custom_appbar.dart';
import 'common_widgets/empty_state.dart';

/// Manage saved (dummy) payment methods.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final method = await PaymentFormSheet.show(
      context,
      makeDefaultFirst: profile.paymentMethods.isEmpty,
    );
    if (method == null || !context.mounted) return;
    final ok = await profile.savePaymentMethod(auth.uid!, method);
    if (!context.mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Payment method added');
    } else if (profile.error != null) {
      SnackbarHelper.showError(context, profile.error!);
    }
  }

  Future<void> _delete(BuildContext context, PaymentMethodModel method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove card?'),
        content: Text('Remove ${method.type} •••• ${method.last4}?'),
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
    if (confirmed != true || !context.mounted) return;
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final ok = await profile.deletePaymentMethod(auth.uid!, method.id);
    if (!context.mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Payment method removed');
    } else if (profile.error != null) {
      SnackbarHelper.showError(context, profile.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final methods = profile.paymentMethods;

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.paymentMethods,
        showCart: false,
        fallbackRoute: AppRoutes.profilePath,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: methods.isEmpty
          ? const EmptyState(
              icon: Icons.credit_card_off_outlined,
              title: 'No payment methods',
              message: 'Add a card to check out faster next time.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: methods.length,
              separatorBuilder: (_, _) => Gaps.sm,
              itemBuilder: (context, i) {
                final p = methods[i];
                return _PaymentCard(
                  method: p,
                  onDelete: () => _delete(context, p),
                  onSetDefault: () async {
                    final ok = await context
                        .read<ProfileProvider>()
                        .setDefaultPaymentMethod(auth.uid!, p.id);
                    if (!context.mounted) return;
                    if (!ok && profile.error != null) {
                      SnackbarHelper.showError(context, profile.error!);
                    }
                  },
                );
              },
            ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.method,
    required this.onDelete,
    required this.onSetDefault,
  });

  final PaymentMethodModel method;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  IconData get _brandIcon {
    switch (method.type.toLowerCase()) {
      case 'visa':
        return Icons.credit_card_rounded;
      case 'mastercard':
        return Icons.credit_card_rounded;
      case 'amex':
        return Icons.credit_card_rounded;
      default:
        return Icons.credit_card_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 60,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(_brandIcon, color: scheme.primary),
            ),
            Gaps.hSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${method.type} •••• ${method.last4}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (method.isDefault) ...[
                        Gaps.hXs,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusPill,
                            ),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Gaps.xxs,
                  Text(
                    '${method.holderName} · Expires ${method.expiry}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (!method.isDefault)
                    TextButton(
                      onPressed: onSetDefault,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Set as default'),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
