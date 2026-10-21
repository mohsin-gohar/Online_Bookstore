import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../data/mock/mock_transport.dart';
import '../../logic/auth_provider.dart';
import '../common_widgets/app_logo.dart';
import '../common_widgets/custom_button.dart';
import '../common_widgets/custom_textfield.dart';

/// Email/password login screen with Google sign-in and a forgot-password link.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Validates, calls the provider, and routes on success.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (ok) {
      SnackbarHelper.showSuccess(context, AppStrings.welcomeBackToast);
      if (!mounted) return;
      context.goAfterAuth(isAdmin: auth.isAdmin);
    } else {
      SnackbarHelper.showError(
        context,
        auth.errorMessage ?? AppStrings.somethingWentWrong,
      );
    }
  }

  /// Runs the Google flow; routes on success, ignores a user cancel.
  Future<void> _googleSignIn() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    if (!mounted) return;

    if (ok) {
      SnackbarHelper.showSuccess(context, 'Signed in with Google');
      context.goAfterAuth(isAdmin: auth.isAdmin);
    } else if (auth.errorMessage != null) {
      SnackbarHelper.showError(context, auth.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the provider's busy/error state changes.
    final isBusy = context.watch<AuthProvider>().isBusy;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxContentWidth,
              ),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppLogo(showTagline: true),
                      Gaps.xxl,

                      Text(
                        AppStrings.welcomeBack,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Gaps.xxs,
                      Text(
                        AppStrings.loginSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Gaps.xl,

                      // ── Email ──
                      CustomTextField(
                        controller: _emailController,
                        label: AppStrings.email,
                        hint: 'you@example.com',
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      Gaps.md,

                      // ── Password ──
                      CustomTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        label: AppStrings.password,
                        hint: '••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: Validators.password,
                        onSubmitted: (_) => _submit(),
                      ),

                      // ── Forgot password ──
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isBusy
                              ? null
                              : () =>
                                    context.push(AppRoutes.forgotPasswordPath),
                          child: const Text(AppStrings.forgotPassword),
                        ),
                      ),
                      Gaps.sm,

                      // ── Login ──
                      CustomButton(
                        label: AppStrings.login,
                        isLoading: isBusy,
                        onPressed: _submit,
                      ),
                      Gaps.lg,

                      // ── Divider ──
                      const _OrDivider(),
                      Gaps.lg,

                      // ── Google ──
                      CustomButton(
                        label: AppStrings.continueWithGoogle,
                        variant: CustomButtonVariant.outlined,
                        icon: Icons.g_mobiledata_rounded,
                        onPressed: isBusy ? null : _googleSignIn,
                      ),
                      Gaps.xl,

                      // ── Demo credentials (mock mode only) ──
                      if (ApiConstants.useMockMode) ...[
                        const _DemoAccountHint(),
                        Gaps.lg,
                      ],

                      // ── Register link ──
                      _SwitchAuthPrompt(
                        leading: AppStrings.dontHaveAccount,
                        action: AppStrings.register,
                        onTap: isBusy
                            ? null
                            : () => context.push(AppRoutes.registerPath),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "──────  or continue with  ──────" separator.
///
/// A small card that reveals the seeded demo accounts. It is only shown when
/// the app runs against the bundled mock backend, so a live build never
/// advertises credentials.
class _DemoAccountHint extends StatelessWidget {
  const _DemoAccountHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                'Demo mode — try a seeded account',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Customer  $demoCustomerEmail  ·  $demoCustomerPassword\n'
            'Admin     $demoAdminEmail  ·  $demoAdminPassword',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// "──────  or continue with  ──────" separator.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = Expanded(
      child: Divider(color: scheme.onSurface.withValues(alpha: 0.12)),
    );
    return Row(
      children: [
        divider,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          child: Text(
            AppStrings.orContinueWith,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        divider,
      ],
    );
  }
}

/// "Don't have an account?  Register" prompt.
class _SwitchAuthPrompt extends StatelessWidget {
  const _SwitchAuthPrompt({
    required this.leading,
    required this.action,
    required this.onTap,
  });

  final String leading;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(leading, style: theme.textTheme.bodyMedium),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
