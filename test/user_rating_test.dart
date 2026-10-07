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
    'ratings require a completed shared trip and cannot be duplicated',
    () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      final unique = DateTime.now().microsecondsSinceEpoch;
      Future<int> addUser(String role, String suffix) => db.insert('users', {
        'full_name': suffix,
        'email': '$suffix-$unique@test.invalid',
        'password_hash': 'test-only',
        'role': role,
        'is_active': 1,
        'is_verified': 1,
        'created_at': now,
        'updated_at': now,
      });

      final driverId = await addUser('driver', 'rating-driver');
      final passengerId = await addUser('passenger', 'rating-passenger');
      final outsiderId = await addUser('passenger', 'rating-outsider');
      final vehicleId = await db.insert('vehicles', {
        'user_id': driverId,
        'brand': 'Test',
        'model': 'Campus',
        'color': 'Blue',
        'license_plate': 'RATE-$unique',
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
        'available_seats': 3,
        'price': 10.0,
        'meeting_point': '',
        'description': null,
        'status': 'available',
        'created_at': now,
        'updated_at': now,
      });
      final bookingId = await db.insert('bookings', {
        'trip_id': tripId,
        'passenger_id': passengerId,
        'seats_reserved': 1,
        'status': 'accepted',
        'created_at': now,
        'updated_at': now,
      });
      addTearDown(() async {
        await db.delete('ratings', where: 'trip_id = ?', whereArgs: [tripId]);
        await db.delete('bookings', where: 'id = ?', whereArgs: [bookingId]);
        await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
        await db.delete('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
        await db.delete(
          'users',
          where: 'id IN (?, ?, ?)',
          whereArgs: [driverId, passengerId, outsiderId],
        );
      });

      final repository = RatingRepository();
      expect(
        await repository.getEligibility(
          tripId: tripId,
          reviewerId: passengerId,
          reviewedId: driverId,
        ),
        RatingEligibility.unavailable,
      );
      await expectLater(
        repository.submitRating(
          tripId: tripId,
          reviewerId: passengerId,
          reviewedId: driverId,
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
          reviewerId: outsiderId,
          reviewedId: driverId,
        ),
        RatingEligibility.unavailable,
      );
      final ratingId = await repository.submitRating(
        tripId: tripId,
        reviewerId: passengerId,
        reviewedId: driverId,
        score: 4,
        comment: '  Très bon trajet.  ',
      );
      final saved = (await db.query(
        'ratings',
        where: 'id = ?',
        whereArgs: [ratingId],
      )).single;
      expect(saved['score'], 4);
      expect(saved['comment'], 'Très bon trajet.');
      expect(
        await repository.getEligibility(
          tripId: tripId,
          reviewerId: passengerId,
          reviewedId: driverId,
        ),
        RatingEligibility.alreadyRated,
      );
      await expectLater(
        repository.submitRating(
          tripId: tripId,
          reviewerId: passengerId,
          reviewedId: driverId,
          score: 4,
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
