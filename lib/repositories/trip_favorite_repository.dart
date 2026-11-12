import '../database/database_helper.dart';
import '../models/trip.dart';

class TripFavoriteRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Set<int>> getFavoriteTripIds(int passengerId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'trip_favorites',
      columns: ['trip_id'],
      where: 'passenger_id = ?',
      whereArgs: [passengerId],
    );
    return rows.map((row) => row['trip_id'] as int).toSet();
  }

  Future<bool> toggleFavorite({
    required int passengerId,
    required int tripId,
  }) async {
    final db = await _databaseHelper.database;
    return db.transaction<bool>((transaction) async {
      final existing = await transaction.query(
        'trip_favorites',
        columns: ['trip_id'],
        where: 'passenger_id = ? AND trip_id = ?',
        whereArgs: [passengerId, tripId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        await transaction.delete(
          'trip_favorites',
          where: 'passenger_id = ? AND trip_id = ?',
          whereArgs: [passengerId, tripId],
        );
        return false;
      }
      await transaction.insert('trip_favorites', {
        'passenger_id': passengerId,
        'trip_id': tripId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    });
  }

  Future<List<Trip>> getFavoriteTrips(int passengerId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT trips.*, drivers.full_name AS driver_name,
        drivers.is_verified AS driver_is_verified,
        drivers.is_active AS driver_is_active,
        drivers.role AS driver_role,
        drivers.profile_image AS driver_profile_image,
        vehicles.user_id = trips.driver_id AS vehicle_belongs_to_driver,
        vehicles.brand AS vehicle_brand, vehicles.model AS vehicle_model,
        vehicles.color AS vehicle_color, vehicles.seats AS vehicle_seats,
        NULL AS driver_rating
      FROM trip_favorites
      INNER JOIN trips ON trips.id = trip_favorites.trip_id
      INNER JOIN users AS drivers ON drivers.id = trips.driver_id
      LEFT JOIN vehicles ON vehicles.id = trips.vehicle_id
      WHERE trip_favorites.passenger_id = ?
      ORDER BY trip_favorites.created_at DESC, trips.id DESC
      ''',
      [passengerId],
    );
    return rows.map(Trip.fromMap).toList(growable: false);
  }
}
