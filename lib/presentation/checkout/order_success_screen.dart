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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            children: [
              const Spacer(),
              // Success check mark.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: AppColors.success,
                  ),
                ),
              ),
              Gaps.xl,
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
                Gaps.xl,
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
              const Spacer(),
              if (order != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.pushReplacement(
                      AppRoutes.orderDetails(order!.id),
                    ),
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text(AppStrings.trackOrder),
                  ),
                ),
              Gaps.sm,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.homePath),
                  child: const Text('Continue Shopping'),
                ),
              ),
            ],
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
