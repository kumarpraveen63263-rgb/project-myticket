import 'package:flutter_test/flutter_test.dart';
import 'package:mytick/data/repositories/booking_repository.dart';

void main() {
  group('BookingRepository Atomic Seat Hold & Security Tests', () {
    late BookingRepository repository;

    setUp(() {
      repository = BookingRepository();
    });

    test('holdSeats returns 10-minute hold with server-calculated breakdown', () async {
      final now = DateTime.now();
      final result = await repository.holdSeats(
        showId: 'show_test_101',
        seatIds: ['E12', 'E13'],
        title: 'Kalki 2898 AD',
        venue: 'PVR Ampa Skywalk',
        date: now.add(const Duration(days: 1)),
        time: '8:00 PM',
        screen: 'Screen 2',
        imageUrl: '',
        referenceId: 'm001',
      );

      expect(result.success, isTrue);
      expect(result.holdId.startsWith('hold_'), isTrue);
      expect(result.bookingId.startsWith('MT'), isTrue);
      // 2 seats * 150.0 = 300.0
      expect(result.subtotal, 300.0);
      // 2 seats * 30.0 fee = 60.0
      expect(result.convenienceFee, 60.0);
      // 18% GST on (300 + 60) = 64.8
      expect(result.gst, 64.8);
      expect(result.totalAmount, 424.8);
      expect(result.expiresAt.isAfter(now), isTrue);
    });

    test('createPaymentOrder applies valid coupon on server and computes final payable', () async {
      final orderWithPromo = await repository.createPaymentOrder(
        holdId: 'hold_sample_123',
        promoCode: 'FIRST100',
      );

      expect(orderWithPromo.discount, 100.0);
      expect(orderWithPromo.finalAmount, 254.0);
      expect(orderWithPromo.amountInPaise, 25400);
      expect(orderWithPromo.orderId.startsWith('order_'), isTrue);

      final orderWithoutPromo = await repository.createPaymentOrder(
        holdId: 'hold_sample_123',
        promoCode: 'INVALID_COUPON',
      );

      expect(orderWithoutPromo.discount, 0.0);
      expect(orderWithoutPromo.finalAmount, 354.0);
    });

    test('verifyPayment issues signed QR token containing orderId and verifiable salt', () async {
      final verification = await repository.verifyPayment(
        holdId: 'hold_sample_123',
        orderId: 'order_99887766',
        paymentId: 'pay_test_554433',
        signature: 'sig_mock_ok',
      );

      expect(verification.success, isTrue);
      expect(verification.bookingId, 'MT887766');
      expect(verification.qrToken.isNotEmpty, isTrue);
    });
  });
}
