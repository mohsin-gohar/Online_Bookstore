import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_status.dart';
import '../../logic/order_provider.dart';
import '../common_widgets/custom_appbar.dart';
import '../common_widgets/empty_state.dart';
import '../orders/widgets/order_status_chip.dart';

/// Admin: view all orders and advance their status through the pipeline.
class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  OrderStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OrderProvider>().loadAdminOrders(),
    );
  }

  Future<void> _setFilter(OrderStatus? status) async {
    setState(() => _filter = status);
    await context.read<OrderProvider>().loadAdminOrders(status: status);
  }

  /// Advances [order] to [next], asking for an optional note.
  Future<void> _changeStatus(OrderModel order, OrderStatus next) async {
    String note = '';
    if (next == OrderStatus.cancelled) {
      final reason = await _askNote(context, 'Cancellation reason');
      if (reason == null) return;
      note = reason;
    } else {
      note = 'Marked ${next.label.toLowerCase()} by admin';
    }
    if (!mounted) return;

    final ok = await context.read<OrderProvider>().updateOrderStatus(
      order.id,
      next,
      note: note,
    );
    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Order marked ${next.label}');
    } else {
      SnackbarHelper.showError(context, 'Could not update the order.');
    }
  }

  Future<String?> _askNote(BuildContext context, String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Optional note…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    ).then((value) {
      controller.dispose();
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final list = orders.adminOrders;

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.manageOrders,
        showCart: false,
        showHome: false,
        fallbackRoute: AppRoutes.adminDashboardPath,
      ),
      body: Column(
        children: [
          // ── Status filter chips ──
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.xs),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) => _setFilter(null),
                  ),
                ),
                ...OrderStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: AppSizes.xs),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: _filter == s,
                      onSelected: (_) => _setFilter(s),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.isLoadingAdminOrders && list.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders',
                    message: 'Orders will appear here as they come in.',
                  )
                : RefreshIndicator(
                    onRefresh: () => context
                        .read<OrderProvider>()
                        .loadAdminOrders(status: _filter),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.md),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Gaps.sm,
                      itemBuilder: (context, i) => _OrderAdminCard(
                        order: list[i],
                        onChangeStatus: _changeStatus,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderAdminCard extends StatelessWidget {
  const _OrderAdminCard({required this.order, required this.onChangeStatus});

  final OrderModel order;
  final Future<void> Function(OrderModel, OrderStatus) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Compute which next-status actions are allowed.
    final nextOptions = OrderStatus.values
        .where((s) => order.status.canTransitionTo(s))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.orderNumber(order.id),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(order.userName, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                OrderStatusChip(status: order.status),
              ],
            ),
            const Divider(height: AppSizes.lg),
            Row(
              children: [
                Text(
                  Formatters.itemCount(order.itemCount),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  Formatters.price(order.total),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (nextOptions.isNotEmpty) ...[
              Gaps.sm,
              Wrap(
                spacing: AppSizes.xs,
                runSpacing: AppSizes.xs,
                children: nextOptions
                    .map(
                      (next) => ActionChip(
                        avatar: Icon(next.icon, size: 16, color: next.color),
                        label: Text('Mark ${next.label}'),
                        onPressed: () => onChangeStatus(order, next),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
