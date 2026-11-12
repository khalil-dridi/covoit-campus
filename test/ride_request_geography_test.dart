import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/models/ride_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'ride request coordinates round trip and legacy maps remain readable',
    () {
      final request = RideRequest(
        passengerId: 4,
        departure: 'Tunis, Tunisie',
        destination: 'Sousse, Tunisie',
        departureLatitude: 36.8065,
        departureLongitude: 10.1815,
        destinationLatitude: 35.8256,
        destinationLongitude: 10.6084,
        requestDate: '2026-12-01',
        seatsRequested: 1,
        createdAt: '2026-11-01T00:00:00.000',
        updatedAt: '2026-11-01T00:00:00.000',
      );

      final decoded = RideRequest.fromMap({'id': 1, ...request.toMap()});
      expect(decoded.departureLatitude, 36.8065);
      expect(decoded.departureLongitude, 10.1815);
      expect(decoded.destinationLatitude, 35.8256);
      expect(decoded.destinationLongitude, 10.6084);

      final legacy = RideRequest.fromMap({
        'id': 2,
        'passenger_id': 4,
        'departure': 'Tunis',
        'destination': 'Sousse',
        'request_date': '2026-12-01',
        'seats_requested': 1,
        'created_at': '2026-11-01T00:00:00.000',
        'updated_at': '2026-11-01T00:00:00.000',
      });
      expect(legacy.departureLatitude, isNull);
      expect(legacy.destinationLongitude, isNull);
    },
  );

  test('coordinate migration preserves existing ride requests', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('''
      CREATE TABLE ride_requests (
        id INTEGER PRIMARY KEY,
        passenger_id INTEGER NOT NULL,
        departure TEXT NOT NULL,
        destination TEXT NOT NULL,
        request_date TEXT NOT NULL,
        request_time TEXT,
        seats_requested INTEGER NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.insert('ride_requests', {
      'id': 8,
      'passenger_id': 4,
      'departure': 'Tunis',
      'destination': 'Sousse',
      'request_date': '2026-12-01',
      'seats_requested': 1,
      'status': 'active',
      'created_at': '2026-11-01',
      'updated_at': '2026-11-01',
    });

    await DatabaseHelper.migrateRideRequestCoordinates(db);

    final row = (await db.query('ride_requests')).single;
    expect(row['departure'], 'Tunis');
    expect(row['destination'], 'Sousse');
    expect(row['departure_latitude'], isNull);
    expect(row['destination_longitude'], isNull);
  });
}
