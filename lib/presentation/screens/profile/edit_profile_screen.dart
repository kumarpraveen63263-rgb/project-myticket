import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validator_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController =
        TextEditingController(text: '+91 ${user?.phone ?? ''}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .updateProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );
    context.showSnack('Profile updated');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.tr('Edit Profile')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.accentMovie.withValues(alpha: 0.16),
                child: Text(
                  (user?.name ?? 'Guest').initials,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.accentMovie,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            AppTextField(
              controller: _nameController,
              labelText: 'Full Name',
              prefixIcon: Icons.person_outline_rounded,
              validator: ValidatorUtils.validateName,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            AppTextField(
              labelText: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              enabled: false,
              controller: _phoneController,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            AppTextField(
              controller: _emailController,
              labelText: 'Email (optional)',
              prefixIcon: Icons.mail_outline_rounded,
              validator: ValidatorUtils.validateEmail,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            AppButton(label: 'Save Changes', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
