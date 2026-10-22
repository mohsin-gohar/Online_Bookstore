import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';

/// Shown after a successful checkout.
///
/// Receives the created [OrderModel] via `extra`. Offers "Track Order" and
/// "Continue shopping".
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, this.order});

  final OrderModel? order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Home',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.homePath),
        ),
        title: const Text('Order Confirmed'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - AppSizes.xl * 2).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: AppSizes.sm),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success check mark.
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.6, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Container(
                          height: 104,
                          width: 104,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 64,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      Gaps.lg,
                      Text(
                        AppStrings.orderSuccess,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Gaps.xs,
                      Text(
                        'Thank you for your purchase. We\'ll email you updates as your '
                        'order progresses.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (order != null) ...[
                        Gaps.lg,
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              children: [
                                _row(
                                  theme,
                                  AppStrings.orderId,
                                  Formatters.orderNumber(order!.id),
                                ),
                                Gaps.xs,
                                _row(
                                  theme,
                                  AppStrings.total,
                                  Formatters.price(order!.total),
                                ),
                                if (order!.deliveryDate != null) ...[
                                  Gaps.xs,
                                  _row(
                                    theme,
                                    AppStrings.deliveryDate,
                                    Formatters.date(order!.deliveryDate!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (order != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push(
                                AppRoutes.orderDetails(order!.id),
                              ),
                              icon: const Icon(Icons.local_shipping_outlined),
                              label: const Text(AppStrings.trackOrder),
                            ),
                          ),
                          Gaps.sm,
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(AppRoutes.ordersPath),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text(AppStrings.orders),
                          ),
                        ),
                        Gaps.sm,
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go(AppRoutes.homePath),
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Continue Shopping'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
