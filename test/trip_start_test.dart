import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/repositories/notification_repository.dart';
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
    'trip lifecycle notification types expose the trip ID for navigation',
    () {
      expect(
        NotificationRepository.tripLifecycleIdFromType('trip_started:42'),
        42,
      );
      expect(
        NotificationRepository.tripLifecycleIdFromType('trip_completed:77'),
        77,
      );
      expect(
        NotificationRepository.tripLifecycleIdFromType('booking:5;trip:42'),
        isNull,
      );
    },
  );

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
      await _createNotificationTables(db);
      await db.insert('trips', {
        'id': 9,
        'driver_id': 12,
        'status': 'available',
      });
      await _insertBookings(db, tripId: 9);
      final startTime = DateTime.utc(2026, 11, 11, 10);

      expect(
        await db.transaction(
          (transaction) => TripRepository.markTripStarted(
            transaction,
            tripId: 9,
            driverId: 99,
            latitude: 36.8,
            longitude: 10.1,
            startedAt: startTime,
          ),
        ),
        0,
      );
      expect(
        await db.transaction(
          (transaction) => TripRepository.markTripStarted(
            transaction,
            tripId: 9,
            driverId: 12,
            latitude: 36.8065,
            longitude: 10.1815,
            startedAt: startTime,
          ),
        ),
        1,
      );
      expect(
        await db.transaction(
          (transaction) => TripRepository.markTripStarted(
            transaction,
            tripId: 9,
            driverId: 12,
            latitude: 36.8,
            longitude: 10.1,
            startedAt: DateTime.now(),
          ),
        ),
        0,
      );

      final trip = (await db.query('trips', where: 'id = 9')).single;
      expect(trip['status'], 'in_progress');
      expect(trip['start_latitude'], 36.8065);
      expect(trip['start_longitude'], 10.1815);
      expect(trip['actual_start_time'], startTime.toIso8601String());
      final notifications = await db.query('notifications');
      expect(notifications, hasLength(2));
      expect(
        notifications.map((notification) => notification['user_id']).toSet(),
        {21, 22},
      );
      expect(
        notifications.map((notification) => notification['title']).toSet(),
        {'Trajet commencé'},
      );
      expect(
        notifications.map((notification) => notification['body']).toSet(),
        {'Votre conducteur a commencé le trajet. Consultez les détails.'},
      );
      expect(
        notifications.map((notification) => notification['type']).toSet(),
        {'trip_started:9'},
      );
    },
  );

  test('completion notifies distinct accepted passengers only once', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY,
        driver_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await _createNotificationTables(db);
    await db.insert('trips', {
      'id': 5,
      'driver_id': 12,
      'status': 'in_progress',
    });
    await _insertBookings(db, tripId: 5);

    expect(
      await db.transaction(
        (transaction) => TripRepository.markTripCompleted(
          transaction,
          tripId: 5,
          driverId: 12,
        ),
      ),
      1,
    );
    expect(
      await db.transaction(
        (transaction) => TripRepository.markTripCompleted(
          transaction,
          tripId: 5,
          driverId: 12,
        ),
      ),
      0,
    );

    final notifications = await db.query('notifications');
    expect(notifications, hasLength(2));
    expect(notifications.map((notification) => notification['title']).toSet(), {
      'Trajet terminé',
    });
    expect(notifications.map((notification) => notification['body']).toSet(), {
      'Votre trajet est terminé. Vous pouvez maintenant évaluer votre conducteur.',
    });
    expect(notifications.map((notification) => notification['type']).toSet(), {
      'trip_completed:5',
    });
    expect((await db.query('trips')).single['status'], 'completed');
  });
}

Future<void> _createNotificationTables(Database db) async {
  await db.execute('''
    CREATE TABLE bookings (
      id INTEGER PRIMARY KEY,
      trip_id INTEGER NOT NULL,
      passenger_id INTEGER NOT NULL,
      status TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      type TEXT,
      is_read INTEGER NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
}

Future<void> _insertBookings(Database db, {required int tripId}) async {
  await db.insert('bookings', {
    'id': tripId * 10 + 1,
    'trip_id': tripId,
    'passenger_id': 21,
    'status': 'accepted',
  });
  await db.insert('bookings', {
    'id': tripId * 10 + 2,
    'trip_id': tripId,
    'passenger_id': 21,
    'status': 'accepted',
  });
  await db.insert('bookings', {
    'id': tripId * 10 + 3,
    'trip_id': tripId,
    'passenger_id': 22,
    'status': 'accepted',
  });
  await db.insert('bookings', {
    'id': tripId * 10 + 4,
    'trip_id': tripId,
    'passenger_id': 23,
    'status': 'pending',
  });
}
