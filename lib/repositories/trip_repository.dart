import '../database/database_helper.dart';
import '../models/booking.dart';
import '../models/trip.dart';
import '../models/trip_details.dart';
import 'notification_repository.dart';
import 'package:sqflite/sqflite.dart';

enum TripSort { earliest, cheapest, bestRated }

class TripRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Trip>> getAllTripsForAdmin() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT trips.*, drivers.full_name AS driver_name,
        drivers.is_verified AS driver_is_verified,
        drivers.profile_image AS driver_profile_image,
        (SELECT AVG(ratings.score) FROM ratings WHERE ratings.reviewed_id = drivers.id) AS driver_rating
      FROM trips
      INNER JOIN users AS drivers ON drivers.id = trips.driver_id
      ORDER BY trips.departure_date DESC, trips.departure_time DESC, trips.id DESC
    ''');
    return rows.map(Trip.fromMap).toList(growable: false);
  }

  Future<int> cancelTripAsAdmin(int tripId) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final updated = await db.transaction<int>((transaction) async {
      final rows = await transaction.query(
        'trips',
        columns: ['status', 'departure_date', 'departure_time', 'departure', 'destination', 'driver_id'],
        where: 'id = ?',
        whereArgs: [tripId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Trajet introuvable.');
      final row = rows.first;
      if (row['status'] != 'available') {
        throw StateError('Ce trajet ne peut plus être annulé.');
      }
      final date = DateTime.tryParse('${row['departure_date']} ${row['departure_time']}');
      if (date == null || !date.isAfter(now)) {
        throw StateError('Seuls les trajets à venir peuvent être annulés.');
      }
      final count = await transaction.update(
        'trips',
        {'status': 'cancelled', 'updated_at': nowIso},
        where: "id = ? AND status = 'available'",
        whereArgs: [tripId],
      );
      if (count != 1) throw StateError('Le trajet a été modifié entre-temps.');
      final passengers = await transaction.query(
        'bookings',
        columns: ['passenger_id'],
        where: 'trip_id = ? AND status IN (?, ?)',
        whereArgs: [tripId, 'pending', 'accepted'],
      );
      final route = '${row['departure']} → ${row['destination']}';
      for (final booking in passengers) {
        await NotificationRepository.insertInTransaction(
          transaction: transaction,
          userId: booking['passenger_id'] as int,
          title: 'Trajet annulé',
          body: 'Le trajet $route a été annulé par l’administration.',
          type: 'trip:$tripId;cancelled',
          createdAt: nowIso,
        );
      }
      return count;
    });
    NotificationRepository.notifyChanged();
    return updated;
  }

  Future<List<Trip>> searchAvailableTrips({
    required int passengerId,
    String? departure,
    String? destination,
    String? departureDate,
    String? departureTime,
    int seats = 1,
    bool flexibleTime = false,
    bool verifiedDriversOnly = false,
    double? maxPrice,
    TripSort sort = TripSort.earliest,
  }) async {
    final db = await _databaseHelper.database;
    final where = <String>[
      'trips.available_seats >= ?',
      "trips.status = 'available'",
      'drivers.is_active = 1',
      'trips.driver_id != ?',
    ];
    final whereArgs = <Object?>[seats < 1 ? 1 : seats, passengerId];

    final departureFilter = departure?.trim();
    if (departureFilter != null && departureFilter.isNotEmpty) {
      where.add('trips.departure = ?');
      whereArgs.add(departureFilter);
    }
    final destinationFilter = destination?.trim();
    if (destinationFilter != null && destinationFilter.isNotEmpty) {
      where.add('trips.destination = ?');
      whereArgs.add(destinationFilter);
    }
    final dateFilter = departureDate?.trim();
    if (dateFilter != null && dateFilter.isNotEmpty) {
      where.add('trips.departure_date = ?');
      whereArgs.add(dateFilter);
    }

    if (verifiedDriversOnly) {
      where.add('drivers.is_verified = 1');
    }
    if (maxPrice != null) {
      where.add('trips.price <= ?');
      whereArgs.add(maxPrice);
    }

    final orderBy = switch (sort) {
      TripSort.earliest => 'trips.departure_time ASC',
      TripSort.cheapest => 'trips.price ASC, trips.departure_time ASC',
      TripSort.bestRated => 'driver_rating DESC, trips.departure_time ASC',
    };

    final rows = await db.rawQuery('''
      SELECT
        trips.id,
        trips.departure,
        trips.destination,
        trips.departure_date,
        trips.departure_time,
        trips.driver_id,
        trips.vehicle_id,
        trips.total_seats,
        trips.available_seats,
        trips.price,
        trips.meeting_point,
        trips.description,
        trips.status,
        trips.created_at,
        trips.updated_at,
        drivers.full_name AS driver_name,
        drivers.is_verified AS driver_is_verified,
        drivers.profile_image AS driver_profile_image,
        AVG(ratings.score) AS driver_rating
      FROM trips
      INNER JOIN users AS drivers ON drivers.id = trips.driver_id
      LEFT JOIN ratings ON ratings.reviewed_id = drivers.id
      WHERE ${where.join(' AND ')}
      GROUP BY trips.id
      ORDER BY $orderBy
    ''', whereArgs);

    final timeFilter = departureTime?.trim();
    final requestedMinutes = timeFilter == null || timeFilter.isEmpty
        ? null
        : _minutesFromTime(timeFilter);
    return rows
        .map(Trip.fromMap)
        .where((trip) {
          if (requestedMinutes == null) return true;
          final tripMinutes = _minutesFromTime(trip.departureTime);
          final difference = tripMinutes - requestedMinutes;
          return flexibleTime ? difference.abs() <= 60 : difference >= 0;
        })
        .toList(growable: false);
  }

  Future<List<Trip>> getTripsForDriver(int driverId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        trips.id,
        trips.driver_id,
        trips.vehicle_id,
        trips.departure,
        trips.destination,
        trips.departure_date,
        trips.departure_time,
        trips.total_seats,
        trips.available_seats,
        trips.price,
        trips.meeting_point,
        trips.description,
        trips.status,
        trips.created_at,
        trips.updated_at,
        COALESCE((
          SELECT SUM(bookings.seats_reserved)
          FROM bookings
          WHERE bookings.trip_id = trips.id
            AND bookings.status = 'pending'
        ), 0) AS pending_requests
      FROM trips
      WHERE trips.driver_id = ?
      ORDER BY trips.departure_date ASC, trips.departure_time ASC,
        trips.id DESC
    ''', [driverId]);

    return rows.map(Trip.fromMap).toList(growable: false);
  }

  Future<TripDetails?> getTripDetails(int tripId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        trips.id,
        trips.driver_id,
        trips.departure,
        trips.destination,
        trips.departure_date,
        trips.departure_time,
        trips.total_seats,
        trips.available_seats,
        trips.price,
        trips.meeting_point,
        trips.description,
        trips.status,
        drivers.full_name AS driver_name,
        drivers.is_verified AS driver_is_verified,
        drivers.profile_image AS driver_profile_image,
        vehicles.brand AS vehicle_brand,
        vehicles.model AS vehicle_model,
        vehicles.color AS vehicle_color,
        vehicles.seats AS vehicle_seats,
        (
          SELECT AVG(ratings.score)
          FROM ratings
          WHERE ratings.reviewed_id = drivers.id
        ) AS driver_rating,
        (
          SELECT COUNT(*)
          FROM ratings
          WHERE ratings.reviewed_id = drivers.id
        ) AS review_count
      FROM trips
      INNER JOIN users AS drivers
        ON drivers.id = trips.driver_id AND drivers.role = 'driver'
      INNER JOIN vehicles
        ON vehicles.id = trips.vehicle_id AND vehicles.user_id = trips.driver_id
      WHERE trips.id = ?
      LIMIT 1
    ''', [tripId]);

    if (rows.isEmpty) return null;
    return TripDetails.fromMap(rows.first);
  }

  Future<TripDetails?> getDriverTripDetails({
    required int tripId,
    required int driverId,
  }) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        trips.id,
        trips.driver_id,
        trips.departure,
        trips.destination,
        trips.departure_date,
        trips.departure_time,
        trips.total_seats,
        trips.available_seats,
        trips.price,
        trips.meeting_point,
        trips.description,
        trips.status,
        drivers.full_name AS driver_name,
        drivers.is_verified AS driver_is_verified,
        drivers.profile_image AS driver_profile_image,
        vehicles.brand AS vehicle_brand,
        vehicles.model AS vehicle_model,
        vehicles.color AS vehicle_color,
        vehicles.seats AS vehicle_seats,
        (
          SELECT AVG(ratings.score)
          FROM ratings
          WHERE ratings.reviewed_id = drivers.id
        ) AS driver_rating,
        (
          SELECT COUNT(*)
          FROM ratings
          WHERE ratings.reviewed_id = drivers.id
        ) AS review_count,
        (
          SELECT COUNT(*)
          FROM bookings
          WHERE bookings.trip_id = trips.id AND bookings.status = 'pending'
        ) AS pending_requests
      FROM trips
      INNER JOIN users AS drivers
        ON drivers.id = trips.driver_id AND drivers.role = 'driver'
      INNER JOIN vehicles
        ON vehicles.id = trips.vehicle_id AND vehicles.user_id = trips.driver_id
      WHERE trips.id = ? AND trips.driver_id = ?
      LIMIT 1
    ''', [tripId, driverId]);

    if (rows.isEmpty) return null;
    return TripDetails.fromMap(rows.first);
  }

  Future<void> createBooking({
    required int tripId,
    required int passengerId,
    required int seatsReserved,
  }) async {
    if (seatsReserved < 1) {
      throw ArgumentError.value(seatsReserved, 'seatsReserved');
    }

    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((transaction) async {
      final passengerRows = await transaction.query(
        'users',
        columns: ['id', 'role', 'is_active'],
        where: 'id = ?',
        whereArgs: [passengerId],
        limit: 1,
      );
      if (passengerRows.isEmpty ||
          passengerRows.first['role'] != 'passenger' ||
          passengerRows.first['is_active'] != 1) {
        throw StateError('Passenger account is not valid.');
      }

      final tripRows = await transaction.query(
        'trips',
        columns: ['driver_id', 'departure', 'destination', 'available_seats', 'status'],
        where: 'id = ?',
        whereArgs: [tripId],
        limit: 1,
      );
      if (tripRows.isEmpty) throw StateError('Trip not found.');
      final trip = tripRows.first;
      if (trip['driver_id'] == passengerId) {
        throw StateError('A driver cannot book their own trip.');
      }
      if (trip['status'] != 'available') {
        throw StateError('Trip is not available.');
      }

      final duplicateRows = await transaction.query(
        'bookings',
        columns: ['id'],
        where: 'trip_id = ? AND passenger_id = ? AND status IN (?, ?)',
        whereArgs: [tripId, passengerId, 'pending', 'accepted'],
        limit: 1,
      );
      if (duplicateRows.isNotEmpty) {
        throw StateError('A booking already exists for this passenger.');
      }

      final availableSeats = trip['available_seats'] as int;
      if (seatsReserved > availableSeats) {
        throw StateError('Not enough seats are available.');
      }

      final booking = Booking(
        tripId: tripId,
        passengerId: passengerId,
        seatsReserved: seatsReserved,
        createdAt: now,
        updatedAt: now,
      );
      final bookingId = await transaction.insert('bookings', booking.toMap());
      final updatedTrips = await transaction.update(
        'trips',
        {
          'available_seats': availableSeats - seatsReserved,
          'updated_at': now,
        },
        where: 'id = ? AND status = ? AND available_seats >= ?',
        whereArgs: [tripId, 'available', seatsReserved],
      );
      if (updatedTrips != 1) {
        throw StateError('Trip availability changed during booking.');
      }
      final driverId = trip['driver_id'] as int;
      await NotificationRepository.insertInTransaction(
        transaction: transaction,
        userId: driverId,
        title: 'Nouvelle demande de réservation',
        body: 'Un passager a demandé $seatsReserved place(s) pour votre trajet '
            '${trip['departure']} → ${trip['destination']}.',
        type: 'booking:$bookingId;trip:$tripId',
        createdAt: now,
      );
    });
    NotificationRepository.notifyChanged();
  }

  Future<int> createTrip(Trip trip) async {
    final db = await _databaseHelper.database;

    return db.transaction<int>((transaction) async {
      final drivers = await transaction.query(
        'users',
        columns: ['id'],
        where: "id = ? AND role = 'driver' AND is_active = 1",
        whereArgs: [trip.driverId],
        limit: 1,
      );
      if (drivers.isEmpty) {
        throw StateError('The authenticated user is not an active driver.');
      }

      final vehicles = await transaction.query(
        'vehicles',
        columns: ['id'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [trip.vehicleId, trip.driverId],
        limit: 1,
      );
      if (vehicles.isEmpty) {
        throw StateError('The selected vehicle does not belong to driver.');
      }

      return transaction.insert(
        'trips',
        trip.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  Future<int> updateTrip({
    required int tripId,
    required int driverId,
    required String departure,
    required String destination,
    required String departureDate,
    required String departureTime,
    required int totalSeats,
    required int availableSeats,
    required double price,
    required String meetingPoint,
    required String description,
    required int vehicleId,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    return db.transaction<int>((transaction) async {
      final vehicles = await transaction.query(
        'vehicles',
        columns: ['id', 'user_id', 'seats'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [vehicleId, driverId],
        limit: 1,
      );
      if (vehicles.isEmpty) {
        throw StateError('The selected vehicle does not belong to driver.');
      }

      final trip = await transaction.query(
        'trips',
        columns: ['id', 'total_seats', 'available_seats', 'status', 'driver_id'],
        where: 'id = ? AND driver_id = ?',
        whereArgs: [tripId, driverId],
        limit: 1,
      );
      if (trip.isEmpty) {
        throw StateError('The trip does not belong to driver.');
      }

      final existing = trip.first;
      if ((existing['status'] as String? ?? 'available') != 'available') {
        throw StateError('Only upcoming trips can be edited.');
      }

      final bookedSeats = await _bookedSeats(transaction, tripId);
      if (totalSeats < bookedSeats) {
        throw StateError('The seats cannot be lower than current reservations.');
      }

      final vehicleSeats = vehicles.first['seats'] as int;
      if (totalSeats > vehicleSeats) {
        throw StateError('The trip seats exceed the vehicle capacity.');
      }

      final usedSeats = totalSeats - availableSeats;
      if (usedSeats < 0 || usedSeats > totalSeats) {
        throw StateError('The available seats are invalid.');
      }
      if (usedSeats < bookedSeats) {
        throw StateError('The available seats cannot be lower than current reservations.');
      }

      return transaction.update(
        'trips',
        {
          'vehicle_id': vehicleId,
          'departure': departure.trim(),
          'destination': destination.trim(),
          'departure_date': departureDate,
          'departure_time': departureTime,
          'total_seats': totalSeats,
          'available_seats': availableSeats,
          'price': price,
          'meeting_point': meetingPoint.trim(),
          'description': description.trim().isEmpty ? null : description.trim(),
          'updated_at': now,
        },
        where: 'id = ? AND driver_id = ?',
        whereArgs: [tripId, driverId],
      );
    });
  }

  Future<int> cancelTrip({
    required int tripId,
    required int driverId,
  }) async {
    final db = await _databaseHelper.database;
    return db.update(
      'trips',
      {
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND driver_id = ? AND status = ?',
      whereArgs: [tripId, driverId, 'available'],
    );
  }

  Future<int> _bookedSeats(
    Transaction transaction,
    int tripId,
  ) async {
    final bookingRows = await transaction.rawQuery(
      'SELECT COALESCE(SUM(seats_reserved), 0) AS booked_seats '
      'FROM bookings '
      'WHERE trip_id = ? AND status = ?',
      [tripId, 'pending'],
    );
    return bookingRows.first['booked_seats'] as int? ?? 0;
  }

  int _minutesFromTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      return 0;
    }

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }
}
