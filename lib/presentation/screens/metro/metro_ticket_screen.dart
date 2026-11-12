import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/booking_provider.dart';
import '../../widgets/common/app_badge.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/ticket/digital_ticket_card.dart';

class MetroTicketScreen extends ConsumerWidget {
  final String bookingId;

  const MetroTicketScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.tr('Metro Ticket')),
      ),
      body: bookingAsync.when(
        loading: () => const AppLoader(color: AppColors.accentMetro),
        error: (_, _) =>
            Center(child: Text(context.tr('Failed to load ticket'))),
        data: (booking) {
          if (booking == null) {
            return Center(child: Text(context.tr('Ticket not found')));
          }
          final validUntil = booking.createdAt.add(
            Duration(minutes: AppConstants.metroTicketValidMinutes),
          );
          final isExpired = DateTime.now().isAfter(validUntil);
          return ListView(
            padding: EdgeInsets.only(bottom: AppDimensions.paddingLarge),
            children: [
              DigitalTicketCard(
                booking: booking,
                accentColor: AppColors.accentMetro,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppBadge(
                          label: isExpired
                              ? context.tr('Expired')
                              : 'Valid for ${AppConstants.metroTicketValidMinutes} min',
                          color: isExpired
                              ? AppColors.error
                              : AppColors.success,
                          icon: Icons.access_time_rounded,
                        ),
                        SizedBox(width: 8),
                        AppBadge(
                          label: context.tr('One-time use only'),
                          color: AppColors.accentMetro,
                          icon: Icons.qr_code_scanner_rounded,
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.paddingSmall),
                    Text(
                      '${booking.fromStation} → ${booking.toStation}',
                      style: AppTypography.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
