import '../database/database_helper.dart';
import '../models/booking.dart';

class BookingRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Booking>> getBookingsForPassenger(int passengerId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        bookings.id,
        bookings.trip_id,
        bookings.passenger_id,
        bookings.seats_reserved,
        bookings.status,
        bookings.created_at,
        bookings.updated_at,
        trips.departure,
        trips.destination,
        trips.departure_date,
        trips.departure_time,
        trips.price AS price_per_seat,
        trips.available_seats AS trip_available_seats,
        trips.total_seats AS trip_total_seats,
        trips.status AS trip_status,
        trips.meeting_point,
        trips.description,
        drivers.full_name AS driver_name,
        drivers.is_verified AS driver_is_verified,
        drivers.profile_image AS driver_profile_image,
        vehicles.brand AS vehicle_brand,
        vehicles.model AS vehicle_model,
        vehicles.color AS vehicle_color,
        vehicles.seats AS vehicle_seats
      FROM bookings
      INNER JOIN trips ON trips.id = bookings.trip_id
      LEFT JOIN users AS drivers ON drivers.id = trips.driver_id
      LEFT JOIN vehicles
        ON vehicles.id = trips.vehicle_id AND vehicles.user_id = trips.driver_id
      WHERE bookings.passenger_id = ?
      ORDER BY bookings.created_at DESC, bookings.id DESC
    ''', [passengerId]);

    return rows.map(Booking.fromMap).toList(growable: false);
  }

  Future<Booking?> getBookingForPassenger({
    required int bookingId,
    required int passengerId,
  }) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        bookings.id,
        bookings.trip_id,
        bookings.passenger_id,
        bookings.seats_reserved,
        bookings.status,
        bookings.created_at,
        bookings.updated_at,
        trips.departure,
        trips.destination,
        trips.departure_date,
        trips.departure_time,
        trips.price AS price_per_seat,
        trips.available_seats AS trip_available_seats,
        trips.total_seats AS trip_total_seats,
        trips.status AS trip_status,
        trips.meeting_point,
        trips.description,
        drivers.full_name AS driver_name,
        drivers.is_verified AS driver_is_verified,
        drivers.profile_image AS driver_profile_image,
        vehicles.brand AS vehicle_brand,
        vehicles.model AS vehicle_model,
        vehicles.color AS vehicle_color,
        vehicles.seats AS vehicle_seats
      FROM bookings
      INNER JOIN trips ON trips.id = bookings.trip_id
      LEFT JOIN users AS drivers ON drivers.id = trips.driver_id
      LEFT JOIN vehicles
        ON vehicles.id = trips.vehicle_id AND vehicles.user_id = trips.driver_id
      WHERE bookings.id = ? AND bookings.passenger_id = ?
      LIMIT 1
    ''', [bookingId, passengerId]);

    return rows.isEmpty ? null : Booking.fromMap(rows.first);
  }

  Future<void> cancelBooking({
    required int bookingId,
    required int passengerId,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    await db.transaction((transaction) async {
      final rows = await transaction.rawQuery('''
        SELECT
          bookings.trip_id,
          bookings.seats_reserved,
          bookings.status AS booking_status,
          trips.available_seats,
          trips.total_seats,
          trips.status AS trip_status,
          trips.departure_date,
          trips.departure_time
        FROM bookings
        INNER JOIN trips ON trips.id = bookings.trip_id
        WHERE bookings.id = ? AND bookings.passenger_id = ?
        LIMIT 1
      ''', [bookingId, passengerId]);
      if (rows.isEmpty) throw StateError('Booking not found.');

      final booking = rows.first;
      final bookingStatus = booking['booking_status'] as String;
      final tripStatus = booking['trip_status'] as String;
      if (bookingStatus != 'pending') {
        throw StateError('Only pending bookings can be cancelled.');
      }
      if (tripStatus != 'available' ||
          _tripHasPassed(
            booking['departure_date'] as String,
            booking['departure_time'] as String,
            now,
          )) {
        throw StateError('This trip can no longer be cancelled.');
      }

      final tripId = booking['trip_id'] as int;
      final seats = booking['seats_reserved'] as int;
      final availableSeats = booking['available_seats'] as int;
      final totalSeats = booking['total_seats'] as int;
      if (availableSeats + seats > totalSeats) {
        throw StateError('Trip seat data is inconsistent.');
      }

      final changedBookings = await transaction.update(
        'bookings',
        {'status': 'cancelled', 'updated_at': nowIso},
        where: 'id = ? AND passenger_id = ? AND status = ?',
        whereArgs: [bookingId, passengerId, 'pending'],
      );
      if (changedBookings != 1) throw StateError('Booking has changed.');

      final changedTrips = await transaction.update(
        'trips',
        {
          'available_seats': availableSeats + seats,
          'updated_at': nowIso,
        },
        where: 'id = ? AND status = ?',
        whereArgs: [tripId, 'available'],
      );
      if (changedTrips != 1) throw StateError('Trip is no longer available.');
    });
  }

  bool _tripHasPassed(String date, String time, DateTime now) {
    final dateParts = date.split('-');
    final timeParts = time.split(':');
    if (dateParts.length != 3 || timeParts.length < 2) return true;
    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if ([year, month, day, hour, minute].contains(null)) return true;
    return DateTime(year!, month!, day!, hour!, minute!).isBefore(now);
  }

}
