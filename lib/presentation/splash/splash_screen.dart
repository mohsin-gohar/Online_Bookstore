import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_navigation.dart';
import '../../logic/auth_provider.dart';
import '../common_widgets/brand_mark.dart';

/// First screen shown on launch.
///
/// Responsibilities:
///  1. Show the brand mark while the app warms up.
///  2. Decide where to send the user:
///       - first launch  → Onboarding
///       - otherwise     → Login
///
/// The router reacts to [AuthProvider] changes, so this screen only has to
/// make sure the session has been resolved before it hands over.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Waits for the intro animation plus a short brand pause, then routes.
  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    final minimumSplash = Future<void>.delayed(
      const Duration(milliseconds: 1800),
    );

    await Future.wait([auth.bootstrap(), minimumSplash]);
    if (!mounted) return;

    // Reactive router fallback: manually push if it stalls
    context.goAfterAuth(isAdmin: auth.isAdmin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.brandGradient,
          ),
        ),
        child: Stack(
          children: [
            // Soft "reading lamp" glow behind the mark.
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      AppColors.accentLight.withValues(alpha: 0.22),
                      AppColors.accentLight.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand mark.
                      BrandMark(size: 112, onDark: true),
                      const SizedBox(height: 24),

                      Text(
                        AppStrings.appName,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const BrassRule(width: 54),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.appTagline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 36),
                      const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accentLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
