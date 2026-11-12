import '../../../core/localization/app_localizations.dart';
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
import '../../../data/services/payment_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/metro_favourites_provider.dart';
import '../../../providers/offer_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/cached_image_widget.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _couponController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  bool _isPaying = false;
  bool _policyExpanded = false;

  @override
  void dispose() {
    _couponController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(BookingDraft draft) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    final offer = await ref.read(offerRepositoryProvider).validateCode(code);
    if (!mounted) return;
    if (offer == null) {
      context.showSnack('Invalid coupon code', isError: true);
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

  Future<void> _pay(
    BookingDraft draft,
    double total,
    double convenienceFee,
    double gst,
  ) async {
    if (_isPaying) return; // Prevent double-tap
    setState(() => _isPaying = true);

    try {
      final user = ref.read(authProvider).user;
      final phone = user?.phone ?? '9876543210';
      final email = user?.email ?? 'user@mytickets.app';
      final name = user?.name ?? 'MyTickets Customer';

      final bookingRepo = ref.read(bookingRepositoryProvider);

      // 1. Hold seats atomically on server
      final holdResult = await bookingRepo.holdSeats(
        showId: draft.referenceId,
        seatIds: draft.seats,
        title: draft.title,
        venue: draft.venue,
        date: draft.date,
        time: draft.time,
        screen: draft.screen ?? 'Screen 1',
        imageUrl: draft.imageUrl,
        referenceId: draft.referenceId,
      );

      if (!holdResult.success) {
        if (!mounted) return;
        setState(() => _isPaying = false);
        context.showSnack(
          holdResult.errorMessage ?? 'Seats are no longer available.',
          isError: true,
        );
        return;
      }

      // 2. Request verified backend order
      final appliedCode = ref.read(appliedOfferCodeProvider);
      final orderResult = await bookingRepo.createPaymentOrder(
        holdId: holdResult.holdId,
        promoCode: appliedCode,
      );

      // 3. Initiate checkout through Razorpay SDK
      final paymentResult = await _paymentService.openCheckout(
        keyId: orderResult.keyId,
        orderId: orderResult.orderId,
        amountInPaise: orderResult.amountInPaise,
        description: '${draft.title} — ${draft.quantity} ticket(s)',
        phone: phone,
        email: email,
        name: name,
      );

      if (!paymentResult.success) {
        if (!mounted) return;
        setState(() => _isPaying = false);
        final err = paymentResult.errorMessage ?? 'Payment cancelled';
        if (!err.toLowerCase().contains('cancelled')) {
          context.showSnack(err, isError: true);
        }
        return;
      }

      // 4. Server-verified confirmation
      final verifyResult = await bookingRepo.verifyPayment(
        holdId: holdResult.holdId,
        orderId: paymentResult.orderId ?? orderResult.orderId,
        paymentId: paymentResult.paymentId ?? '',
        signature: paymentResult.signature ?? '',
      );

      if (!verifyResult.success) {
        if (!mounted) return;
        setState(() => _isPaying = false);
        context.showSnack(
          verifyResult.errorMessage ?? 'Payment verification failed',
          isError: true,
        );
        return;
      }

      // 5. Build confirmed ticket model for client display
      final booking = BookingModel(
        id: holdResult.holdId,
        bookingId: verifyResult.bookingId,
        type: draft.type,
        referenceId: draft.referenceId,
        title: draft.title,
        imageUrl: draft.imageUrl,
        venue: draft.venue,
        date: draft.date,
        time: draft.time,
        seats: draft.seats,
        quantity: draft.quantity,
        subtotal: holdResult.subtotal,
        convenienceFee: holdResult.convenienceFee,
        gst: holdResult.gst,
        discount: orderResult.discount,
        totalAmount: orderResult.finalAmount,
        status: TicketStatus.upcoming,
        createdAt: DateTime.now(),
        screen: draft.screen,
        fromStation: draft.fromStation,
        toStation: draft.toStation,
      );

      final created = await bookingRepo.createBooking(booking);

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
      setState(() => _isPaying = false);

      if (!mounted) return;
      context.go('/booking/confirmation');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      context.showSnack('Checkout error: $e', isError: true);
    }
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
        body: const Center(child: Text('Your cart is empty')),
      );
    }

    final convenienceFee = draft.type == BookingType.metro
        ? 0.0
        : (draft.seats.isNotEmpty
            ? draft.seats.length * AppConstants.convenienceFeePerTicket
            : draft.quantity * AppConstants.convenienceFeePerTicket);
    final gst = draft.type == BookingType.metro
        ? 0.0
        : (draft.subtotal + convenienceFee) * AppConstants.gstRate;
    final total = (draft.subtotal + convenienceFee + gst - discount)
        .clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.tr('Checkout')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        children: [
          _demoNoticeBanner(),
          const SizedBox(height: AppDimensions.paddingMedium),
          _orderSummary(draft),
          const SizedBox(height: AppDimensions.paddingLarge),
          _priceBreakdown(draft, convenienceFee, gst, discount, total),
          const SizedBox(height: AppDimensions.paddingLarge),
          _couponSection(draft, appliedCode),
          const SizedBox(height: AppDimensions.paddingLarge),
          _paymentMethods(paymentMethod),
          const SizedBox(height: AppDimensions.paddingLarge),
          _cancellationPolicy(),
          const SizedBox(height: AppDimensions.bottomPadding),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: AppButton(
            label: 'Pay ${CurrencyUtils.format(total)}',
            isLoading: _isPaying,
            size: AppButtonSize.large,
            onPressed: () => _pay(draft, total, convenienceFee, gst),
          ),
        ),
      ),
    );
  }

  Widget _demoNoticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppColors.accentMovie),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verified Checkout • 10-minute atomic server hold on selected seats',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderSummary(BookingDraft draft) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.title, style: AppTypography.titleLarge),
                const SizedBox(height: 4),
                Text(draft.venue, style: AppTypography.bodySmall),
                const SizedBox(height: 2),
                Text(
                  '${AppDateUtils.formatFullDate(draft.date)} · ${draft.time}',
                  style: AppTypography.bodySmall,
                ),
                if (draft.seats.isNotEmpty) ...[
                  const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
          const Divider(height: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _couponController,
                hintText: context.tr('Enter promo code'),
                prefixIcon: Icons.local_offer_outlined,
              ),
            ),
            const SizedBox(width: 8),
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
          const SizedBox(height: 8),
          Text(
            'Applied: $appliedCode',
            style: AppTypography.bodySmall.copyWith(color: AppColors.success),
          ),
        ],
        const SizedBox(height: AppDimensions.paddingSmall),
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
                    side: const BorderSide(color: AppColors.border),
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
        const SizedBox(height: AppDimensions.paddingSmall),
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
                        const SizedBox(width: 10),
                        Text(m.$1, style: AppTypography.titleMedium),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(left: 30),
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
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tickets once booked cannot be exchanged or refunded within 2 hours of showtime. Prior to 2 hours, cancellation carries a 20% venue fee. In case of show cancellation by the venue, a full 100% refund will be processed automatically to the original source of payment within 5-7 business days.',
              style: AppTypography.bodySmall.copyWith(height: 1.5),
            ),
          ),
      ],
    );
  }
}
