import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/repositories/trip_repository.dart';
import 'package:covoit_campus/services/carbon_savings_service.dart';
import 'package:covoit_campus/services/geo_matching_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'allocates zero contribution when a completed trip has no passengers',
    () async {
      final fixture = await _createFixture(
        passengerCount: 0,
        status: 'completed',
      );
      addTearDown(() => fixture.cleanup());

      expect(
        await CarbonSavingsService().getUserTotalSavingsGrams(fixture.driverId),
        0,
      );
    },
  );

  test(
    'one confirmed passenger and driver receive the same contribution',
    () async {
      final fixture = await _createFixture(
        passengerCount: 1,
        status: 'completed',
      );
      addTearDown(() => fixture.cleanup());
      await fixture.confirmAttendance();

      final service = CarbonSavingsService();
      final driverSavings = await service.getUserTotalSavingsGrams(
        fixture.driverId,
      );
      final passengerSavings = await service.getUserTotalSavingsGrams(
        fixture.passengerIds.single,
      );
      final distanceKm = const GeoMatchingService().distanceKm(
        const LatLng(36.8065, 10.1815),
        const LatLng(36.9865, 10.1815),
      );

      expect(
        driverSavings,
        CarbonSavingsService.individualSavingsGrams(
          distanceKm: distanceKm!,
          passengerCount: 1,
        ),
      );
      expect(passengerSavings, driverSavings);
    },
  );

  test('three-passenger formula gives each participant 1,800 g for 20 km', () {
    expect(
      CarbonSavingsService.individualSavingsGrams(
        distanceKm: 20,
        passengerCount: 3,
      ),
      1800,
    );
  });

  test(
    'accepted booking without presence confirmation earns no contribution',
    () async {
      final fixture = await _createFixture(
        passengerCount: 1,
        status: 'completed',
        acceptedBookings: true,
      );
      addTearDown(() => fixture.cleanup());

      expect(
        await CarbonSavingsService().getUserTotalSavingsGrams(
          fixture.passengerIds.single,
        ),
        0,
      );
      expect(
        await CarbonSavingsService().getUserTotalSavingsGrams(fixture.driverId),
        0,
      );
    },
  );

  test('cancelled and unfinished trips do not contribute', () async {
    for (final status in ['cancelled', 'in_progress']) {
      final fixture = await _createFixture(passengerCount: 1, status: status);
      await fixture.confirmAttendance();
      expect(
        await CarbonSavingsService().getUserTotalSavingsGrams(fixture.driverId),
        0,
      );
      await fixture.cleanup();
    }
  });

  test('invalid GPS coordinates produce no calculated savings', () async {
    final fixture = await _createFixture(
      passengerCount: 1,
      status: 'completed',
      invalidCoordinates: true,
    );
    addTearDown(() => fixture.cleanup());
    await fixture.confirmAttendance();

    expect(
      await CarbonSavingsService().getUserTotalSavingsGrams(fixture.driverId),
      0,
    );
  });

  test(
    'completion persists unique attendance and refreshes profile totals',
    () async {
      final fixture = await _createFixture(
        passengerCount: 3,
        status: 'in_progress',
        acceptedBookings: true,
      );
      addTearDown(() => fixture.cleanup());
      final db = await DatabaseHelper.instance.database;
      final attendanceRevision = CarbonSavingsService.statsRevision.value;

      expect(
        await CarbonSavingsService().getUserTotalSavingsGrams(fixture.driverId),
        0,
      );
      final completed = await TripRepository().completeTrip(
        tripId: fixture.tripId,
        driverId: fixture.driverId,
        confirmedPassengerIds: fixture.passengerIds.toSet(),
      );
      final duplicateCompletion = await TripRepository().completeTrip(
        tripId: fixture.tripId,
        driverId: fixture.driverId,
        confirmedPassengerIds: fixture.passengerIds.toSet(),
      );

      expect(completed, 1);
      expect(duplicateCompletion, 0);
      expect(CarbonSavingsService.statsRevision.value, attendanceRevision + 1);
      expect(
        await db.query(
          'trip_attendance',
          where: 'trip_id = ?',
          whereArgs: [fixture.tripId],
        ),
        hasLength(3),
      );
      final driverSavings = await CarbonSavingsService()
          .getUserTotalSavingsGrams(fixture.driverId);
      for (final passengerId in fixture.passengerIds) {
        expect(
          await CarbonSavingsService().getUserTotalSavingsGrams(passengerId),
          driverSavings,
        );
      }
      final distanceKm = const GeoMatchingService().distanceKm(
        const LatLng(36.8065, 10.1815),
        const LatLng(36.9865, 10.1815),
      );
      expect(
        driverSavings,
        CarbonSavingsService.individualSavingsGrams(
          distanceKm: distanceKm!,
          passengerCount: 3,
        ),
      );
      expect(CarbonSavingsService.formatGrams(0), '0 kg');
    },
  );
}

Future<_TripFixture> _createFixture({
  required int passengerCount,
  required String status,
  bool acceptedBookings = false,
  bool invalidCoordinates = false,
}) async {
  final db = await DatabaseHelper.instance.database;
  final unique = DateTime.now().microsecondsSinceEpoch;
  final now = DateTime.now().toIso8601String();

  Future<int> addUser(String role, String label) => db.insert('users', {
    'full_name': '$label $unique',
    'email': '$label-$unique@example.tn',
    'password_hash': '',
    'role': role,
    'created_at': now,
    'updated_at': now,
  });

  final driverId = await addUser('driver', 'driver');
  final passengerIds = <int>[];
  for (var index = 0; index < passengerCount; index++) {
    passengerIds.add(await addUser('passenger', 'passenger$index'));
  }
  final vehicleId = await db.insert('vehicles', {
    'user_id': driverId,
    'brand': 'Test',
    'model': 'Car',
    'license_plate': 'TEST-$unique',
    'seats': passengerCount + 1,
    'created_at': now,
  });
  final tripId = await db.insert('trips', {
    'driver_id': driverId,
    'vehicle_id': vehicleId,
    'departure': 'Départ test',
    'destination': 'Arrivée test',
    'departure_latitude': invalidCoordinates ? 100 : 36.8065,
    'departure_longitude': 10.1815,
    'arrival_latitude': 36.9865,
    'arrival_longitude': 10.1815,
    'departure_date': '2026-12-01',
    'departure_time': '10:00',
    'total_seats': passengerCount + 1,
    'available_seats': 0,
    'status': status,
    'created_at': now,
    'updated_at': now,
  });
  if (acceptedBookings) {
    for (final passengerId in passengerIds) {
      await db.insert('bookings', {
        'trip_id': tripId,
        'passenger_id': passengerId,
        'seats_reserved': 1,
        'status': 'accepted',
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  return _TripFixture(
    db: db,
    tripId: tripId,
    driverId: driverId,
    vehicleId: vehicleId,
    passengerIds: passengerIds,
  );
}

class _TripFixture {
  const _TripFixture({
    required this.db,
    required this.tripId,
    required this.driverId,
    required this.vehicleId,
    required this.passengerIds,
  });

  final Database db;
  final int tripId;
  final int driverId;
  final int vehicleId;
  final List<int> passengerIds;

  Future<void> confirmAttendance() async {
    final now = DateTime.now().toIso8601String();
    for (final passengerId in passengerIds) {
      await db.insert('trip_attendance', {
        'trip_id': tripId,
        'passenger_id': passengerId,
        'confirmed_at': now,
      });
    }
  }

  Future<void> cleanup() async {
    await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
    await db.delete('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
    final ids = [driverId, ...passengerIds];
    await db.delete(
      'users',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }
}
