import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';
import '../../logic/order_provider.dart';
import '../common_widgets/custom_appbar.dart';
import '../common_widgets/error_state.dart';
import 'widgets/order_status_chip.dart';
import 'widgets/order_timeline.dart';

/// Live order tracking: a progress header + status timeline.
///
/// Subscribes to the order document so status changes appear in real time.
class TrackOrderScreen extends StatelessWidget {
  const TrackOrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final orders = context.read<OrderProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.trackOrder),
      body: StreamBuilder<OrderModel?>(
        stream: orders.watchOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(message: snapshot.error.toString());
          }
          final order = snapshot.data;
          if (order == null) {
            return const ErrorState(message: 'This order could not be found.');
          }
          return _TrackBody(order: order);
        },
      ),
    );
  }
}

class _TrackBody extends StatelessWidget {
  const _TrackBody({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.md),
      children: [
        // ── Header ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Formatters.orderNumber(order.id),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    OrderStatusChip(status: order.status),
                  ],
                ),
                if (order.deliveryDate != null && !order.isCancelled) ...[
                  Gaps.sm,
                  Row(
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      Gaps.hXs,
                      Text(
                        'Expected by ${Formatters.date(order.deliveryDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                Gaps.md,

                // Linear progress bar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  child: LinearProgressIndicator(
                    value: order.isCancelled ? 1 : order.progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      order.isCancelled ? AppColors.danger : AppColors.brand,
                    ),
                  ),
                ),
                Gaps.sm,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Placed', style: theme.textTheme.bodySmall),
                    Text('Delivered', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
        Gaps.lg,

        // ── Timeline ──
        Text(
          'Order Timeline',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Gaps.md,
        OrderTimeline(currentStatus: order.status, events: order.timeline),
        Gaps.lg,

        // ── Delivery summary ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery to',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.xs,
                Text(order.address, style: theme.textTheme.bodyMedium),
                Gaps.md,
                Text(
                  'Payment',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gaps.xs,
                Text(order.paymentMethod, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        Gaps.xxl,
      ],
    );
  }
}
