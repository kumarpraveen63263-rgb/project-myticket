import '../../../core/localization/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/offer_provider.dart';
import '../../../providers/metro_favourites_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/cached_image_widget.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isPaying = false;
  bool _policyExpanded = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(BookingDraft draft) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    final offer = await ref.read(offerRepositoryProvider).validateCode(code);
    if (!mounted) return;
    if (offer == null) {
      ref.read(appliedOfferCodeProvider.notifier).state = null;
      ref.read(appliedDiscountProvider.notifier).state = 0;
      context.showSnack('Invalid or expired coupon code', isError: true);
    } else {
      ref.read(appliedOfferCodeProvider.notifier).state = offer.code;
      final discount = offer.discountText.contains('%')
          ? draft.subtotal *
                (double.tryParse(
                      offer.discountText.replaceAll(RegExp(r'[^0-9]'), ''),
                    ) ??
                    0) /
                100
          : double.tryParse(
                  offer.discountText.replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0;
      ref.read(appliedDiscountProvider.notifier).state = discount;
      context.showSnack('Coupon applied! ${offer.discountText}');
    }
  }

  Future<void> _pay(BookingDraft draft, double total) async {
    setState(() => _isPaying = true);
    final booking = BookingModel(
      id: 'bk_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: BookingRepository.generateBookingId(),
      type: draft.type,
      referenceId: draft.referenceId,
      title: draft.title,
      imageUrl: draft.imageUrl,
      venue: draft.venue,
      date: draft.date,
      time: draft.time,
      seats: draft.seats,
      quantity: draft.quantity,
      subtotal: draft.subtotal,
      convenienceFee: draft.seats.length * AppConstants.convenienceFeePerTicket,
      gst:
          (draft.subtotal +
              draft.seats.length * AppConstants.convenienceFeePerTicket) *
          AppConstants.gstRate,
      discount: ref.read(appliedDiscountProvider),
      totalAmount: total,
      status: TicketStatus.upcoming,
      createdAt: DateTime.now(),
      screen: draft.screen,
      fromStation: draft.fromStation,
      toStation: draft.toStation,
    );

    final created = await ref
        .read(bookingRepositoryProvider)
        .createBooking(booking);
    if (!mounted) return;
    if (draft.type == BookingType.metro &&
        draft.fromStation != null &&
        draft.toStation != null) {
      await ref
          .read(metroFavouriteRoutesProvider.notifier)
          .add(metroRouteKey(draft.fromStation!, draft.toStation!));
    }
    ref.read(lastBookingProvider.notifier).state = created;
    ref.invalidate(allBookingsProvider);
    ref.read(appliedOfferCodeProvider.notifier).state = null;
    ref.read(appliedDiscountProvider.notifier).state = 0;
    ref.read(bookingDraftProvider.notifier).clear();
    ref.read(appliedOfferCodeProvider.notifier).state = null;
    ref.read(appliedDiscountProvider.notifier).state = 0;
    setState(() => _isPaying = false);
    context.go('/booking/confirmation');
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    final appliedCode = ref.watch(appliedOfferCodeProvider);
    final discount = ref.watch(appliedDiscountProvider);
    final paymentMethod = ref.watch(selectedPaymentMethodProvider);

    if (draft == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(context.tr('Checkout'))),
        body: Center(child: Text('Your cart is empty')),
      );
    }

    final convenienceFee = draft.seats.isNotEmpty
        ? draft.seats.length * AppConstants.convenienceFeePerTicket
        : AppConstants.convenienceFeePerTicket;
    final gst = (draft.subtotal + convenienceFee) * AppConstants.gstRate;
    final total = draft.subtotal + convenienceFee + gst - discount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.tr('Checkout')),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        children: [
          _orderSummary(draft),
          SizedBox(height: AppDimensions.paddingLarge),
          _priceBreakdown(draft, convenienceFee, gst, discount, total),
          SizedBox(height: AppDimensions.paddingLarge),
          _couponSection(draft, appliedCode),
          SizedBox(height: AppDimensions.paddingLarge),
          _paymentMethods(paymentMethod),
          SizedBox(height: AppDimensions.paddingLarge),
          _cancellationPolicy(),
          SizedBox(height: AppDimensions.bottomPadding),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingMedium),
          child: AppButton(
            label: 'Pay ${CurrencyUtils.format(total)}',
            isLoading: _isPaying,
            size: AppButtonSize.large,
            onPressed: () => _pay(draft, total),
          ),
        ),
      ),
    );
  }

  Widget _orderSummary(BookingDraft draft) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedImageWidget(
            imageUrl: draft.imageUrl,
            width: 60,
            height: 80,
            fit: BoxFit.cover,
            borderRadius: AppDimensions.radiusSmall,
            category: ImageCategory.movie,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.title, style: AppTypography.titleLarge),
                SizedBox(height: 4),
                Text(draft.venue, style: AppTypography.bodySmall),
                SizedBox(height: 2),
                Text(
                  '${AppDateUtils.formatFullDate(draft.date)} · ${draft.time}',
                  style: AppTypography.bodySmall,
                ),
                if (draft.seats.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    'Seats: ${draft.seats.join(', ')}',
                    style: AppTypography.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceBreakdown(
    BookingDraft draft,
    double fee,
    double gst,
    double discount,
    double total,
  ) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _priceRow('Ticket price × ${draft.quantity}', draft.subtotal),
          _priceRow('Convenience fee', fee),
          _priceRow('GST (18%)', gst),
          if (discount > 0)
            _priceRow('Promo discount', -discount, color: AppColors.success),
          Divider(height: 20),
          _priceRow('Total Payable', total, bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    double amount, {
    bool bold = false,
    Color? color,
  }) {
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
            '${amount < 0 ? '-' : ''}${CurrencyUtils.format(amount.abs())}',
            style: (bold ? AppTypography.titleLarge : AppTypography.bodyMedium)
                .copyWith(
                  color:
                      color ??
                      (bold ? AppColors.accentMovie : AppColors.textPrimary),
                ),
          ),
        ],
      ),
    );
  }

  Widget _couponSection(BookingDraft draft, String? appliedCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('Apply Coupon'), style: AppTypography.titleLarge),
        SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _couponController,
                hintText: context.tr('Enter promo code'),
                prefixIcon: Icons.local_offer_outlined,
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: AppButton(
                label: context.tr('Apply'),
                size: AppButtonSize.medium,
                onPressed: () => _applyCoupon(draft),
              ),
            ),
          ],
        ),
        if (appliedCode != null) ...[
          SizedBox(height: 8),
          Text(
            'Applied: $appliedCode',
            style: AppTypography.bodySmall.copyWith(color: AppColors.success),
          ),
        ],
        SizedBox(height: AppDimensions.paddingSmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['FIRST100', 'EVENT20', 'WEEKEND15']
              .map(
                (c) => GestureDetector(
                  onTap: () {
                    _couponController.text = c;
                    _applyCoupon(draft);
                  },
                  child: Chip(
                    label: Text(c),
                    backgroundColor: AppColors.surfaceElevated,
                    side: BorderSide(color: AppColors.border),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _paymentMethods(String selected) {
    final methods = [
      ('UPI', Icons.qr_code_rounded, 'Google Pay, PhonePe, Paytm'),
      ('Card', Icons.credit_card_rounded, 'Credit / Debit Card'),
      ('Net Banking', Icons.account_balance_rounded, 'All major banks'),
      ('Wallet', Icons.account_balance_wallet_rounded, 'MyTickets Wallet'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('Payment Method'), style: AppTypography.titleLarge),
        SizedBox(height: AppDimensions.paddingSmall),
        RadioGroup<String>(
          groupValue: selected,
          onChanged: (v) =>
              ref.read(selectedPaymentMethodProvider.notifier).state = v!,
          child: Column(
            children: methods
                .map(
                  (m) => RadioListTile<String>(
                    value: m.$1,
                    activeColor: AppColors.accentMovie,
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Icon(m.$2, size: 20, color: AppColors.textPrimary),
                        SizedBox(width: 10),
                        Text(m.$1, style: AppTypography.titleMedium),
                      ],
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(left: 30),
                      child: Text(m.$3, style: AppTypography.caption),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _cancellationPolicy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _policyExpanded = !_policyExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('Cancellation Policy'),
                style: AppTypography.titleLarge,
              ),
              Icon(
                _policyExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        if (_policyExpanded)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Tickets once booked cannot be exchanged, refunded or cancelled. In case of show cancellation by the venue, a full refund will be processed automatically within 5-7 business days.',
              style: AppTypography.bodySmall.copyWith(height: 1.5),
            ),
          ),
      ],
    );
  }
}
