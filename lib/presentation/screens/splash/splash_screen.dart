import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    try {
      final storage = ref.read(localStorageServiceProvider);
      if (!storage.hasSeenOnboarding) {
        context.go('/onboarding');
      } else if (ref.read(authProvider).isLoggedIn || storage.isLoggedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.accentMovie,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                )
                .animate()
                .scale(
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1, 1),
                )
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            Text(AppConstants.appName, style: AppTypography.displayMedium)
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: AppTypography.bodyMedium,
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
