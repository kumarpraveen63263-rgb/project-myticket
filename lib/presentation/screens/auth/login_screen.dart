import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validator_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    final validation = ValidatorUtils.validatePhone(phone);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() => _error = null);
    final ok = await ref.read(authProvider.notifier).sendOtp(phone);
    if (!mounted) return;
    if (ok) {
      context.push('/otp', extra: phone);
    } else {
      context.showSnack('Failed to send OTP. Try again.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentMovie,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              SizedBox(height: AppDimensions.paddingXL),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: AppTypography.displaySmall,
              ),
              SizedBox(height: 8),
              Text(
                'Enter your phone number to continue',
                style: AppTypography.bodyMedium,
              ),
              SizedBox(height: AppDimensions.paddingXL),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: AppDimensions.buttonHeightLarge,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMedium,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text('+91', style: AppTypography.bodyLarge),
                  ),
                  SizedBox(width: AppDimensions.paddingSmall),
                  Expanded(
                    child: AppTextField(
                      controller: _phoneController,
                      hintText: 'Phone number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_rounded,
                      errorText: _error,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                  ),
                ],
              ),
              // Enforce 10 digit numeric input.
              SizedBox(height: AppDimensions.paddingLarge),
              AppButton(
                label: context.tr('Send OTP'),
                isLoading: isLoading,
                onPressed: _sendOtp,
                size: AppButtonSize.large,
              ),
              SizedBox(height: AppDimensions.paddingXL),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: AppTypography.caption,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: AppDimensions.paddingLarge),
              Row(
                children: [
                  Expanded(
                    child: _googleButton(),
                  ),
                  SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: _socialButton(Icons.apple_rounded, 'Apple'),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.paddingXL),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing you agree to our ',
                    style: AppTypography.caption,
                    children: [
                      TextSpan(
                        text: 'Terms',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentMovie,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentMovie,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Real Google Sign-In button.
  Widget _googleButton() {
    return OutlinedButton.icon(
      onPressed: _signInWithGoogle,
      icon: Icon(Icons.g_mobiledata_rounded, color: AppColors.textPrimary),
      label: Text(
        'Google',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(AppDimensions.buttonHeightMedium),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),
    );
  }

  /// Handles Google Sign-In flow.
  Future<void> _signInWithGoogle() async {
    final ok = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      if (error != null && !error.contains('cancelled')) {
        context.showSnack(error, isError: true);
      }
    }
  }

  Widget _socialButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () =>
          context.showSnack('$label sign-in coming soon!'),
      icon: Icon(icon, color: AppColors.textPrimary),
      label: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(AppDimensions.buttonHeightMedium),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),
    );
  }
}
