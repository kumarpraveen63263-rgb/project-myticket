import '../models/booking_model.dart';
import '../models/ticket_model.dart';

/// Clean abstract contract for Booking Repository.
/// Enables seamless swapping between production backend and offline/demo implementations.
abstract class BookingRepositoryInterface {
  Future<List<BookingModel>> getAll();
  Future<List<BookingModel>> getByStatus(TicketStatus status);
  Future<BookingModel?> getById(String id);
  Future<BookingModel> createBooking(BookingModel booking);
  Future<void> cancelBooking(String id);

  /// Atomically holds the requested seats on the server.
  Future<SeatHoldResult> holdSeats({
    required String showId,
    required List<String> seatIds,
    required String title,
    required String venue,
    required DateTime date,
    required String time,
    required String screen,
    required String imageUrl,
    required String referenceId,
  });

  /// Requests a server-verified payment order.
  Future<PaymentOrderResult> createPaymentOrder({
    required String holdId,
    String? promoCode,
  });

  /// Verifies the payment with server signature check.
  Future<BookingConfirmationResult> verifyPayment({
    required String holdId,
    required String orderId,
    required String paymentId,
    required String signature,
  });
}

class SeatHoldResult {
  final bool success;
  final String holdId;
  final String bookingId;
  final double subtotal;
  final double convenienceFee;
  final double gst;
  final double totalAmount;
  final DateTime expiresAt;
  final String? errorMessage;

  const SeatHoldResult({
    required this.success,
    required this.holdId,
    required this.bookingId,
    required this.subtotal,
    required this.convenienceFee,
    required this.gst,
    required this.totalAmount,
    required this.expiresAt,
    this.errorMessage,
  });
}

class PaymentOrderResult {
  final String orderId;
  final int amountInPaise;
  final double finalAmount;
  final double discount;
  final String keyId;
  final String currency;

  const PaymentOrderResult({
    required this.orderId,
    required this.amountInPaise,
    required this.finalAmount,
    required this.discount,
    required this.keyId,
    this.currency = 'INR',
  });
}

class BookingConfirmationResult {
  final bool success;
  final String bookingId;
  final String qrToken;
  final String? errorMessage;

  const BookingConfirmationResult({
    required this.success,
    required this.bookingId,
    required this.qrToken,
    this.errorMessage,
  });
}
