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
}