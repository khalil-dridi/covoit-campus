import '../database/database_helper.dart';
import '../models/trip.dart';
import 'package:sqflite/sqflite.dart';

enum TripSort { earliest, cheapest, bestRated }

class TripRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Trip>> searchAvailableTrips({
    required int passengerId,
    required String departure,
    required String destination,
    required String departureDate,
    required String departureTime,
    required int seats,
    required bool flexibleTime,
    required bool verifiedDriversOnly,
    double? maxPrice,
    TripSort sort = TripSort.earliest,
  }) async {
    final db = await _databaseHelper.database;
    final where = <String>[
      'trips.departure = ?',
      'trips.destination = ?',
      'trips.departure_date = ?',
      'trips.available_seats >= ?',
      "trips.status = 'available'",
      'drivers.is_active = 1',
      'trips.driver_id != ?',
    ];
    final whereArgs = <Object?>[
      departure,
      destination,
      departureDate,
      seats,
      passengerId,
    ];

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

    final requestedMinutes = _minutesFromTime(departureTime);
    return rows
        .map(Trip.fromMap)
        .where((trip) {
          final tripMinutes = _minutesFromTime(trip.departureTime);
          final difference = tripMinutes - requestedMinutes;
          return flexibleTime ? difference.abs() <= 60 : difference >= 0;
        })
        .toList(growable: false);
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