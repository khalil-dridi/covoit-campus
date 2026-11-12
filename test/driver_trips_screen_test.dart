import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/models/trip.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/screens/driver/trips/driver_trips_screen.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('fr_FR');
  });

  test('sorts trips by departure and publication date in either direction', () {
    final trips = [
      _trip(1, departureDate: '2030-05-10', createdAt: '2025-04-03T12:00:00'),
      _trip(2, departureDate: '2030-05-12', createdAt: '2025-04-01T12:00:00'),
      _trip(3, departureDate: '2030-05-11', createdAt: '2025-04-02T12:00:00'),
    ];

    expect(
      sortDriverTrips(trips, DriverTripsSort.tripNewest).map((t) => t.id),
      [2, 3, 1],
    );
    expect(
      sortDriverTrips(trips, DriverTripsSort.tripOldest).map((t) => t.id),
      [1, 3, 2],
    );
    expect(
      sortDriverTrips(trips, DriverTripsSort.publishedNewest).map((t) => t.id),
      [1, 3, 2],
    );
    expect(
      sortDriverTrips(trips, DriverTripsSort.publishedOldest).map((t) => t.id),
      [2, 3, 1],
    );
  });

  testWidgets('cards open the selected trip details and tabs filter trips', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_createFixture))!;
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      MaterialApp(home: DriverTripsScreen(user: fixture.user)),
    );
    await _pumpFrames(tester);

    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('Annulés'), findsOneWidget);
    expect(find.text('Départ en cours'), findsOneWidget);
    expect(find.text('Départ disponible'), findsOneWidget);
    expect(find.text('Voir détails'), findsNothing);
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Annuler'), findsNothing);
    expect(find.text('Terminer'), findsNothing);

    await tester.tap(find.byType(DropdownButton<DriverTripsSort>));
    await _pumpFrames(tester, count: 2);
    await tester.tap(find.text('Date du trajet · plus ancien'));
    await _pumpFrames(tester, count: 3);
    await tester.tap(find.text('Départ disponible'));
    await _pumpFrames(tester);
    expect(find.text('Détails du trajet'), findsOneWidget);
    expect(find.text('Commencer le trajet'), findsOneWidget);
    expect(find.text('Terminer le trajet'), findsNothing);
    await tester.tap(find.byTooltip('Retour'));
    await _pumpFrames(tester);

    await tester.tap(find.text('Départ en cours'));
    await _pumpFrames(tester);
    expect(find.text('Détails du trajet'), findsOneWidget);
    expect(find.text('Terminer le trajet'), findsOneWidget);
    expect(find.text('Commencer le trajet'), findsNothing);
    await tester.tap(find.byTooltip('Retour'));
    await _pumpFrames(tester);

    await tester.tap(find.text('Terminé'));
    await _pumpFrames(tester, count: 4);
    expect(find.text('Départ terminé'), findsOneWidget);
    await tester.tap(find.text('Départ terminé'));
    await _pumpFrames(tester);
    expect(find.text('Détails du trajet'), findsOneWidget);
    expect(find.text('Commencer le trajet'), findsNothing);
    expect(find.text('Terminer le trajet'), findsNothing);
    await tester.tap(find.byTooltip('Retour'));
    await _pumpFrames(tester);

    await tester.tap(find.text('Annulés'));
    await _pumpFrames(tester, count: 4);
    expect(find.text('Départ annulé'), findsOneWidget);
  });
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 12}) async {
  for (var index = 0; index < count; index++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Trip _trip(
  int id, {
  required String departureDate,
  required String createdAt,
}) => Trip(
  id: id,
  driverId: 1,
  vehicleId: 1,
  departure: 'A',
  destination: 'B',
  departureDate: departureDate,
  departureTime: '09:00',
  totalSeats: 4,
  availableSeats: 2,
  price: 10,
  status: 'available',
  createdAt: createdAt,
  updatedAt: createdAt,
);

Future<_TripsFixture> _createFixture() async {
  final db = await DatabaseHelper.instance.database;
  final now = DateTime.now().toIso8601String();
  final token = DateTime.now().microsecondsSinceEpoch;
  final driverId = await db.insert('users', {
    'full_name': 'Trips Screen Driver',
    'email': 'trips-screen-$token@test.invalid',
    'password_hash': 'test-only',
    'role': 'driver',
    'is_active': 1,
    'is_verified': 1,
    'created_at': now,
    'updated_at': now,
  });
  final vehicleId = await db.insert('vehicles', {
    'user_id': driverId,
    'brand': 'Test',
    'model': 'Campus',
    'license_plate': 'TRIP-$token',
    'seats': 4,
    'created_at': now,
  });

  Future<int> addTrip({
    required String status,
    required String departure,
    required String date,
    required String createdAt,
  }) => db.insert('trips', {
    'driver_id': driverId,
    'vehicle_id': vehicleId,
    'departure': departure,
    'destination': 'Destination $departure',
    'departure_latitude': 36.8,
    'departure_longitude': 10.1,
    'arrival_latitude': 36.9,
    'arrival_longitude': 10.2,
    'departure_date': date,
    'departure_time': '09:00',
    'total_seats': 4,
    'available_seats': 2,
    'price': 10.0,
    'meeting_point': 'Point test',
    'description': null,
    'status': status,
    'created_at': createdAt,
    'updated_at': createdAt,
  });

  final upcomingDate = '2030-06-15';
  final recent = DateTime.now().toIso8601String();
  final tripIds = [
    await addTrip(
      status: 'available',
      departure: 'Départ disponible',
      date: upcomingDate,
      createdAt: recent,
    ),
    await addTrip(
      status: 'in_progress',
      departure: 'Départ en cours',
      date: '2030-06-16',
      createdAt: recent,
    ),
    await addTrip(
      status: 'completed',
      departure: 'Départ terminé',
      date: '2025-06-16',
      createdAt: recent,
    ),
    await addTrip(
      status: 'cancelled',
      departure: 'Départ annulé',
      date: upcomingDate,
      createdAt: recent,
    ),
  ];
  return _TripsFixture(
    db: db,
    user: User(
      id: driverId,
      fullName: 'Trips Screen Driver',
      email: 'trips-screen-$token@test.invalid',
      passwordHash: 'test-only',
      role: 'driver',
      createdAt: now,
      updatedAt: now,
    ),
    driverId: driverId,
    vehicleId: vehicleId,
    tripIds: tripIds,
  );
}

class _TripsFixture {
  final Database db;
  final User user;
  final int driverId;
  final int vehicleId;
  final List<int> tripIds;

  const _TripsFixture({
    required this.db,
    required this.user,
    required this.driverId,
    required this.vehicleId,
    required this.tripIds,
  });

  Future<void> dispose() async {
    await db.delete(
      'bookings',
      where: 'trip_id IN (${List.filled(tripIds.length, '?').join(',')})',
      whereArgs: tripIds,
    );
    await db.delete(
      'trips',
      where: 'id IN (${List.filled(tripIds.length, '?').join(',')})',
      whereArgs: tripIds,
    );
    await db.delete('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
    await db.delete('users', where: 'id = ?', whereArgs: [driverId]);
  }
}
