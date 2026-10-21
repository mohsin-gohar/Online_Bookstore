import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// A compact −/qty/+ stepper used on the book details bar and cart rows.
///
/// Clamps between [min] and [max]; disables the relevant button at the bounds.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.qty,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.compact = false,
  });

  final int qty;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// Smaller sizing for dense cart rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = compact ? 28.0 : 36.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(
            icon: Icons.remove_rounded,
            size: size,
            enabled: qty > min,
            onTap: () => onChanged(qty - 1),
          ),
          SizedBox(
            width: compact ? 26 : 34,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _Btn(
            icon: Icons.add_rounded,
            size: size,
            enabled: qty < max,
            onTap: () => onChanged(qty + 1),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
