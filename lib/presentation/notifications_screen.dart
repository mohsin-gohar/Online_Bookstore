import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/notification_model.dart';
import '../../logic/auth_provider.dart';
import '../../logic/notification_provider.dart';
import 'common_widgets/custom_appbar.dart';
import 'common_widgets/empty_state.dart';

/// Screen listing the user's in-app notifications.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().uid;
      if (uid != null) context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: AppStrings.notifications,
          showCart: false,
        ),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Log in to see notifications',
          message: 'Order updates and offers will appear here.',
          actionLabel: AppStrings.login,
          onAction: () => context.go(AppRoutes.loginPath),
        ),
      );
    }

    final items = notifications.items;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.notifications,
        showCart: false,
        actions: [
          if (notifications.hasUnread)
            TextButton(
              onPressed: notifications.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              message: 'You\'re all caught up!',
            )
          : RefreshIndicator(
              onRefresh: notifications.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.md),
                itemCount: items.length,
                separatorBuilder: (_, _) => Gaps.sm,
                itemBuilder: (context, i) => _NotificationTile(
                  notification: items[i],
                  onTap: () => _open(items[i]),
                  onDelete: () => notifications.delete(items[i]),
                ),
              ),
            ),
    );
  }

  void _open(NotificationModel notification) {
    context.read<NotificationProvider>().markRead(notification);
    if (notification.orderId.isNotEmpty) {
      context.push(AppRoutes.orderDetails(notification.orderId));
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  IconData get _icon {
    switch (notification.type) {
      case 'order':
        return Icons.local_shipping_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'account':
        return Icons.person_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = !notification.read;

    return Card(
      color: unread ? scheme.primary.withValues(alpha: 0.06) : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 20, color: scheme.primary),
              ),
              Gaps.hSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    Gaps.xxs,
                    Text(
                      notification.message,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (notification.createdAt != null) ...[
                      Gaps.xxs,
                      Text(
                        Formatters.relativeDate(notification.createdAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
