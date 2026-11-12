import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/screens/driver/trips/driver_trip_details_screen.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('fr_FR');
  });

  for (final passengerCount in [0, 1, 4]) {
    testWidgets(
      'confirmation dialog lays out with $passengerCount accepted passengers',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = (await tester.runAsync(
          () => _createFixture(passengerCount: passengerCount),
        ))!;
        addTearDown(fixture.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: DriverTripDetailsScreen(
              tripId: fixture.tripId,
              user: fixture.user,
            ),
          ),
        );
        await _pumpFrames(tester);
        await _tapFinish(tester);
        await _pumpFrames(tester);

        expect(find.text('Terminer ce trajet ?'), findsOneWidget);
        expect(
          find.text('Aucun passager avec une réservation acceptée.'),
          passengerCount == 0 ? findsOneWidget : findsNothing,
        );
        expect(find.byType(CheckboxListTile), findsNWidgets(passengerCount));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('checkboxes toggle and Retour cancels without layout errors', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => _createFixture(passengerCount: 2),
    ))!;
    addTearDown(fixture.dispose);
    await _showDialog(tester, fixture);

    final first = find.byType(CheckboxListTile).first;
    expect(tester.widget<CheckboxListTile>(first).value, isFalse);
    await tester.tap(first);
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(first).value, isTrue);
    await tester.tap(first);
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(first).value, isFalse);
    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Terminer ce trajet ?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation button closes the dialog without layout errors', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => _createFixture(passengerCount: 1),
    ))!;
    addTearDown(fixture.dispose);
    await _showDialog(tester, fixture);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Terminer le trajet'),
      ),
    );
    await _pumpFrames(tester);
    expect(find.text('Terminer ce trajet ?'), findsNothing);
    expect(tester.takeException(), isNull);
    final rows = await tester.runAsync(
      () => fixture.db.query(
        'trips',
        where: 'id = ?',
        whereArgs: [fixture.tripId],
      ),
    );
    expect(rows!.single['status'], 'in_progress');
  });
}

Future<void> _showDialog(WidgetTester tester, _Fixture fixture) async {
  await tester.pumpWidget(
    MaterialApp(
      home: DriverTripDetailsScreen(tripId: fixture.tripId, user: fixture.user),
    ),
  );
  await _pumpFrames(tester);
  await _tapFinish(tester);
  await _pumpFrames(tester);
  expect(find.text('Terminer ce trajet ?'), findsOneWidget);
}

Future<void> _tapFinish(WidgetTester tester) async {
  final finish = find.text('Terminer le trajet');
  await tester.ensureVisible(finish);
  await tester.tap(finish);
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_Fixture> _createFixture({required int passengerCount}) async {
  final db = await DatabaseHelper.instance.database;
  final now = DateTime.now().toIso8601String();
  final token = DateTime.now().microsecondsSinceEpoch;
  final driverId = await db.insert('users', {
    'full_name': 'Dialog Test Driver',
    'email': 'dialog-driver-$token@test.invalid',
    'password_hash': 'test',
    'role': 'driver',
    'is_active': 1,
    'is_verified': 1,
    'created_at': now,
    'updated_at': now,
  });
  final vehicleId = await db.insert('vehicles', {
    'user_id': driverId,
    'brand': 'Test',
    'model': 'Car',
    'license_plate': 'DIALOG-$token',
    'seats': 5,
    'created_at': now,
  });
  final tripId = await db.insert('trips', {
    'driver_id': driverId,
    'vehicle_id': vehicleId,
    'departure': 'Campus',
    'destination': 'Centre',
    'departure_latitude': 36.8,
    'departure_longitude': 10.1,
    'arrival_latitude': 36.9,
    'arrival_longitude': 10.2,
    'departure_date': '2030-06-15',
    'departure_time': '09:00',
    'total_seats': 5,
    'available_seats': 5,
    'price': 10.0,
    'meeting_point': 'Campus',
    'status': 'in_progress',
    'created_at': now,
    'updated_at': now,
  });
  final passengerIds = <int>[];
  for (var i = 0; i < passengerCount; i++) {
    final id = await db.insert('users', {
      'full_name': 'Passenger $i',
      'email': 'dialog-passenger-$i-$token@test.invalid',
      'password_hash': 'test',
      'role': 'passenger',
      'is_active': 1,
      'is_verified': 1,
      'created_at': now,
      'updated_at': now,
    });
    passengerIds.add(id);
    await db.insert('bookings', {
      'trip_id': tripId,
      'passenger_id': id,
      'seats_reserved': 1,
      'status': 'accepted',
      'created_at': now,
      'updated_at': now,
    });
  }
  return _Fixture(
    db: db,
    tripId: tripId,
    vehicleId: vehicleId,
    driverId: driverId,
    passengerIds: passengerIds,
    user: User(
      id: driverId,
      fullName: 'Dialog Test Driver',
      email: 'dialog-driver-$token@test.invalid',
      passwordHash: 'test',
      role: 'driver',
      createdAt: now,
      updatedAt: now,
    ),
  );
}

class _Fixture {
  const _Fixture({
    required this.db,
    required this.tripId,
    required this.vehicleId,
    required this.driverId,
    required this.passengerIds,
    required this.user,
  });
  final Database db;
  final int tripId;
  final int vehicleId;
  final int driverId;
  final List<int> passengerIds;
  final User user;

  Future<void> dispose() async {
    await db.delete('bookings', where: 'trip_id = ?', whereArgs: [tripId]);
    await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
    await db.delete('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
    await db.delete('users', where: 'id = ?', whereArgs: [driverId]);
    for (final id in passengerIds) {
      await db.delete('users', where: 'id = ?', whereArgs: [id]);
    }
  }
}
