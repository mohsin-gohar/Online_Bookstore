import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../logic/auth_provider.dart';
import '../../logic/profile_provider.dart';
import 'common_widgets/custom_appbar.dart';
import 'common_widgets/custom_textfield.dart';

/// Edit the user's basic profile (name, phone). Email is read-only.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final uid = auth.uid;
    if (uid == null) return;

    final ok = await profile.updateBasicProfile(
      uid: uid,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      // Reflect the change in AuthProvider too so the whole app updates.
      final updated = auth.user?.copyWith(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      if (updated != null) auth.updateLocalUser(updated);
      SnackbarHelper.showSuccess(context, 'Profile updated');
      context.pop();
    } else if (profile.error != null) {
      SnackbarHelper.showError(context, profile.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ProfileProvider>().isSaving;

    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.editProfile,
        showCart: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _name,
                label: AppStrings.fullName,
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: Validators.name,
              ),
              Gaps.md,
              CustomTextField(
                controller: _phone,
                label: AppStrings.phone,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => Validators.phone(v),
              ),
              Gaps.md,
              // Email is not editable here (tied to the auth account).
              CustomTextField(
                controller: _email,
                label: AppStrings.email,
                prefixIcon: Icons.alternate_email_rounded,
                enabled: false,
              ),
              Gaps.xl,
              ElevatedButton(
                onPressed: saving ? null : _save,
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(AppStrings.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
