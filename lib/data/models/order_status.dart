import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// The lifecycle of an order: Pending -> Confirmed -> Shipped -> Delivered,
/// or Cancelled at any point before delivery.
enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled;

  /// Parses a stored string, defaulting to [pending].
  static OrderStatus fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get value => name;

  /// Human-readable label.
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Colour used for status chips on order cards.
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.shipped:
        return AppColors.statusShipped;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  /// Icon used alongside the status.
  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.confirmed:
        return Icons.verified_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatus.delivered:
        return Icons.inventory_2_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  /// The happy-path sequence used by the tracking timeline.
  static const List<OrderStatus> timeline = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  /// Index within [timeline] (cancelled returns -1).
  int get timelineIndex => timeline.indexOf(this);

  /// True when the order can no longer change (delivered/cancelled).
  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  /// Whether the order may move from this status to [next].
  ///
  /// Enforces the forward-only flow and allows cancellation while an order is
  /// still pending/confirmed/shipped.
  bool canTransitionTo(OrderStatus next) {
    if (isTerminal) return false;
    switch (this) {
      case OrderStatus.pending:
        return next == OrderStatus.confirmed || next == OrderStatus.cancelled;
      case OrderStatus.confirmed:
        return next == OrderStatus.shipped || next == OrderStatus.cancelled;
      case OrderStatus.shipped:
        return next == OrderStatus.delivered || next == OrderStatus.cancelled;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return false;
    }
  }
}
