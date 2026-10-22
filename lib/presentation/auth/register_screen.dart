import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../logic/auth_provider.dart';
import '../common_widgets/app_logo.dart';
import '../common_widgets/custom_button.dart';
import '../common_widgets/custom_textfield.dart';

/// Email/password registration screen.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _acceptedTerms = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formValid = _formKey.currentState?.validate() ?? false;
    final termsValid = _acceptedTerms;
    if (!termsValid) {
      setState(() => _showTermsError = true);
    } else {
      setState(() => _showTermsError = false);
    }
    if (!formValid || !termsValid) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
    );
    if (!mounted) return;

    if (ok) {
      SnackbarHelper.showSuccess(context, AppStrings.accountCreated);
      if (!mounted) return;
      context.goAfterAuth(isAdmin: auth.isAdmin);
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
              vertical: AppSizes.sm,
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
                      const Center(
                        child: AppLogo(size: 60, showWordmark: false),
                      ),
                      Gaps.lg,

                      Text(
                        AppStrings.createAccount,
                        style: theme.textTheme.headlineSmall,
                      ),
                      Gaps.xxs,
                      Text(
                        AppStrings.registerSubtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Gaps.xl,

                      // ── Name ──
                      CustomTextField(
                        controller: _nameController,
                        label: AppStrings.fullName,
                        hint: 'Jane Doe',
                        prefixIcon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: Validators.name,
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                      ),
                      Gaps.md,

                      // ── Email ──
                      CustomTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        label: AppStrings.email,
                        hint: 'you@example.com',
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                        onSubmitted: (_) => _phoneFocus.requestFocus(),
                      ),
                      Gaps.md,

                      // ── Phone (optional) ──
                      CustomTextField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        label: '${AppStrings.phone} (optional)',
                        hint: '+1 555 010 1234',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: (v) => Validators.phone(v),
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      Gaps.md,

                      // ── Password ──
                      CustomTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        label: AppStrings.password,
                        hint: 'At least 6 characters',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: Validators.password,
                        onSubmitted: (_) => _confirmFocus.requestFocus(),
                      ),
                      Gaps.md,

                      // ── Confirm password ──
                      CustomTextField(
                        controller: _confirmController,
                        focusNode: _confirmFocus,
                        label: AppStrings.confirmPassword,
                        hint: 'Re-enter your password',
                        prefixIcon: Icons.lock_reset_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (v) => Validators.confirmPassword(
                          v,
                          _passwordController.text,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      Gaps.sm,

                      // ── Terms ──
                      _TermsCheckbox(
                        value: _acceptedTerms,
                        hasError: _showTermsError,
                        onChanged: (v) => setState(() {
                          _acceptedTerms = v;
                          if (v) _showTermsError = false;
                        }),
                      ),
                      Gaps.lg,

                      // ── Sign up ──
                      CustomButton(
                        label: AppStrings.signUp,
                        isLoading: isBusy,
                        onPressed: _submit,
                      ),
                      Gaps.lg,

                      // ── Login link ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.alreadyHaveAccount,
                            style: theme.textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: isBusy ? null : () => context.pop(),
                            child: Text(
                              AppStrings.login,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Gaps.lg,
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

/// "I agree to the Terms & Privacy Policy" checkbox with an error state.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  final bool value;
  final bool hasError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(!value),
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: theme.textTheme.bodySmall,
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.sm,
              top: AppSizes.xxs,
            ),
            child: Text(
              'Please accept the terms to continue',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
      ],
    );
  }
}
