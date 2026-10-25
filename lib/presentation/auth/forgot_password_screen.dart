import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../logic/auth_provider.dart';
import '../common_widgets/custom_button.dart';
import '../common_widgets/custom_textfield.dart';

/// "Forgot password" screen: collects an email and sends a reset link.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  /// When true, the confirmation view replaces the form.
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(_emailController.text.trim());
    if (!mounted) return;

    if (ok) {
      setState(() => _emailSent = true);
      SnackbarHelper.showSuccess(context, AppStrings.resetSent);
    } else {
      SnackbarHelper.showError(
        context,
        auth.errorMessage ?? AppStrings.somethingWentWrong,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<AuthProvider>().isBusy;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: isBusy
              ? null
              : () => AppNavigator.popOrGo(context, AppRoutes.loginPath),
        ),
      ),
      body: SafeArea(
        top: false,
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
              child: _emailSent
                  ? _buildConfirmation(theme)
                  : _buildForm(theme, isBusy),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form view ─────────────────────────────

  Widget _buildForm(ThemeData theme, bool isBusy) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon badge.
          Center(
            child: Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Gaps.xl,

          Text(
            AppStrings.resetPassword,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          Gaps.xs,
          Text(
            'Enter the email associated with your account and we\'ll send you a '
            'link to reset your password.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          Gaps.xl,

          CustomTextField(
            controller: _emailController,
            label: AppStrings.email,
            hint: 'you@example.com',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
          Gaps.xl,

          CustomButton(
            label: AppStrings.sendResetLink,
            icon: Icons.send_rounded,
            isLoading: isBusy,
            onPressed: _submit,
          ),
          Gaps.md,

          CustomButton(
            label: 'Back to Login',
            variant: CustomButtonVariant.text,
            onPressed: isBusy
                ? null
                : () => AppNavigator.popOrGo(context, AppRoutes.loginPath),
          ),
        ],
      ),
    );
  }

  // ── Confirmation view ─────────────────────

  Widget _buildConfirmation(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 44,
              color: AppColors.success,
            ),
          ),
        ),
        Gaps.xl,
        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        Gaps.xs,
        Text.rich(
          TextSpan(
            text: 'We sent a password reset link to\n',
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(
                text: _emailController.text.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        Gaps.xxl,
        CustomButton(
          label: 'Back to Login',
          onPressed: () => AppNavigator.popOrGo(context, AppRoutes.loginPath),
        ),
        Gaps.md,
        CustomButton(
          label: 'Resend Email',
          variant: CustomButtonVariant.outlined,
          onPressed: () {
            setState(() => _emailSent = false);
            _submit();
          },
        ),
      ],
    );
  }
}
