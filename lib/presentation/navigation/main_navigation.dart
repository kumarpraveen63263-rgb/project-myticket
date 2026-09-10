import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// Bottom-nav shell. The [StatefulNavigationShell] is the single source of
/// truth for the active tab index and owns one persistent navigator + state
/// per branch (via the underlying IndexedStack).
class MainNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigation({super.key, required this.navigationShell});

  List<_NavItem> _items(BuildContext context) => [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: context.tr('Home'),
      color: AppColors.accentMovie,
    ),
    _NavItem(
      icon: Icons.movie_outlined,
      activeIcon: Icons.movie_rounded,
      label: context.tr('Movies'),
      color: AppColors.accentMovie,
    ),
    _NavItem(
      icon: Icons.celebration_outlined,
      activeIcon: Icons.celebration_rounded,
      label: context.tr('Events'),
      color: AppColors.accentEvent,
    ),
    _NavItem(
      icon: Icons.train_outlined,
      activeIcon: Icons.train_rounded,
      label: context.tr('Metro'),
      color: AppColors.accentMetro,
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: context.tr('Profile'),
      color: AppColors.accentMovie,
    ),
  ];

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, -2),
              blurRadius: 12,
            ),
          ],
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppDimensions.bottomNavHeight,
            child: Row(
              children: List.generate(items.length, (index) {
                return _NavButton(
                  item: items[index],
                  isActive: index == navigationShell.currentIndex,
                  onTap: () => _onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? item.color : AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        label: '${item.label} tab',
        selected: isActive,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? item.color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
