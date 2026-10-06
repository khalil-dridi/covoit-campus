import '../database/database_helper.dart';
import '../models/booking.dart';
import 'notification_repository.dart';

class BookingRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Booking>> getBookingsForAdminTrip(int tripId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT bookings.id, bookings.trip_id, bookings.passenger_id,
        bookings.seats_reserved, bookings.status, bookings.created_at, bookings.updated_at,
        passengers.full_name AS passenger_name,
        passengers.email AS passenger_email
      FROM bookings
      INNER JOIN users AS passengers ON passengers.id = bookings.passenger_id
      WHERE bookings.trip_id = ?
      ORDER BY bookings.created_at DESC, bookings.id DESC
    ''', [tripId]);
    return rows.map(Booking.fromMap).toList(growable: false);
  }

  Future<List<Booking>> getBookingsForDriverTrip({
    required int tripId,
    required int driverId,
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
        passengers.full_name AS passenger_name,
        passengers.profile_image AS passenger_image,
        passengers.university AS passenger_university
      FROM bookings
      INNER JOIN trips ON trips.id = bookings.trip_id
      INNER JOIN users AS passengers ON passengers.id = bookings.passenger_id
      WHERE bookings.trip_id = ? AND trips.driver_id = ?
      ORDER BY bookings.created_at DESC, bookings.id DESC
    ''', [tripId, driverId]);
    return rows.map(Booking.fromMap).toList(growable: false);
  }

  Future<void> decideBooking({
    required int bookingId,
    required int driverId,
    required bool accept,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    await db.transaction((transaction) async {
      final rows = await transaction.rawQuery('''
        SELECT
          bookings.trip_id,
          bookings.passenger_id,
          bookings.seats_reserved,
          bookings.status AS booking_status,
          trips.driver_id,
          trips.departure,
          trips.destination,
          trips.departure_date,
          trips.departure_time,
          trips.available_seats,
          trips.total_seats,
          trips.status AS trip_status
        FROM bookings
        INNER JOIN trips ON trips.id = bookings.trip_id
        WHERE bookings.id = ? AND trips.driver_id = ?
        LIMIT 1
      ''', [bookingId, driverId]);
      if (rows.isEmpty) throw StateError('Booking not found for this driver.');
      final row = rows.first;
      if (row['booking_status'] != 'pending') {
        throw StateError('Only pending bookings can be decided.');
      }
      if (row['trip_status'] != 'available') {
        throw StateError('Trip is not available.');
      }

      final status = accept ? 'accepted' : 'rejected';
      final changedBookings = await transaction.update(
        'bookings',
        {'status': status, 'updated_at': nowIso},
        where: 'id = ? AND status = ?',
        whereArgs: [bookingId, 'pending'],
      );
      if (changedBookings != 1) throw StateError('Booking has changed.');

      if (!accept) {
        final seatsReserved = row['seats_reserved'] as int;
        final availableSeats = row['available_seats'] as int;
        final totalSeats = row['total_seats'] as int;
        if (availableSeats + seatsReserved > totalSeats) {
          throw StateError('Trip seat data is inconsistent.');
        }
        final changedTrips = await transaction.update(
          'trips',
          {
            'available_seats': availableSeats + seatsReserved,
            'updated_at': nowIso,
          },
          where: 'id = ? AND driver_id = ? AND status = ?',
          whereArgs: [row['trip_id'], driverId, 'available'],
        );
        if (changedTrips != 1) throw StateError('Trip availability changed.');
      }

      final departure = row['departure'] as String;
      final destination = row['destination'] as String;
      await NotificationRepository.insertInTransaction(
        transaction: transaction,
        userId: row['passenger_id'] as int,
        title: accept
            ? 'Votre réservation a été acceptée'
            : 'Votre réservation a été refusée',
        body: 'Votre réservation pour le trajet $departure → $destination '
            'a été ${accept ? 'acceptée' : 'refusée'}.',
        type: 'booking:$bookingId;trip:${row['trip_id']}',
        createdAt: nowIso,
      );
    });
    NotificationRepository.notifyChanged();
  }

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
      if (bookingStatus != 'pending' && bookingStatus != 'accepted') {
        throw StateError('This booking can no longer be cancelled.');
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
        whereArgs: [bookingId, passengerId, bookingStatus],
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
