import '../services/local_storage_service.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_model.dart';
import '../models/seat_model.dart';
import '../models/show_model.dart';
import '../models/ticket_model.dart';

class BookingRepository {
  static const _uuid = Uuid();
  static final LocalStorageService _storage = LocalStorageService();
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
      venue: 'Blue Line',
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
    BookingModel(
      id: 'bk_seed_3',
      bookingId:
          'MT${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 10)}C',
      type: BookingType.event,
      referenceId: 'e002',
      title: 'Zakir Khan — Standup Special',
      imageUrl: 'https://picsum.photos/seed/zakirkhan/800/450',
      venue: 'Sir Mutha Venkatasubba Rao Concert Hall',
      date: DateTime.now().subtract(const Duration(days: 10)),
      time: '8:00 PM',
      seats: const [],
      quantity: 2,
      subtotal: 1198,
      convenienceFee: 60,
      gst: 226.4,
      discount: 0,
      totalAmount: 1484.4,
      status: TicketStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    BookingModel(
      id: 'bk_seed_4',
      bookingId:
          'MT${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 10)}D',
      type: BookingType.movie,
      referenceId: 'm004',
      title: 'Animal',
      imageUrl: 'https://picsum.photos/seed/animal/300/450',
      venue: 'INOX Citi Centre, Mount Road',
      date: DateTime.now().subtract(const Duration(days: 20)),
      time: '4:30 PM',
      seats: const ['H4'],
      quantity: 1,
      subtotal: 150,
      convenienceFee: 30,
      gst: 32.4,
      discount: 0,
      totalAmount: 212.4,
      status: TicketStatus.cancelled,
      createdAt: DateTime.now().subtract(const Duration(days: 21)),
      screen: 'Screen 1',
    ),
  ];

  Future<void> _restorePersistedBookings() async {
    if (_restored) return;
    _restored = true;
    for (final booking in _storage.savedBookings) {
      if (!_bookings.any((item) => item.id == booking.id)) {
        _bookings.add(booking);
        await _storage.saveBooking(booking);
      }
    }
  }

  Future<List<BookingModel>> getAll() async {
    await _restorePersistedBookings();
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_bookings.reversed);
  }

  Future<List<BookingModel>> getByStatus(TicketStatus status) async {
    await _restorePersistedBookings();
    await Future.delayed(const Duration(milliseconds: 200));
    return _bookings
        .where((b) => b.status == status)
        .toList()
        .reversed
        .toList();
  }

  Future<BookingModel?> getById(String id) async {
    await _restorePersistedBookings();
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<BookingModel> createBooking(BookingModel booking) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _bookings.add(booking);
    await _storage.saveBooking(booking);
    return booking;
  }

  Future<void> cancelBooking(String id) async {
    await _restorePersistedBookings();
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final updated = _bookings[idx].copyWith(status: TicketStatus.cancelled);
      _bookings[idx] = updated;
      await _storage.saveBooking(updated);
    }
  }

  static String generateBookingId() {
    return 'MT${_uuid.v4().substring(0, 8).toUpperCase()}';
  }

  static List<SeatModel> generateSeatsForShow(ShowModel show) {
    final seats = <SeatModel>[];
    final layout = <String, int>{
      'A': 8, // Recliner
      'B': 12, 'C': 12, 'D': 12, // Premium
      'E': 14, 'F': 14, 'G': 14, 'H': 14, // Executive
      'I': 16, 'J': 16, 'K': 16, 'L': 16, // Normal
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

    layout.forEach((row, count) {
      final category = _categoryForRow(row);
      final price = _priceForCategory(category, show);
      for (int i = 1; i <= count; i++) {
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
    final seed = show.id.codeUnits.fold<int>(0, (sum, code) => sum + code);
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
