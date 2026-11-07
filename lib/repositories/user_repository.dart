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

  Future<User?> loginUser(String email, String passwordHash) async {
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
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return User.fromMap(result.first);
  }

  Future<User?> findUserByFirebaseUid(String firebaseUid) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'users',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
      limit: 1,
    );
    return result.isEmpty ? null : User.fromMap(result.first);
  }

  Future<User> linkFirebaseUidToVerifiedAccount({
    required int userId,
    required String email,
    required String passwordHash,
    required String firebaseUid,
    required bool emailVerified,
  }) async {
    final db = await _databaseHelper.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const UserProfileConflictException(
          UserProfileConflictReason.accountChanged,
        );
      }

      final current = User.fromMap(rows.first);
      if (current.email.trim().toLowerCase() != email.trim().toLowerCase() ||
          current.passwordHash != passwordHash ||
          passwordHash.isEmpty) {
        throw const UserProfileConflictException(
          UserProfileConflictReason.invalidProof,
        );
      }
      if (!current.isActive) {
        throw const UserProfileConflictException(
          UserProfileConflictReason.inactive,
        );
      }
      if (current.firebaseUid != null && current.firebaseUid != firebaseUid) {
        throw const UserProfileConflictException(
          UserProfileConflictReason.uidAlreadyLinked,
        );
      }

      final otherRows = await txn.query(
        'users',
        columns: ['id'],
        where: 'firebase_uid = ? AND id != ?',
        whereArgs: [firebaseUid, userId],
        limit: 1,
      );
      if (otherRows.isNotEmpty) {
        throw const UserProfileConflictException(
          UserProfileConflictReason.uidAlreadyLinked,
        );
      }

      final updates = <String, Object?>{
        'firebase_uid': firebaseUid,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (emailVerified) updates['is_verified'] = 1;
      await txn.update('users', updates, where: 'id = ?', whereArgs: [userId]);

      final linkedRows = await txn.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      return User.fromMap(linkedRows.single);
    });
  }

  Future<User> registerGoogleUser({
    required String fullName,
    required String email,
    required String? profileImage,
    required String firebaseUid,
    required String role,
    required bool emailVerified,
  }) async {
    if (role != 'passenger' && role != 'driver') {
      throw ArgumentError.value(role, 'role', 'Rôle Google non autorisé.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    final now = DateTime.now().toIso8601String();
    final user = User(
      fullName: fullName.trim(),
      email: normalizedEmail,
      // Google-only profiles cannot use the legacy local password flow.
      passwordHash: '',
      firebaseUid: firebaseUid,
      profileImage: profileImage,
      role: role,
      isVerified: emailVerified,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final db = await _databaseHelper.database;
    return db.transaction((txn) async {
      final uidRows = await txn.query(
        'users',
        columns: ['id'],
        where: 'firebase_uid = ?',
        whereArgs: [firebaseUid],
        limit: 1,
      );
      if (uidRows.isNotEmpty) {
        throw const UserProfileConflictException(
          UserProfileConflictReason.uidAlreadyLinked,
        );
      }
      final emailRows = await txn.query(
        'users',
        columns: ['id'],
        where: 'LOWER(email) = ?',
        whereArgs: [normalizedEmail],
        limit: 1,
      );
      if (emailRows.isNotEmpty) {
        throw const UserProfileConflictException(
          UserProfileConflictReason.emailAlreadyExists,
        );
      }
      final id = await txn.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      final insertedRows = await txn.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return User.fromMap(insertedRows.single);
    });
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
      {'is_verified': 1, 'updated_at': DateTime.now().toIso8601String()},
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
        'phone': phone?.trim().isNotEmpty == true ? phone!.trim() : null,
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
        'phone': phone?.trim().isNotEmpty == true ? phone!.trim() : null,
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
      {'role': role, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await _databaseHelper.database;

    final result = await db.query('users', orderBy: 'created_at DESC, id DESC');

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
      _countWithArgs(db, 'SELECT COUNT(*) FROM vehicles WHERE user_id = ?', [
        userId,
      ]),
      _countWithArgs(db, 'SELECT COUNT(*) FROM trips WHERE driver_id = ?', [
        userId,
      ]),
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

enum UserProfileConflictReason {
  accountChanged,
  invalidProof,
  inactive,
  uidAlreadyLinked,
  emailAlreadyExists,
}

class UserProfileConflictException implements Exception {
  final UserProfileConflictReason reason;

  const UserProfileConflictException(this.reason);
}
