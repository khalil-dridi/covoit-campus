import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/repositories/rating_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'driver may rate accepted passengers once after completion only',
    () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      final token = DateTime.now().microsecondsSinceEpoch;

      Future<int> addUser(String role, String name) => db.insert('users', {
        'full_name': name,
        'email': '$name-$token@test.invalid',
        'password_hash': 'test-only',
        'role': role,
        'is_active': 1,
        'is_verified': 1,
        'created_at': now,
        'updated_at': now,
      });

      final driverId = await addUser('driver', 'driver-reviewer');
      final otherDriverId = await addUser('driver', 'other-driver-reviewer');
      final passengerId = await addUser('passenger', 'accepted-passenger');
      final rejectedPassengerId = await addUser(
        'passenger',
        'rejected-passenger',
      );
      final cancelledPassengerId = await addUser(
        'passenger',
        'cancelled-passenger',
      );
      final vehicleId = await db.insert('vehicles', {
        'user_id': driverId,
        'brand': 'Test',
        'model': 'Rating',
        'license_plate': 'DRV-RATE-$token',
        'seats': 4,
        'created_at': now,
      });
      final tripId = await db.insert('trips', {
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'departure': 'Tunis',
        'destination': 'Sousse',
        'departure_date': '2035-06-10',
        'departure_time': '09:00',
        'total_seats': 4,
        'available_seats': 1,
        'price': 10.0,
        'meeting_point': '',
        'description': null,
        'status': 'available',
        'created_at': now,
        'updated_at': now,
      });

      Future<void> addBooking(int userId, String status) async {
        await db.insert('bookings', {
          'trip_id': tripId,
          'passenger_id': userId,
          'seats_reserved': 1,
          'status': status,
          'created_at': now,
          'updated_at': now,
        });
      }

      await addBooking(passengerId, 'accepted');
      await addBooking(rejectedPassengerId, 'rejected');
      await addBooking(cancelledPassengerId, 'cancelled');
      addTearDown(() async {
        await db.delete('ratings', where: 'trip_id = ?', whereArgs: [tripId]);
        await db.delete('bookings', where: 'trip_id = ?', whereArgs: [tripId]);
        await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
        await db.delete('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
        await db.delete(
          'users',
          where: 'id IN (?, ?, ?, ?, ?)',
          whereArgs: [
            driverId,
            otherDriverId,
            passengerId,
            rejectedPassengerId,
            cancelledPassengerId,
          ],
        );
      });

      final repository = RatingRepository();
      expect(
        await repository.getEligibility(
          tripId: tripId,
          reviewerId: driverId,
          reviewedId: passengerId,
        ),
        RatingEligibility.unavailable,
      );
      await expectLater(
        repository.submitRating(
          tripId: tripId,
          reviewerId: driverId,
          reviewedId: passengerId,
          score: 5,
        ),
        throwsA(isA<StateError>()),
      );

      await db.update(
        'trips',
        {'status': 'completed'},
        where: 'id = ?',
        whereArgs: [tripId],
      );
      expect(
        await repository.getEligibility(
          tripId: tripId,
          reviewerId: driverId,
          reviewedId: passengerId,
        ),
        RatingEligibility.eligible,
      );
      expect(
        await repository.getEligibility(
          tripId: tripId,
          reviewerId: otherDriverId,
          reviewedId: passengerId,
        ),
        RatingEligibility.unavailable,
      );
      expect(
        await repository.getEligibility(
          tripId: tripId,
          reviewerId: driverId,
          reviewedId: driverId,
        ),
        RatingEligibility.unavailable,
      );
      await expectLater(
        repository.submitRating(
          tripId: tripId,
          reviewerId: driverId,
          reviewedId: driverId,
          score: 4,
        ),
        throwsA(isA<StateError>()),
      );
      for (final ineligiblePassengerId in [
        rejectedPassengerId,
        cancelledPassengerId,
      ]) {
        expect(
          await repository.getEligibility(
            tripId: tripId,
            reviewerId: driverId,
            reviewedId: ineligiblePassengerId,
          ),
          RatingEligibility.unavailable,
        );
        await expectLater(
          repository.submitRating(
            tripId: tripId,
            reviewerId: driverId,
            reviewedId: ineligiblePassengerId,
            score: 4,
          ),
          throwsA(isA<StateError>()),
        );
      }

      final ratingId = await repository.submitRating(
        tripId: tripId,
        reviewerId: driverId,
        reviewedId: passengerId,
        score: 5,
        comment: 'Merci pour le trajet.',
      );
      expect(ratingId, greaterThan(0));
      expect(
        await repository.getEligibility(
          tripId: tripId,
          reviewerId: driverId,
          reviewedId: passengerId,
        ),
        RatingEligibility.alreadyRated,
      );
      await expectLater(
        repository.submitRating(
          tripId: tripId,
          reviewerId: driverId,
          reviewedId: passengerId,
          score: 4,
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repository.submitRating(
          tripId: tripId,
          reviewerId: driverId,
          reviewedId: passengerId,
          score: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    },
  );
}
