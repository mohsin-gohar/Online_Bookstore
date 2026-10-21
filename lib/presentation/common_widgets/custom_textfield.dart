import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_sizes.dart';

/// A styled, reusable text field.
///
/// Wraps [TextFormField] so every input in the app shares the same look:
/// rounded, filled, with an optional leading icon and a password show/hide
/// toggle. Validation is injected via [validator].
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    this.maxLines = 1,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;

  /// Optional custom trailing widget. When null and [obscureText] is true, a
  /// show/hide password toggle is shown instead.
  final Widget? suffix;

  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        Gaps.xs,
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: AppSizes.iconMd),
            suffixIcon: _buildSuffix(),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix() {
    if (widget.suffix != null) return widget.suffix;
    if (!widget.obscureText) return null;
    return IconButton(
      tooltip: _obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        _obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: AppSizes.iconMd,
      ),
      onPressed: () => setState(() => _obscured = !_obscured),
    );
  }
}
