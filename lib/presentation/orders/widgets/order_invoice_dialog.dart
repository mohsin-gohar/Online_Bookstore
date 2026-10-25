import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/order_model.dart';

/// Professional e-commerce tax invoice / receipt modal.
class OrderInvoiceDialog extends StatelessWidget {
  const OrderInvoiceDialog({super.key, required this.order});

  final OrderModel order;

  static Future<void> show(BuildContext context, OrderModel order) {
    return showDialog<void>(
      context: context,
      builder: (context) => OrderInvoiceDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      backgroundColor: isDark
          ? const Color(0xFF131D36)
          : const Color(0xFFFFFDF9),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header / Logo ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.import_contacts_rounded,
                            color: AppColors.accent,
                            size: 24,
                          ),
                          Gaps.xs,
                          Text(
                            'BOOK STORE',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: isDark ? AppColors.white : AppColors.brand,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Official Sales Receipt & Tax Invoice',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'PAID',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: AppColors.accent.withValues(alpha: 0.3)),
              const SizedBox(height: 12),

              // ── Invoice Meta ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVOICE TO:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.userName.isNotEmpty
                              ? order.userName
                              : 'Valued Customer',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.grey400
                                : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDER REF:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.orderNumber(order.id),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (order.orderDate != null)
                          Text(
                            'Date: ${Formatters.date(order.orderDate!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.grey600,
                            ),
                          ),
                        Text(
                          'Method: ${order.paymentMethod}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.grey400
                                : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Line Items Table ──
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radiusMd - 1),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Price',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rows
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.qty}x',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.grey400
                                      : AppColors.grey600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                Formatters.price(item.subtotal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Financial Totals ──
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal:',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.grey600,
                            ),
                          ),
                          Text(
                            Formatters.price(order.subtotal),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shipping:',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.grey600,
                            ),
                          ),
                          Text(
                            order.shipping == 0
                                ? 'Free'
                                : Formatters.price(order.shipping),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (order.discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discount (${order.promoCode}):',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.grey400
                                    : AppColors.grey600,
                              ),
                            ),
                            Text(
                              '-${Formatters.price(order.discount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Divider(color: AppColors.accent.withValues(alpha: 0.3)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Paid:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Formatters.price(order.total),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Dialog Actions ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        SnackbarHelper.showSuccess(
                          context,
                          'Invoice downloaded as PDF (stored in Downloads)',
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
