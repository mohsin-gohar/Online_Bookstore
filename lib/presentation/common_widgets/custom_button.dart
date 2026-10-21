import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'loading_indicator.dart';

/// Visual variants for [CustomButton].
enum CustomButtonVariant { primary, outlined, text }

/// A versatile button with a built-in loading state.
///
/// While [isLoading] is true the button shows a spinner, is disabled, and stops
/// accepting taps — preventing double submissions on auth/checkout forms.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = CustomButtonVariant.primary,
    this.expand = true,
    this.height = AppSizes.buttonHeight,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final CustomButtonVariant variant;

  /// When true (default) the button stretches to its parent's width.
  final bool expand;

  final double height;
  final Color? foregroundColor;

  bool get _disabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);
    final VoidCallback? callback = _disabled ? null : onPressed;

    Widget button;
    switch (variant) {
      case CustomButtonVariant.primary:
        button = ElevatedButton(
          onPressed: callback,
          style: foregroundColor == null
              ? null
              : ElevatedButton.styleFrom(
                  backgroundColor: foregroundColor,
                  foregroundColor: Colors.white,
                ),
          child: child,
        );
      case CustomButtonVariant.outlined:
        button = OutlinedButton(onPressed: callback, child: child);
      case CustomButtonVariant.text:
        button = TextButton(onPressed: callback, child: child);
    }

    final sized = SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: button,
    );
    return sized;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return LoadingIndicator(
        size: 20,
        color: variant == CustomButtonVariant.primary
            ? Colors.white
            : Theme.of(context).colorScheme.primary,
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: AppSizes.iconSm),
        Gaps.hXs,
        Text(label),
      ],
    );
  }
}
