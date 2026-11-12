import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../providers/metro_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/metro/interactive_metro_map.dart';

/// Fullscreen live map: the map fills the entire screen, with a back button
/// floating over it and a draggable bottom sheet (Google-Maps-style) for
/// From/To selection and, once both are picked, a route summary that reuses
/// the same fare/duration calculation as the rest of the booking flow.
class MetroMapScreen extends ConsumerWidget {
  const MetroMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: InteractiveMetroMap(height: null)),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: AppDimensions.paddingMedium,
            child: _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.16,
            maxChildSize: 0.62,
            builder: (context, scrollController) =>
                _RouteSheet(scrollController: scrollController),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _RouteSheet extends ConsumerWidget {
  final ScrollController scrollController;
  const _RouteSheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final from = ref.watch(fromStationProvider);
    final to = ref.watch(toStationProvider);
    final route = ref.watch(metroRouteProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          AppDimensions.paddingMedium,
          10,
          AppDimensions.paddingMedium,
          AppDimensions.paddingLarge,
        ),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: EdgeInsets.only(bottom: AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.map_rounded, color: AppColors.accentMetro, size: 20),
              SizedBox(width: 8),
              Text(
                context.tr('Tap a station to select it'),
                style: AppTypography.titleMedium,
              ),
            ],
          ),
          SizedBox(height: AppDimensions.paddingMedium),
          _stationRow(
            context,
            ref,
            label: context.tr('From'),
            value: from,
            isFrom: true,
          ),
          Divider(height: 20, color: AppColors.border),
          _stationRow(
            context,
            ref,
            label: context.tr('To'),
            value: to,
            isFrom: false,
          ),
          if (route != null) ...[
            SizedBox(height: AppDimensions.paddingLarge),
            Container(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _stat('${route.stations.length}', 'Stations'),
                  ),
                  Expanded(
                    child: _stat('${route.travelMinutes} min', 'Duration'),
                  ),
                  Expanded(
                    child: _stat(
                      CurrencyUtils.format(route.fare.toDouble()),
                      'Fare',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimensions.paddingMedium),
            AppButton(
              label: context.tr('Book Tickets'),
              accentColor: AppColors.accentMetro,
              onPressed: () {
                ref.read(recentRoutesProvider.notifier).addRoute(from!, to!);
                context.push('/metro/route');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _stationRow(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String? value,
    required bool isFrom,
  }) {
    return InkWell(
      onTap: () async {
        final result = await context.push<String>('/metro/search-station');
        if (result != null) {
          final notifier = isFrom
              ? ref.read(fromStationProvider.notifier)
              : ref.read(toStationProvider.notifier);
          notifier.state = result;
        }
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Row(
        children: [
          Icon(
            isFrom ? Icons.trip_origin_rounded : Icons.location_on_rounded,
            size: 18,
            color: isFrom
                ? AppColors.metroSelectedRoute
                : AppColors.accentMovie,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                Text(
                  value ?? 'Tap map or search',
                  style: AppTypography.titleMedium.copyWith(
                    color: value == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.accentMetro,
          ),
        ),
        SizedBox(height: 2),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
