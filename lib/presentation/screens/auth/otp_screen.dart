import '../../../core/localization/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = AppConstants.otpResendSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _secondsLeft = AppConstants.otpResendSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != AppConstants.otpLength) {
      context.showSnack('Enter the complete 6-digit OTP', isError: true);
      return;
    }
    final ok = await ref
        .read(authProvider.notifier)
        .verifyOtp(widget.phone, otp);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error ?? 'Invalid OTP. Please try again.';
      context.showSnack(error, isError: true);
      _otpController.clear();
    }
  }

  Future<void> _resend() async {
    final ok = await ref.read(authProvider.notifier).sendOtp(widget.phone);
    if (!mounted) return;
    _startTimer();
    if (ok) {
      context.showSnack('OTP sent again');
    } else {
      final error = ref.read(authProvider).error ?? 'Failed to resend OTP';
      context.showSnack(error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: AppTypography.displaySmall,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Verify your number'),
              style: AppTypography.displaySmall,
            ),
            SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to +91 ${widget.phone.maskedPhone}',
              style: AppTypography.bodyMedium,
            ),
            SizedBox(height: AppDimensions.paddingXL),
            Pinput(
              controller: _otpController,
              length: AppConstants.otpLength,
              autofocus: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: AppColors.accentMovie, width: 1.5),
                ),
              ),
              onCompleted: (_) => _verify(),
            ),
            SizedBox(height: AppDimensions.paddingLarge),
            Center(
              child: _secondsLeft > 0
                  ? Text(
                      'Resend OTP in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                      style: AppTypography.bodyMedium,
                    )
                  : TextButton(
                      onPressed: _resend,
                      child: Text(
                        'Resend OTP',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accentMovie,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: AppDimensions.paddingLarge),
            AppButton(
              label: context.tr('Verify & Continue'),
              isLoading: isLoading,
              onPressed: _verify,
              size: AppButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}
