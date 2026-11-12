import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/ticket_model.dart';
import '../../../providers/booking_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/ticket/digital_ticket_card.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String bookingId;

  const TicketDetailScreen({super.key, required this.bookingId});

  Color _accentFor(BookingType type) {
    switch (type) {
      case BookingType.movie:
        return AppColors.accentMovie;
      case BookingType.event:
        return AppColors.accentEvent;
      case BookingType.metro:
        return AppColors.accentMetro;
    }
  }

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
        title: Text(context.tr('Ticket')),
      ),
      body: bookingAsync.when(
        loading: () => const AppLoader(),
        error: (_, _) =>
            Center(child: Text(context.tr('Failed to load ticket'))),
        data: (booking) {
          if (booking == null) {
            return Center(child: Text(context.tr('Ticket not found')));
          }
          final accent = _accentFor(booking.type);
          return ListView(
            padding: EdgeInsets.only(bottom: AppDimensions.paddingLarge),
            children: [
              DigitalTicketCard(booking: booking, accentColor: accent),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: context.tr('Share'),
                        icon: Icons.share_rounded,
                        variant: AppButtonVariant.outlined,
                        accentColor: accent,
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(
                            text:
                                '${booking.title} — Booking ID: ${booking.bookingId}',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppDimensions.paddingSmall),
                    Expanded(
                      child: AppButton(
                        label: 'Download',
                        icon: Icons.download_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr(
                                  'Ticket saved to My Tickets for offline access',
                                ),
                              ),
                            ),
                          ),
                      ),
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
