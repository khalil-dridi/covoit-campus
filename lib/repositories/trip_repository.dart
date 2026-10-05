import '../database/database_helper.dart';
import '../models/trip.dart';

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
        trips.available_seats,
        trips.price,
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