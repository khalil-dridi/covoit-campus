import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/repositories/user_repository.dart';
import 'package:covoit_campus/utils/password_hasher.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('admin profile edits preserve protected role and email', () async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    final unique = DateTime.now().microsecondsSinceEpoch;
    final id = await db.insert(
      'users',
      User(
        fullName: 'Profile Admin',
        email: 'profile-admin-$unique@covoitcampus.tn',
        passwordHash: 'unchanged-hash',
        role: 'admin',
        isVerified: true,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );
    addTearDown(() => db.delete('users', where: 'id = ?', whereArgs: [id]));

    final repository = UserRepository();
    expect(
      await repository.updateAdminProfile(
        userId: id,
        fullName: 'Updated Admin',
        phone: '55512345',
        university: 'Campus University',
      ),
      1,
    );
    final updated = await repository.getUserById(id);
    expect(updated?.fullName, 'Updated Admin');
    expect(updated?.phone, '55512345');
    expect(updated?.university, 'Campus University');
    expect(updated?.role, 'admin');
    expect(updated?.email, 'profile-admin-$unique@covoitcampus.tn');

    expect(
      await repository.changeAdminPassword(
        userId: id,
        currentPasswordHash: hashPassword('wrong password'),
        newPasswordHash: hashPassword('Newpass123'),
      ),
      isFalse,
    );
    expect(
      await repository.changeAdminPassword(
        userId: id,
        currentPasswordHash: 'unchanged-hash',
        newPasswordHash: hashPassword('Newpass123'),
      ),
      isTrue,
    );
    expect(
      (await repository.getUserById(id))?.passwordHash,
      hashPassword('Newpass123'),
    );
    expect(
      await repository.loginUser(
        'profile-admin-$unique@covoitcampus.tn',
        hashPassword('Newpass123'),
      ),
      isNotNull,
    );
  });

  test('admin profile update cannot modify non-admin accounts', () async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    final unique = DateTime.now().microsecondsSinceEpoch;
    final id = await db.insert(
      'users',
      User(
        fullName: 'Regular User',
        email: 'profile-user-$unique@covoitcampus.tn',
        passwordHash: 'unchanged-hash',
        role: 'passenger',
        createdAt: now,
        updatedAt: now,
      ).toMap(),
    );
    addTearDown(() => db.delete('users', where: 'id = ?', whereArgs: [id]));

    expect(
      await UserRepository().updateAdminProfile(
        userId: id,
        fullName: 'Changed Name',
      ),
      0,
    );
    expect((await UserRepository().getUserById(id))?.fullName, 'Regular User');
  });
}
