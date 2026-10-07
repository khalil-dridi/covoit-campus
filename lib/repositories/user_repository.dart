import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/user.dart';

class UserRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> registerUser(User user) async {
    final db = await _databaseHelper.database;

    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<User?> loginUser(
    String email,
    String passwordHash,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [email, passwordHash],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return User.fromMap(result.first);
  }

  Future<User?> findUserByEmail(String email) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return User.fromMap(result.first);
  }

  Future<User?> getUserById(int userId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isEmpty ? null : User.fromMap(result.first);
  }

  Future<User?> getActiveUserById(int userId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'users',
      where: 'id = ? AND is_active = 1',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isEmpty ? null : User.fromMap(result.first);
  }

  Future<bool> changeAdminPassword({
    required int userId,
    required String currentPasswordHash,
    required String newPasswordHash,
  }) async {
    final db = await _databaseHelper.database;
    final changed = await db.update(
      'users',
      {
        'password_hash': newPasswordHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND role = ? AND is_active = 1 AND password_hash = ?',
      whereArgs: [userId, 'admin', currentPasswordHash],
    );
    return changed == 1;
  }

  Future<int> verifyUser(int userId) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'users',
      {
        'is_verified': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUserProfile({
    required int userId,
    required String fullName,
    String? phone,
    String? university,
  }) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'users',
      {
        'full_name': fullName.trim(),
        'phone': phone?.trim().isNotEmpty == true
            ? phone!.trim()
            : null,
        'university': university?.trim().isNotEmpty == true
            ? university!.trim()
            : null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateAdminProfile({
    required int userId,
    required String fullName,
    String? phone,
    String? university,
  }) async {
    final db = await _databaseHelper.database;
    return db.update(
      'users',
      {
        'full_name': fullName.trim(),
        'phone': phone?.trim().isNotEmpty == true
            ? phone!.trim()
            : null,
        'university': university?.trim().isNotEmpty == true
            ? university!.trim()
            : null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND role = ? AND is_active = 1',
      whereArgs: [userId, 'admin'],
    );
  }

  Future<int> updateUserRole(int userId, String role) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'users',
      {
        'role': role,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'users',
      orderBy: 'created_at DESC, id DESC',
    );

    return result.map(User.fromMap).toList(growable: false);
  }

  Future<int> setUserActiveStatus(
    int userId,
    bool isActive, {
    int? adminId,
  }) async {
    if (adminId != null && userId == adminId && !isActive) {
      throw StateError(
        'Un administrateur ne peut pas désactiver son propre compte.',
      );
    }

    final db = await _databaseHelper.database;

    return await db.update(
      'users',
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<AdminUserStats> getAdminUserStats() async {
    final db = await _databaseHelper.database;

    final results = await Future.wait<int>([
      _count(db, 'SELECT COUNT(*) FROM users'),
      _count(db, "SELECT COUNT(*) FROM users WHERE role = 'passenger'"),
      _count(db, "SELECT COUNT(*) FROM users WHERE role = 'driver'"),
      _count(db, 'SELECT COUNT(*) FROM users WHERE is_active = 1'),
      _count(db, 'SELECT COUNT(*) FROM users WHERE is_verified = 0'),
    ]);

    return AdminUserStats(
      totalUsers: results[0],
      passengerCount: results[1],
      driverCount: results[2],
      activeCount: results[3],
      unverifiedCount: results[4],
    );
  }

  Future<Map<String, int>> getUserActivityCounts(int userId) async {
    final db = await _databaseHelper.database;

    final results = await Future.wait<int>([
      _countWithArgs(
        db,
        'SELECT COUNT(*) FROM vehicles WHERE user_id = ?',
        [userId],
      ),
      _countWithArgs(
        db,
        'SELECT COUNT(*) FROM trips WHERE driver_id = ?',
        [userId],
      ),
      _countWithArgs(
        db,
        'SELECT COUNT(*) FROM bookings WHERE passenger_id = ?',
        [userId],
      ),
    ]);

    return {
      'vehicles': results[0],
      'trips': results[1],
      'bookings': results[2],
    };
  }

  Future<int> _count(Database db, String sql) async {
    final rows = await db.rawQuery(sql);
    final value = rows.first.values.first;
    return value == null ? 0 : (value as int);
  }

  Future<int> _countWithArgs(
    Database db,
    String sql,
    List<Object?> args,
  ) async {
    final rows = await db.rawQuery(sql, args);
    final value = rows.first.values.first;
    return value == null ? 0 : (value as int);
  }
}

class AdminUserStats {
  final int totalUsers;
  final int passengerCount;
  final int driverCount;
  final int activeCount;
  final int unverifiedCount;

  const AdminUserStats({
    required this.totalUsers,
    required this.passengerCount,
    required this.driverCount,
    required this.activeCount,
    required this.unverifiedCount,
  });
}
