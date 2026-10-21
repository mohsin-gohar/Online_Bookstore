import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/app_exceptions.dart';
import '../common_widgets/empty_state.dart';
import '../common_widgets/error_state.dart';

/// Admin: view all users and block/unblock abusive accounts.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<UserModel> _users = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await context.read<UserRepository>().getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AppException ? e.message : 'Something went wrong';
        _loading = false;
      });
    }
  }

  Future<void> _toggleBlock(UserModel user) async {
    final blocking = !user.isBlockedAccount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(blocking ? 'Block user?' : 'Unblock user?'),
        content: Text(
          blocking
              ? '${user.name} will be signed out and unable to log in.'
              : '${user.name} will be able to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(blocking ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<UserRepository>().setBlocked(user.uid, blocking);
      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        blocking ? 'User blocked' : 'User unblocked',
      );
      _load();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          e is AppException ? e.message : 'Something went wrong',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.manageUsers)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _users.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No users',
              message: 'Registered users will appear here.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.md),
                itemCount: _users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) =>
                    _UserRow(user: _users[i], onToggleBlock: _toggleBlock),
              ),
            ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onToggleBlock});

  final UserModel user;
  final ValueChanged<UserModel> onToggleBlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primary.withValues(alpha: 0.15),
            backgroundImage: user.photoUrl.isNotEmpty
                ? CachedNetworkImageProvider(user.photoUrl)
                : null,
            child: user.photoUrl.isEmpty
                ? Text(
                    user.initial,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          Gaps.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (user.isAdmin) ...[
                      Gaps.hXs,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusPill,
                          ),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                    if (user.isBlockedAccount) ...[
                      Gaps.hXs,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusPill,
                          ),
                        ),
                        child: const Text(
                          'BLOCKED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                if (user.createdAt != null)
                  Text(
                    'Joined ${Formatters.date(user.createdAt!)}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          // Don't allow blocking admins from here.
          if (!user.isAdmin)
            IconButton(
              tooltip: user.isBlockedAccount ? 'Unblock' : 'Block',
              icon: Icon(
                user.isBlockedAccount
                    ? Icons.lock_open_rounded
                    : Icons.block_rounded,
                color: user.isBlockedAccount
                    ? AppColors.success
                    : AppColors.danger,
              ),
              onPressed: () => onToggleBlock(user),
            ),
        ],
      ),
    );
  }
}
