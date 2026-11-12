import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'trip attendance migration is repeatable and preserves existing rows',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY)');
      await db.execute('CREATE TABLE trips (id INTEGER PRIMARY KEY)');
      await db.insert('users', {'id': 1});
      await db.insert('trips', {'id': 2});

      await DatabaseHelper.migrateTripAttendance(db);
      await DatabaseHelper.migrateTripAttendance(db);
      await db.insert('trip_attendance', {
        'trip_id': 2,
        'passenger_id': 1,
        'confirmed_at': '2026-01-01T00:00:00.000',
      });

      expect(await db.query('users'), hasLength(1));
      expect(await db.query('trips'), hasLength(1));
      expect(
        await db.query('trip_attendance', where: 'trip_id = ?', whereArgs: [2]),
        hasLength(1),
      );
      await expectLater(
        db.insert('trip_attendance', {
          'trip_id': 2,
          'passenger_id': 1,
          'confirmed_at': '2026-01-02T00:00:00.000',
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );
}
