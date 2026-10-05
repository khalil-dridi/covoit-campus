import '../database/database_helper.dart';
import '../models/vehicle.dart';

class VehicleRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<Vehicle?> getVehicleForUser(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'vehicles',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: 1,
    );

    return rows.isEmpty ? null : Vehicle.fromMap(rows.first);
  }

  Future<List<Vehicle>> getVehiclesForUser(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'vehicles',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(Vehicle.fromMap).toList(growable: false);
  }

  Future<int> createVehicle(Vehicle vehicle) async {
    final db = await _databaseHelper.database;
    return db.insert('vehicles', vehicle.toMap());
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await _databaseHelper.database;
    return db.update(
      'vehicles',
      vehicle.toMap()..remove('user_id'),
      where: 'id = ? AND user_id = ?',
      whereArgs: [vehicle.id, vehicle.userId],
    );
  }

  Future<int> deleteVehicle(int vehicleId, int userId) async {
    final db = await _databaseHelper.database;
    final linkedTrips = await db.rawQuery(
      'SELECT COUNT(*) AS trip_count FROM trips WHERE vehicle_id = ?',
      [vehicleId],
    );
    if ((linkedTrips.first['trip_count'] as int? ?? 0) > 0) {
      throw StateError('Vehicle is linked to existing trips.');
    }

    return db.delete(
      'vehicles',
      where: 'id = ? AND user_id = ?',
      whereArgs: [vehicleId, userId],
    );
  }
}