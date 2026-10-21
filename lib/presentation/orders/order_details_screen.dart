import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../../logic/order_provider.dart';
import '../common_widgets/custom_appbar.dart';
import '../common_widgets/error_state.dart';
import 'widgets/order_invoice_dialog.dart';
import 'widgets/order_status_chip.dart';

/// Detailed view of a single order, with a cancel action while it's active.
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderModel? _order;
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
    final order = await context.read<OrderProvider>().getOrder(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
      if (order == null) _error = 'This order could not be found.';
    });
  }

  Future<void> _cancel() async {
    final order = _order;
    if (order == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text(
          'This cannot be undone. The order will be marked as cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<OrderProvider>().cancelOrder(order.id);
    if (!mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Order cancelled');
      _load();
    } else {
      SnackbarHelper.showError(context, 'Could not cancel the order.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: const CustomAppBar(title: AppStrings.orderDetails),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final order = _order;
    if (_error != null || order == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: AppStrings.orderDetails),
        body: ErrorState(message: _error ?? 'Not found', onRetry: _load),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.orderDetails),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // ── Status ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.orderNumber(order.id),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Gaps.xxs,
                        if (order.orderDate != null)
                          Text(
                            'Placed ${Formatters.dateTime(order.orderDate!)}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
            ),
          ),
          Gaps.lg,

          // ── Items ──
          Text(
            'Items',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Gaps.xs,
          Card(
            child: Column(
              children: [
                for (var i = 0; i < order.items.length; i++) ...[
                  _OrderItemRow(item: order.items[i]),
                  if (i != order.items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          Gaps.lg,

          // ── Shipping + payment ──
          Text(
            'Delivery & Payment',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Gaps.xs,
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Shipping address'),
                  subtitle: Text(order.address),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.credit_card_rounded),
                  title: const Text('Payment method'),
                  subtitle: Text(order.paymentMethod),
                ),
                if (order.deliveryDate != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text(AppStrings.deliveryDate),
                    subtitle: Text(Formatters.date(order.deliveryDate!)),
                  ),
                ],
              ],
            ),
          ),
          Gaps.lg,

          // ── Summary ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  _row(
                    theme,
                    AppStrings.subtotal,
                    Formatters.price(order.subtotal),
                  ),
                  Gaps.xs,
                  _row(
                    theme,
                    AppStrings.shipping,
                    order.shipping == 0
                        ? 'Free'
                        : Formatters.price(order.shipping),
                  ),
                  const Divider(height: AppSizes.lg),
                  _row(
                    theme,
                    AppStrings.total,
                    Formatters.price(order.total),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          Gaps.xl,

          // ── Actions ──
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.trackOrder(order.id)),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text(AppStrings.trackOrder),
          ),
          Gaps.sm,
          OutlinedButton.icon(
            onPressed: () => OrderInvoiceDialog.show(context, order),
            icon: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.accent,
            ),
            label: const Text(
              'View Invoice / Receipt',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
            ),
          ),
          if (order.isActive) ...[
            Gaps.sm,
            OutlinedButton.icon(
              onPressed: _cancel,
              icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
              label: const Text(
                'Cancel Order',
                style: TextStyle(color: AppColors.danger),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ],
          Gaps.xxl,
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    final style = bold
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style?.copyWith(
            fontWeight: FontWeight.w700,
            color: bold ? AppColors.brand : null,
          ),
        ),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: SizedBox(
              width: 44,
              height: 64,
              child: item.coverImage.isEmpty
                  ? Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: scheme.onSurface.withValues(alpha: 0.3),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.coverImage,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: scheme.surfaceContainerHighest),
                      errorWidget: (_, _, _) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_rounded),
                      ),
                    ),
            ),
          ),
          Gaps.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${Formatters.price(item.price)} × ${item.qty}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            Formatters.price(item.lineTotal),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
