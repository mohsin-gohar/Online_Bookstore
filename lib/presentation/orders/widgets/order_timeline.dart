import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_status.dart';
import '../../../data/models/order_status_event.dart';

/// A vertical timeline of an order's status events.
///
/// Falls back to the canonical happy-path sequence (from [OrderStatus.timeline])
/// when the order has no recorded events, marking reached steps as complete.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({
    super.key,
    required this.currentStatus,
    this.events = const [],
  });

  final OrderStatus currentStatus;
  final List<OrderStatusEvent> events;

  @override
  Widget build(BuildContext context) {
    // Build the row list: either recorded events or the canonical steps.
    final steps = events.isNotEmpty ? _fromEvents() : _fromCanonical();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }

  /// Builds steps from recorded events, marking the latest one as current.
  List<_Step> _fromEvents() {
    return events.map((e) {
      final status = OrderStatus.fromString(e.status);
      return _Step(status: status, reached: true, date: e.at, note: e.note);
    }).toList();
  }

  /// Builds the canonical happy-path steps up to and including [currentStatus].
  List<_Step> _fromCanonical() {
    if (currentStatus == OrderStatus.cancelled) {
      return [
        const _Step(status: OrderStatus.pending, reached: true),
        _Step(
          status: OrderStatus.cancelled,
          reached: true,
          note: 'Order cancelled',
        ),
      ];
    }
    final currentIndex = currentStatus.timelineIndex;
    return OrderStatus.timeline
        .map(
          (s) => _Step(
            status: s,
            reached: s.timelineIndex <= currentIndex,
            isCurrent: s == currentStatus,
          ),
        )
        .toList();
  }
}

class _Step {
  const _Step({
    required this.status,
    required this.reached,
    this.date,
    this.note = '',
    this.isCurrent = false,
  });

  final OrderStatus status;
  final bool reached;
  final DateTime? date;
  final String note;
  final bool isCurrent;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _Step step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = step.reached
        ? step.status.color
        : scheme.onSurface.withValues(alpha: 0.25);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + connector line.
          Column(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.reached
                      ? color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  step.reached ? Icons.check_rounded : step.status.icon,
                  size: 15,
                  color: color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: step.reached ? 0.6 : 0.25),
                  ),
                ),
            ],
          ),
          Gaps.hSm,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.lg, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.status.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: step.isCurrent
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: step.reached
                          ? null
                          : scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  if (step.date != null)
                    Text(
                      Formatters.dateTime(step.date!),
                      style: theme.textTheme.bodySmall,
                    ),
                  if (step.note.isNotEmpty)
                    Text(
                      step.note,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
