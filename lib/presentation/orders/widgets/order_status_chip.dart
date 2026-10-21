import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../data/models/order_status.dart';

/// A coloured pill showing an [OrderStatus].
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status, this.dense = false});

  final OrderStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: dense ? 12 : 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
