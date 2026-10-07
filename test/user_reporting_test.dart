import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/repositories/report_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'passenger and driver reports use only their real booking relation',
    () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      final unique = DateTime.now().microsecondsSinceEpoch;
      final userIds = <int>[];
      final vehicleIds = <int>[];
      final tripIds = <int>[];
      final bookingIds = <int>[];
      final reportIds = <int>[];

      Future<int> addUser(String name, String role, String label) async {
        final id = await db.insert('users', {
          'full_name': name,
          'email': '$label-$unique@test.invalid',
          'password_hash': 'test-only',
          'role': role,
          'is_active': 1,
          'is_verified': 1,
          'created_at': now,
          'updated_at': now,
        });
        userIds.add(id);
        return id;
      }

      Future<int> addTrip(int driverId, String label) async {
        final vehicleId = await db.insert('vehicles', {
          'user_id': driverId,
          'brand': 'Test',
          'model': 'Campus',
          'color': 'Blue',
          'license_plate': 'T-$unique-$label',
          'seats': 4,
          'created_at': now,
        });
        vehicleIds.add(vehicleId);
        final tripId = await db.insert('trips', {
          'driver_id': driverId,
          'vehicle_id': vehicleId,
          'departure': 'Tunis',
          'destination': 'Sousse',
          'departure_date': '2035-06-10',
          'departure_time': '09:00',
          'total_seats': 4,
          'available_seats': 3,
          'price': 12.0,
          'meeting_point': '',
          'description': null,
          'status': 'available',
          'created_at': now,
          'updated_at': now,
        });
        tripIds.add(tripId);
        return tripId;
      }

      Future<int> addBooking(int tripId, int passengerId) async {
        final bookingId = await db.insert('bookings', {
          'trip_id': tripId,
          'passenger_id': passengerId,
          'seats_reserved': 1,
          'status': 'accepted',
          'created_at': now,
          'updated_at': now,
        });
        bookingIds.add(bookingId);
        return bookingId;
      }

      final passenger = await addUser(
        'Passenger One',
        'passenger',
        'passenger-one',
      );
      final unrelatedPassenger = await addUser(
        'Passenger Two',
        'passenger',
        'passenger-two',
      );
      final driver = await addUser('Driver One', 'driver', 'driver-one');
      final unrelatedDriver = await addUser(
        'Driver Two',
        'driver',
        'driver-two',
      );
      final trip = await addTrip(driver, 'one');
      final unrelatedTrip = await addTrip(unrelatedDriver, 'two');
      final selfTrip = await addTrip(passenger, 'self');
      final passengerBooking = await addBooking(trip, passenger);
      final unrelatedBooking = await addBooking(
        unrelatedTrip,
        unrelatedPassenger,
      );
      final selfBooking = await addBooking(selfTrip, passenger);
      final requestId = await db.insert('ride_requests', {
        'passenger_id': passenger,
        'departure': 'Tunis',
        'destination': 'Sousse',
        'request_date': '2035-06-10',
        'request_time': '09:00',
        'seats_requested': 1,
        'description': null,
        'status': 'active',
        'created_at': now,
        'updated_at': now,
      });

      addTearDown(() async {
        for (final id in reportIds) {
          await db.delete('reports', where: 'id = ?', whereArgs: [id]);
        }
        for (final id in bookingIds) {
          await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
        }
        for (final id in tripIds) {
          await db.delete('trips', where: 'id = ?', whereArgs: [id]);
        }
        for (final id in vehicleIds) {
          await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
        }
        await db.delete('ride_requests', where: 'id = ?', whereArgs: [requestId]);
        for (final id in userIds) {
          await db.delete('users', where: 'id = ?', whereArgs: [id]);
        }
      });

      final repository = ReportRepository();
      final passengerReportId = await repository
          .createReportFromPassengerBooking(
            reporterId: passenger,
            bookingId: passengerBooking,
            reason: '  Conducteur absent  ',
            description: 'Arrivé au point de rendez-vous.',
          );
      reportIds.add(passengerReportId);
      final passengerReport = await repository.getReportById(passengerReportId);
      expect(passengerReport?.reporterId, passenger);
      expect(passengerReport?.reportedUserId, driver);
      expect(passengerReport?.tripId, trip);
      expect(passengerReport?.reason, 'Conducteur absent');
      expect(passengerReport?.status, 'pending');
      expect(
        (await repository.getReportsForUser(passenger))
            .where((report) => report.id == passengerReportId),
        hasLength(1),
      );

      final driverReportId = await repository.createReportFromDriverBooking(
        reporterId: driver,
        bookingId: passengerBooking,
        reason: 'Passager absent',
      );
      reportIds.add(driverReportId);
      final driverReport = await repository.getReportById(driverReportId);
      expect(driverReport?.reporterId, driver);
      expect(driverReport?.reportedUserId, passenger);
      expect(driverReport?.tripId, trip);
      expect(driverReport?.status, 'pending');

      await expectLater(
        repository.createReportFromPassengerBooking(
          reporterId: passenger,
          bookingId: passengerBooking,
          reason: '  ',
        ),
        throwsArgumentError,
      );
      await expectLater(
        repository.createReportFromPassengerBooking(
          reporterId: driver,
          bookingId: passengerBooking,
          reason: 'Autre',
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repository.createReportFromPassengerBooking(
          reporterId: passenger,
          bookingId: selfBooking,
          reason: 'Autre',
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repository.createReportFromDriverBooking(
          reporterId: driver,
          bookingId: unrelatedBooking,
          reason: 'Comportement inapproprié',
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repository.createReportFromPassengerBooking(
          reporterId: passenger,
          bookingId: unrelatedBooking,
          reason: 'Autre',
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        (await repository.getAllReports())
            .where((r) => reportIds.contains(r.id))
            .length,
        2,
      );

      expect(
        await repository.canCreateProfileReport(
          reporterId: driver,
          targetId: passenger,
          rideRequestId: requestId,
        ),
        isTrue,
      );
      final requestReportId = await repository.createProfileReport(
        reporterId: driver,
        targetId: passenger,
        rideRequestId: requestId,
        contextLabel: 'Tunis → Sousse',
        reason: 'Comportement inapproprié',
        description: 'Contexte du signalement.',
      );
      reportIds.add(requestReportId);
      final requestReport = await repository.getReportById(requestReportId);
      expect(requestReport?.tripId, isNull);
      expect(requestReport?.description, contains('Tunis → Sousse'));
      expect(requestReport?.description, contains('Contexte du signalement.'));
    },
  );
}
