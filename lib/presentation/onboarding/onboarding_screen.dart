import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/local_storage_service.dart';
import '../common_widgets/brand_mark.dart';

/// A single onboarding slide's content.
class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    icon: Icons.auto_stories_rounded,
    title: AppStrings.onboardingTitle1,
    body: AppStrings.onboardingBody1,
  ),
  _OnboardingPage(
    icon: Icons.search_rounded,
    title: AppStrings.onboardingTitle2,
    body: AppStrings.onboardingBody2,
  ),
  _OnboardingPage(
    icon: Icons.local_shipping_outlined,
    title: AppStrings.onboardingTitle3,
    body: AppStrings.onboardingBody3,
  ),
];

/// Three-slide intro shown only on first launch.
///
/// Persists the "seen" flag so subsequent launches skip straight to login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Marks onboarding complete and navigates to login.
  Future<void> _finish() async {
    await context.read<LocalStorageService>().setOnboardingDone(true);
    if (!mounted) return;
    context.go(AppRoutes.loginPath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar with Skip ─────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xs,
                  vertical: AppSizes.xxs,
                ),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    AppStrings.skip,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),

            // ── Slides ────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _Slide(page: _pages[i]),
              ),
            ),

            // ── Dots ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: i == _index ? 26 : 8,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                ),
              ),
            ),
            Gaps.xl,

            // ── Next / Get Started ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _isLast ? AppStrings.getStarted : AppStrings.next,
                  ),
                ),
              ),
            ),
            Gaps.lg,
          ],
        ),
      ),
    );
  }
}

/// One onboarding slide: an "engraved book plate" holding the illustration,
/// followed by the title and body.
class _Slide extends StatelessWidget {
  const _Slide({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Book plate: cream card, brass hairline, tinted artwork.
          Container(
            height: 232,
            width: 232,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(color: AppColors.accent, width: 1.4),
              boxShadow: AppSizes.softShadow,
            ),
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 116,
                  width: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        scheme.primary.withValues(alpha: 0.18),
                        AppColors.accent.withValues(alpha: 0.20),
                      ],
                    ),
                  ),
                  child: Icon(page.icon, size: 54, color: scheme.primary),
                ),
                Gaps.md,
                const BrassRule(width: 34, height: 2),
              ],
            ),
          ),
          Gaps.xxl,
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          Gaps.sm,
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
