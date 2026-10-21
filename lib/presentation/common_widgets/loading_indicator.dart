import 'package:flutter/material.dart';

/// A small, centred progress spinner.
///
/// Kept lightweight (no dependency on Lottie) so it can be used inside buttons
/// and dialogs where a full-screen animation would be inappropriate.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 28,
    this.color,
    this.strokeWidth = 2.6,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Full-screen loading overlay used on screens that fetch data before showing
/// content.
class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingIndicator(size: 40),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
