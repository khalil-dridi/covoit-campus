import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('v6 users and foreign-key data survive Firebase migration', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
    addTearDown(db.close);

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        phone TEXT,
        profile_image TEXT,
        university TEXT,
        role TEXT NOT NULL DEFAULT 'passenger',
        is_verified INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        color TEXT,
        license_plate TEXT NOT NULL,
        seats INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.insert('users', {
      'id': 41,
      'full_name': 'Conducteur existant',
      'email': 'driver@example.tn',
      'password_hash': 'legacy-hash',
      'role': 'driver',
      'is_verified': 1,
      'is_active': 1,
      'created_at': '2025-01-01T00:00:00.000',
      'updated_at': '2025-01-02T00:00:00.000',
    });
    await db.insert('vehicles', {
      'id': 77,
      'user_id': 41,
      'brand': 'Campus',
      'model': 'One',
      'license_plate': 'TEST-41',
      'seats': 4,
      'created_at': '2025-01-02T00:00:00.000',
    });

    await DatabaseHelper.migrateUsersForFirebase(db);

    final migrated = (await db.query('users', where: 'id = 41')).single;
    expect(migrated['email'], 'driver@example.tn');
    expect(migrated['password_hash'], 'legacy-hash');
    expect(migrated['role'], 'driver');
    expect(migrated['firebase_uid'], isNull);
    expect(
      (await db.query('vehicles', where: 'id = 77')).single['user_id'],
      41,
    );
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    await db.update('users', {
      'firebase_uid': 'firebase-user-41',
    }, where: 'id = 41');

    await expectLater(
      db.insert('users', {
        'full_name': 'Autre profil',
        'email': 'other@example.tn',
        'password_hash': 'another-hash',
        'firebase_uid': 'firebase-user-41',
        'role': 'passenger',
        'created_at': '2025-01-03T00:00:00.000',
        'updated_at': '2025-01-03T00:00:00.000',
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
