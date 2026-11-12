import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/metro_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/metro_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/metro/metro_map_widget.dart';

class MetroRouteScreen extends ConsumerWidget {
  const MetroRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(metroRouteProvider);
    final passengers = ref.watch(metroPassengerCountProvider);
    final from = ref.watch(fromStationProvider);
    final to = ref.watch(toStationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.tr('Route Details')),
      ),
      body: route == null
          ? AppEmptyState(
              icon: Icons.route_outlined,
              title: context.tr('Select both stations to view route'),
            )
          : ListView(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              children: [
                MetroMapWidget(stations: route.stations),
                SizedBox(height: AppDimensions.paddingSmall),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.push('/metro/map'),
                    icon: Icon(
                      Icons.map_rounded,
                      size: 16,
                      color: AppColors.accentMetro,
                    ),
                    label: Text(
                      context.tr('View on live map'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentMetro,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppDimensions.paddingSmall),
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        context.tr('Stations'),
                        '${route.stations.length}',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _infoCard(
                        context.tr('Travel Time'),
                        '${route.travelMinutes} min',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _infoCard(
                        context.tr('Interchanges'),
                        '${route.interchanges}',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.paddingLarge),
                Container(
                  padding: EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _fareRow('Base fare', 10),
                      _fareRow(
                        context.tr('Distance fare'),
                        (route.fare - 10).toDouble().clamp(0, double.infinity),
                      ),
                      Divider(height: 20),
                      _fareRow(
                        context.tr('Total (per passenger)'),
                        route.fare.toDouble(),
                        bold: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimensions.paddingLarge),
                Text(
                  context.tr('Number of Passengers'),
                  style: AppTypography.titleLarge,
                ),
                SizedBox(height: AppDimensions.paddingSmall),
                Row(
                  children: [
                    _stepperButton(Icons.remove_rounded, () {
                      if (passengers > 1) {
                        ref.read(metroPassengerCountProvider.notifier).state =
                            passengers - 1;
                      }
                    }),
                    Expanded(
                      child: Text(
                        '$passengers',
                        textAlign: TextAlign.center,
                        style: AppTypography.displaySmall,
                      ),
                    ),
                    _stepperButton(Icons.add_rounded, () {
                      if (passengers < AppConstants.maxMetroPassengers) {
                        ref.read(metroPassengerCountProvider.notifier).state =
                            passengers + 1;
                      }
                    }),
                  ],
                ),
                SizedBox(height: AppDimensions.paddingLarge),
                AppButton(
                  label:
                      "${context.tr('Book Tickets')} (${CurrencyUtils.format(route.fare * passengers)})",
                  accentColor: AppColors.accentMetro,
                  onPressed: () {
                    ref
                        .read(bookingDraftProvider.notifier)
                        .set(
                          BookingDraft(
                            type: BookingType.metro,
                            referenceId: 'metro',
                            title: '$from → $to',
                            imageUrl:
                                'https://picsum.photos/seed/metroticket/300/450',
                            venue: route.stations.first.line.label,
                            date: DateTime.now(),
                            time: TimeOfDay.now().format(context),
                            seats: [],
                            quantity: passengers,
                            subtotal: (route.fare * passengers).toDouble(),
                            fromStation: from,
                            toStation: to,
                          ),
                        );
                    context.push('/booking/checkout');
                  },
                ),
                SizedBox(height: AppDimensions.bottomPadding),
              ],
            ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
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
      ),
    );
  }

  Widget _fareRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? AppTypography.titleMedium : AppTypography.bodyMedium,
          ),
          Text(
            CurrencyUtils.format(amount),
            style: bold
                ? AppTypography.titleLarge.copyWith(
                    color: AppColors.accentMetro,
                  )
                : AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}
