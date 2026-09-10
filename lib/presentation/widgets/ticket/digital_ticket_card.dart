import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/ticket_model.dart';
import '../common/cached_image_widget.dart';
import 'qr_display_widget.dart';

class DigitalTicketCard extends StatelessWidget {
  final BookingModel booking;
  final Color accentColor;

  const DigitalTicketCard({
    super.key,
    required this.booking,
    this.accentColor = AppColors.accentMovie,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [_topHalf(), _perforation(), _bottomHalf(context)],
      ),
    );
  }

  Widget _topHalf() {
    return Container(
      color: AppColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.type != BookingType.metro)
            CachedImageWidget(
              imageUrl: booking.imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: 0,
              category: booking.type == BookingType.movie
                  ? ImageCategory.movie
                  : ImageCategory.event,
            ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.title, style: AppTypography.headline),
                const SizedBox(height: 6),
                Text(
                  '${AppDateUtils.formatFullDate(booking.date)} · ${booking.time}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(booking.venue, style: AppTypography.bodySmall),
                if (booking.seats.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: booking.seats
                        .map(
                          (s) => Chip(
                            label: Text(
                              s,
                              style: AppTypography.caption.copyWith(
                                color: accentColor,
                              ),
                            ),
                            backgroundColor: accentColor.withValues(
                              alpha: 0.12,
                            ),
                            side: BorderSide(
                              color: accentColor.withValues(alpha: 0.4),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (booking.screen != null) ...[
                  const SizedBox(height: 4),
                  Text(booking.screen!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _perforation() {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLinePainter(),
          ),
        ],
      ),
    );
  }

  Widget _bottomHalf(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          QrDisplayWidget(data: booking.bookingId),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            booking.bookingId,
            style: AppTypography.titleMedium.copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text('Tap QR to expand', style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(min(x + dashWidth, size.width), size.height / 2),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
