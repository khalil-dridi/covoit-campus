import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/repositories/trip_repository.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('migration adds actual start fields and is safe to repeat', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('CREATE TABLE trips (id INTEGER PRIMARY KEY)');

    await DatabaseHelper.migrateTripStartFields(db);
    await DatabaseHelper.migrateTripStartFields(db);

    final columns = (await db.rawQuery('PRAGMA table_info(trips)'))
        .map((column) => column['name'])
        .toSet();
    expect(
      columns,
      containsAll(['start_latitude', 'start_longitude', 'actual_start_time']),
    );
  });

  test(
    'only the owning driver can start once and start data is stored',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY,
        driver_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        start_latitude REAL,
        start_longitude REAL,
        actual_start_time TEXT,
        updated_at TEXT
      )
    ''');
      await db.insert('trips', {
        'id': 9,
        'driver_id': 12,
        'status': 'available',
      });
      final startTime = DateTime.utc(2026, 11, 11, 10);

      expect(
        await TripRepository.markTripStarted(
          db,
          tripId: 9,
          driverId: 99,
          latitude: 36.8,
          longitude: 10.1,
          startedAt: startTime,
        ),
        0,
      );
      expect(
        await TripRepository.markTripStarted(
          db,
          tripId: 9,
          driverId: 12,
          latitude: 36.8065,
          longitude: 10.1815,
          startedAt: startTime,
        ),
        1,
      );
      expect(
        await TripRepository.markTripStarted(
          db,
          tripId: 9,
          driverId: 12,
          latitude: 36.8,
          longitude: 10.1,
          startedAt: DateTime.now(),
        ),
        0,
      );

      final trip = (await db.query('trips', where: 'id = 9')).single;
      expect(trip['status'], 'in_progress');
      expect(trip['start_latitude'], 36.8065);
      expect(trip['start_longitude'], 10.1815);
      expect(trip['actual_start_time'], startTime.toIso8601String());
    },
  );
}
