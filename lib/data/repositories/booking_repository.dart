import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_model.dart';
import '../models/seat_model.dart';
import '../models/show_model.dart';
import '../models/ticket_model.dart';
import '../services/local_storage_service.dart';
import 'booking_repository_interface.dart';

class BookingRepository implements BookingRepositoryInterface {
  static const _uuid = Uuid();
  static final LocalStorageService _storage = LocalStorageService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _restored = false;

  static final List<BookingModel> _bookings = [
    BookingModel(
      id: 'bk_seed_1',
      bookingId:
          'MT${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 10)}A',
      type: BookingType.movie,
      referenceId: 'm001',
      title: 'Kalki 2898 AD',
      imageUrl: 'assets/images/kalki.jpg',
      venue: 'PVR Ampa Skywalk, Aminjikarai',
      date: DateTime.now().add(const Duration(days: 2)),
      time: '8:00 PM',
      seats: const ['E12', 'E13'],
      quantity: 2,
      subtotal: 400,
      convenienceFee: 60,
      gst: 82.8,
      discount: 0,
      totalAmount: 542.8,
      status: TicketStatus.upcoming,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      screen: 'Screen 2',
    ),
    BookingModel(
      id: 'bk_seed_2',
      bookingId:
          'MT${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 10)}B',
      type: BookingType.metro,
      referenceId: 'metro',
      title: 'Chennai Central → Guindy',
      imageUrl: 'https://picsum.photos/seed/metroticket/300/450',
      venue: 'Blue Line (Prototype)',
      date: DateTime.now(),
      time: '9:15 AM',
      seats: const [],
      quantity: 1,
      subtotal: 30,
      convenienceFee: 0,
      gst: 0,
      discount: 0,
      totalAmount: 30,
      status: TicketStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      fromStation: 'Chennai Central',
      toStation: 'Guindy',
    ),
  ];

  Future<void> _restorePersistedBookings() async {
    if (_restored) return;
    _restored = true;

    for (final booking in _storage.savedBookings) {
      if (!_bookings.any((item) => item.id == booking.id)) {
        _bookings.add(booking);
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          final firestoreBooking = BookingModel.fromMap(data);
          final existingIndex =
              _bookings.indexWhere((b) => b.id == firestoreBooking.id);
          if (existingIndex >= 0) {
            _bookings[existingIndex] = firestoreBooking;
          } else {
            _bookings.add(firestoreBooking);
          }
          await _storage.saveBooking(firestoreBooking);
        }
      } catch (e) {
        debugPrint('Firestore bookings fetch fallback: $e');
      }
    }
  }

  @override
  Future<List<BookingModel>> getAll() async {
    await _restorePersistedBookings();
    return List.unmodifiable(_bookings.reversed);
  }

  @override
  Future<List<BookingModel>> getByStatus(TicketStatus status) async {
    await _restorePersistedBookings();
    return _bookings
        .where((b) => b.status == status)
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<BookingModel?> getById(String id) async {
    await _restorePersistedBookings();
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    _bookings.add(booking);
    await _storage.saveBooking(booking);
    return booking;
  }

  @override
  Future<void> cancelBooking(String id) async {
    await _restorePersistedBookings();
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final updated = _bookings[idx].copyWith(status: TicketStatus.cancelled);
      _bookings[idx] = updated;
      await _storage.saveBooking(updated);
    }
  }

  @override
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
  }) async {
    final holdId = 'hold_${DateTime.now().millisecondsSinceEpoch}';
    final bookingId = generateBookingId();
    final subtotal = seatIds.length * 150.0;
    final fee = seatIds.length * 30.0;
    final gst = (subtotal + fee) * 0.18;
    final total = subtotal + fee + gst;

    return SeatHoldResult(
      success: true,
      holdId: holdId,
      bookingId: bookingId,
      subtotal: subtotal,
      convenienceFee: fee,
      gst: gst,
      totalAmount: total,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<PaymentOrderResult> createPaymentOrder({
    required String holdId,
    String? promoCode,
  }) async {
    double discount = 0;
    if (promoCode != null && promoCode.toUpperCase() == 'FIRST100') {
      discount = 100.0;
    }

    const total = 354.0;
    final finalAmount = (total - discount).clamp(0.0, double.infinity);

    return PaymentOrderResult(
      orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
      amountInPaise: (finalAmount * 100).round(),
      finalAmount: finalAmount,
      discount: discount,
      keyId: 'rzp_test_MyTicketsDemoKey',
    );
  }

  @override
  Future<BookingConfirmationResult> verifyPayment({
    required String holdId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    String uid = 'guest';
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) uid = user.uid;
    } catch (_) {
      // Offline / unit test fallback
    }
    final qrToken = base64UrlEncode(
      utf8.encode('$orderId:$uid:${DateTime.now().millisecondsSinceEpoch}'),
    );

    return BookingConfirmationResult(
      success: true,
      bookingId: 'MT${orderId.substring(orderId.length - 6).toUpperCase()}',
      qrToken: qrToken,
    );
  }

  static String generateBookingId() {
    return 'MT${_uuid.v4().substring(0, 8).toUpperCase()}';
  }

  static List<SeatModel> generateSeatsForShow(ShowModel show) {
    final seats = <SeatModel>[];
    final layout = <String, int>{
      'A': 8,
      'B': 12, 'C': 12, 'D': 12,
      'E': 14, 'F': 14, 'G': 14, 'H': 14,
      'I': 16, 'J': 16, 'K': 16, 'L': 16,
    };

    double bookedRatio;
    switch (show.availability) {
      case ShowAvailability.available:
        bookedRatio = 0.2;
        break;
      case ShowAvailability.fastFilling:
        bookedRatio = 0.6;
        break;
      case ShowAvailability.almostFull:
        bookedRatio = 0.9;
        break;
    }

    layout.forEach((row, seatCount) {
      final category = _categoryForRow(row);
      final price = _priceForCategory(category, show);
      for (int i = 1; i <= seatCount; i++) {
        seats.add(
          SeatModel(
            id: '${show.id}_$row$i',
            row: row,
            number: i,
            category: category,
            price: price,
            isBooked: _isSeatBooked(show, row, i, bookedRatio),
          ),
        );
      }
    });
    return seats;
  }

  static bool _isSeatBooked(
    ShowModel show,
    String row,
    int number,
    double ratio,
  ) {
    final seed = show.id.codeUnits.fold<int>(0, (acc, code) => acc + code);
    final seatSeed = seed + row.codeUnitAt(0) * 31 + number * 17;
    return (seatSeed % 100) / 100 < ratio;
  }

  static SeatCategory _categoryForRow(String row) {
    if (row == 'A') return SeatCategory.recliner;
    if (['B', 'C', 'D'].contains(row)) return SeatCategory.premium;
    if (['E', 'F', 'G', 'H'].contains(row)) return SeatCategory.executive;
    return SeatCategory.normal;
  }

  static double _priceForCategory(SeatCategory category, ShowModel show) {
    switch (category) {
      case SeatCategory.recliner:
        return show.priceRecliner;
      case SeatCategory.premium:
        return show.pricePremium;
      case SeatCategory.executive:
        return show.priceExecutive;
      case SeatCategory.normal:
        return show.priceNormal;
    }
  }
}
