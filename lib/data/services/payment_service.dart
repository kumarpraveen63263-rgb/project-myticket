import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Result of a payment attempt.
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorMessage;
  final int? errorCode;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorMessage,
    this.errorCode,
  });
}

/// Wraps the Razorpay Flutter SDK for payment processing.
///
/// Usage:
/// ```dart
/// final service = PaymentService();
/// final result = await service.openCheckout(
///   keyId: 'rzp_test_xxxxx',
///   orderId: 'order_xxxxx',
///   amountInPaise: 54280,
///   description: 'Kalki 2898 AD - 2 tickets',
///   phone: '9876543210',
///   email: 'user@example.com',
/// );
/// service.dispose();
/// ```
class PaymentService {
  Razorpay? _razorpay;
  Completer<PaymentResult>? _completer;

  /// Opens the Razorpay checkout sheet.
  ///
  /// [keyId] — Your Razorpay Key ID (starts with 'rzp_test_' or 'rzp_live_').
  /// [orderId] — The order ID created by your backend.
  /// [amountInPaise] — Total amount in paise (₹100 = 10000 paise).
  /// [description] — Short description shown in checkout UI.
  /// [phone] — Customer's phone number for pre-fill.
  /// [email] — Customer's email for receipt.
  ///
  /// Returns a [PaymentResult] indicating success or failure.
  Future<PaymentResult> openCheckout({
    required String keyId,
    required String orderId,
    required int amountInPaise,
    required String description,
    required String phone,
    String? email,
    String? name,
  }) async {
    _razorpay?.clear();
    _razorpay = Razorpay();
    _completer = Completer<PaymentResult>();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final options = {
      'key': keyId,
      'amount': amountInPaise,
      'order_id': orderId,
      'currency': 'INR',
      'name': 'MyTickets',
      'description': description,
      'prefill': {
        'contact': phone,
        'email': ?email,
        'name': ?name,
      },
      'theme': {
        'color': '#E50914', // MyTickets accent color
      },
      'modal': {
        'confirm_close': true,
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _completer?.complete(PaymentResult(
        success: false,
        errorMessage: e.toString(),
      ));
    }

    return _completer!.future;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    _completer?.complete(PaymentResult(
      success: true,
      paymentId: response.paymentId,
      orderId: response.orderId,
      signature: response.signature,
    ));
  }

  void _handleError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _completer?.complete(PaymentResult(
      success: false,
      errorCode: response.code,
      errorMessage: _mapErrorMessage(response.code, response.message),
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    // External wallets (Paytm, PhonePe, etc.) redirect back after payment.
    // The result will come via success/error handlers.
  }

  /// Maps Razorpay error codes to user-friendly messages.
  String _mapErrorMessage(int? code, String? message) {
    switch (code) {
      case Razorpay.NETWORK_ERROR:
        return 'Network error. Please check your connection and try again.';
      case Razorpay.INVALID_OPTIONS:
        return 'Payment configuration error. Please try again later.';
      case Razorpay.PAYMENT_CANCELLED:
        return 'Payment was cancelled.';
      case Razorpay.TLS_ERROR:
        return 'Secure connection error. Please update your device.';
      default:
        return message ?? 'Payment failed. Please try again.';
    }
  }

  /// Cleans up Razorpay listeners. Call when done with payments.
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
