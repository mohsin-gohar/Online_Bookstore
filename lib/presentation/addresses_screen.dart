import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/address_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/profile_provider.dart';
import 'checkout/widgets/address_form_sheet.dart';
import 'common_widgets/custom_appbar.dart';
import 'common_widgets/empty_state.dart';

/// Manage saved shipping addresses: add, edit, delete, set default.
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final address = await AddressFormSheet.show(
      context,
      makeDefaultFirst: profile.addresses.isEmpty,
    );
    if (address == null || !context.mounted) return;
    final ok = await profile.saveAddress(auth.uid!, address);
    if (!context.mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Address saved');
    } else if (profile.error != null) {
      SnackbarHelper.showError(context, profile.error!);
    }
  }

  Future<void> _edit(BuildContext context, AddressModel address) async {
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final updated = await AddressFormSheet.show(context, existing: address);
    if (updated == null || !context.mounted) return;
    final ok = await profile.saveAddress(auth.uid!, updated);
    if (!context.mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Address updated');
    } else if (profile.error != null) {
      SnackbarHelper.showError(context, profile.error!);
    }
  }

  Future<void> _delete(BuildContext context, AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove "${address.label}"?'),
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
    final ok = await profile.deleteAddress(auth.uid!, address.id);
    if (!context.mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Address deleted');
    } else if (profile.error != null) {
      SnackbarHelper.showError(context, profile.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final addresses = profile.addresses;

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.addresses,
        showCart: false,
        fallbackRoute: AppRoutes.profilePath,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: addresses.isEmpty
          ? const EmptyState(
              icon: Icons.location_off_outlined,
              title: 'No addresses yet',
              message: 'Add a shipping address to speed up checkout.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => Gaps.sm,
              itemBuilder: (context, i) {
                final a = addresses[i];
                return _AddressCard(
                  address: a,
                  onEdit: () => _edit(context, a),
                  onDelete: () => _delete(context, a),
                  onSetDefault: () async {
                    final ok = await context
                        .read<ProfileProvider>()
                        .setDefaultAddress(auth.uid!, a.id);
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

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                Gaps.hXs,
                Text(
                  address.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (address.isDefault) ...[
                  Gaps.hXs,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.danger,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
            Gaps.xs,
            Text(address.summary, style: theme.textTheme.bodyMedium),
            if (address.phone.isNotEmpty) ...[
              Gaps.xxs,
              Text(address.phone, style: theme.textTheme.bodySmall),
            ],
            if (!address.isDefault) ...[
              Gaps.xs,
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
          ],
        ),
      ),
    );
  }
}
