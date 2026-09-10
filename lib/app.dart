import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/widgets/common/connectivity_banner.dart';
import 'providers/language_provider.dart';

class MyTicketsApp extends ConsumerWidget {
  const MyTicketsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(languageProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      locale: Locale(languageCode),
      routerConfig: AppRouter.router,
      builder: (context, child) => AppLocaleScope(
        languageCode: languageCode,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: ConnectivityBanner(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
