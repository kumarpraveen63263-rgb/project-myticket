import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/booking_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/ticket/digital_ticket_card.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(lastBookingProvider);

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: AppButton(
            label: context.tr('Go to Home'),
            fullWidth: false,
            onPressed: () => context.go('/home'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          children: [
            Center(
              child:
                  Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut)
                      .fadeIn(),
            ),
            SizedBox(height: AppDimensions.paddingLarge),
            Center(
              child: Text(
                'Booking Confirmed!',
                style: AppTypography.displaySmall,
              ),
            ),
            SizedBox(height: 6),
            Center(
              child: Text(
                'Booking ID: ${booking.bookingId}',
                style: AppTypography.bodyMedium,
              ),
            ),
            SizedBox(height: 4),
            Center(
              child: Text(
                '${booking.title} · ${AppDateUtils.formatFullDate(booking.date)}',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: AppDimensions.paddingLarge),
            DigitalTicketCard(booking: booking),
            SizedBox(height: AppDimensions.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'View Ticket',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push('/ticket/${booking.id}'),
                  ),
                ),
                SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: AppButton(
                    label: 'Add to Calendar',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => context.showSnack('Added to calendar'),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.paddingSmall),
            AppButton(
              label: context.tr('Share'),
              icon: Icons.share_rounded,
              variant: AppButtonVariant.ghost,
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      'I just booked ${booking.title} on MyTickets! Booking ID: ${booking.bookingId}',
                ),
              ),
            ),
            SizedBox(height: AppDimensions.paddingLarge),
            Center(
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  context.tr('Go to Home'),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.accentMovie,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
