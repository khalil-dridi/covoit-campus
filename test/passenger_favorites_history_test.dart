import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/repositories/booking_repository.dart';
import 'package:covoit_campus/repositories/trip_favorite_repository.dart';
import 'package:covoit_campus/screens/passenger/trips/passenger_favorites_screen.dart';
import 'package:covoit_campus/screens/passenger/trips/passenger_history_screen.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('fr_FR');
  });

  test(
    'favorites toggle once, isolate by passenger, and persist in SQLite',
    () async {
      final fixture = await _createFixture();
      addTearDown(fixture.dispose);
      final repository = TripFavoriteRepository();

      expect(await repository.getFavoriteTripIds(fixture.passengerId), isEmpty);
      expect(
        await repository.toggleFavorite(
          passengerId: fixture.passengerId,
          tripId: fixture.tripId,
        ),
        isTrue,
      );
      expect(await repository.getFavoriteTripIds(fixture.passengerId), {
        fixture.tripId,
      });
      expect(
        await repository.getFavoriteTripIds(fixture.otherPassengerId),
        isEmpty,
      );

      final rows = await fixture.db.query('trip_favorites');
      expect(rows, hasLength(1));
      expect(
        (await repository.getFavoriteTrips(fixture.passengerId))
            .single
            .departure,
        'Campus',
      );
      expect(
        await repository.toggleFavorite(
          passengerId: fixture.passengerId,
          tripId: fixture.tripId,
        ),
        isFalse,
      );
      expect(await repository.getFavoriteTripIds(fixture.passengerId), isEmpty);
      await repository.toggleFavorite(
        passengerId: fixture.passengerId,
        tripId: fixture.tripId,
      );
      expect(await fixture.db.query('trip_favorites'), hasLength(1));
    },
  );

  testWidgets('favorites screen shows and removes a saved trip, back returns', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_createFixture))!;
    // Database-backed widget tests need the platform work to run outside fake time.
    addTearDown(fixture.dispose);
    await tester.runAsync(
      () => TripFavoriteRepository().toggleFavorite(
        passengerId: fixture.passengerId,
        tripId: fixture.tripId,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PassengerFavoritesScreen(user: fixture.passenger),
                ),
              ),
              child: const Text('Accueil test'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Accueil test'));
    await _pump(tester);
    expect(find.text('Campus → Centre'), findsOneWidget);
    expect(find.text('Conducteur : Test Driver'), findsOneWidget);
    await tester.tap(find.byTooltip('Retirer des favoris'));
    await _pump(tester);
    expect(find.text('Aucun trajet favori'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Accueil test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'history includes all passenger booking statuses in newest-first order',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(_createFixture))!;
      addTearDown(fixture.dispose);
      final statuses = [
        'pending',
        'accepted',
        'rejected',
        'cancelled',
        'accepted',
      ];
      for (var index = 0; index < statuses.length; index++) {
        await tester.runAsync(
          () => fixture.db.insert('bookings', {
            'trip_id': fixture.tripId,
            'passenger_id': fixture.passengerId,
            'seats_reserved': 1,
            'status': statuses[index],
            'created_at': DateTime(2026, 1, index + 1).toIso8601String(),
            'updated_at': DateTime(2026, 1, index + 1).toIso8601String(),
          }),
        );
      }
      await tester.runAsync(
        () => fixture.db.insert('bookings', {
          'trip_id': fixture.tripId,
          'passenger_id': fixture.otherPassengerId,
          'seats_reserved': 1,
          'status': 'accepted',
          'created_at': DateTime(2026, 2, 1).toIso8601String(),
          'updated_at': DateTime(2026, 2, 1).toIso8601String(),
        }),
      );
      final bookings = (await tester.runAsync(
        () => BookingRepository().getBookingsForPassenger(fixture.passengerId),
      ))!;
      expect(bookings.map((booking) => booking.status), [
        'accepted',
        'cancelled',
        'rejected',
        'accepted',
        'pending',
      ]);
      await tester.runAsync(
        () => fixture.db.update(
          'trips',
          {'status': 'completed'},
          where: 'id = ?',
          whereArgs: [fixture.tripId],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PassengerHistoryScreen(user: fixture.passenger),
                  ),
                ),
                child: const Text('Historique test'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Historique test'));
      await _pump(tester);
      expect(find.text('Campus → Centre'), findsNWidgets(5));
      expect(find.text('En attente'), findsOneWidget);
      expect(find.text('Acceptée'), findsNWidgets(2));
      expect(find.text('Refusée'), findsOneWidget);
      expect(find.text('Annulée'), findsOneWidget);
      expect(find.text('Trajet : Terminé · 1 place'), findsNWidgets(5));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(find.text('Historique test'), findsOneWidget);
    },
  );
}

Future<void> _pump(WidgetTester tester) async {
  for (var index = 0; index < 10; index++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<_Fixture> _createFixture() async {
  final db = await DatabaseHelper.instance.database;
  final now = DateTime.now().toIso8601String();
  final token = DateTime.now().microsecondsSinceEpoch;
  Future<int> addUser(String name, String role) => db.insert('users', {
    'full_name': name,
    'email': '$role-$token-${name.hashCode}@test.invalid',
    'password_hash': 'test',
    'role': role,
    'is_active': 1,
    'is_verified': 1,
    'created_at': now,
    'updated_at': now,
  });
  final driverId = await addUser('Test Driver', 'driver');
  final passengerId = await addUser('Test Passenger', 'passenger');
  final otherPassengerId = await addUser('Other Passenger', 'passenger');
  final vehicleId = await db.insert('vehicles', {
    'user_id': driverId,
    'brand': 'Test',
    'model': 'Car',
    'license_plate': 'FAV-$token',
    'seats': 4,
    'created_at': now,
  });
  final tripId = await db.insert('trips', {
    'driver_id': driverId,
    'vehicle_id': vehicleId,
    'departure': 'Campus',
    'destination': 'Centre',
    'departure_date': '2030-06-15',
    'departure_time': '09:00',
    'total_seats': 4,
    'available_seats': 3,
    'price': 12.5,
    'meeting_point': 'Campus gate',
    'status': 'available',
    'created_at': now,
    'updated_at': now,
  });
  return _Fixture(
    db: db,
    tripId: tripId,
    vehicleId: vehicleId,
    driverId: driverId,
    passengerId: passengerId,
    otherPassengerId: otherPassengerId,
    userIds: [driverId, passengerId, otherPassengerId],
    passenger: User(
      id: passengerId,
      fullName: 'Test Passenger',
      email: 'passenger-$token-test.invalid',
      passwordHash: 'test',
      role: 'passenger',
      createdAt: now,
      updatedAt: now,
    ),
  );
}

class _Fixture {
  final Database db;
  final int tripId;
  final int vehicleId;
  final int driverId;
  final int passengerId;
  final int otherPassengerId;
  final List<int> userIds;
  final User passenger;

  const _Fixture({
    required this.db,
    required this.tripId,
    required this.vehicleId,
    required this.driverId,
    required this.passengerId,
    required this.otherPassengerId,
    required this.userIds,
    required this.passenger,
  });

  Future<void> dispose() async {
    await db.delete(
      'trip_favorites',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    await db.delete('bookings', where: 'trip_id = ?', whereArgs: [tripId]);
    await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
    await db.delete('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
    for (final id in userIds) {
      await db.delete('users', where: 'id = ?', whereArgs: [id]);
    }
  }
}
