import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/repositories/rating_repository.dart';
import 'package:covoit_campus/screens/shared/profile/rating_history_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'received and given history only include valid reviews, newest first',
    () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      final suffix = DateTime.now().microsecondsSinceEpoch;

      Future<int> addUser(String role, String name, {String? image}) =>
          db.insert('users', {
            'full_name': name,
            'email': '$name-$suffix@test.invalid',
            'password_hash': 'test-only',
            'role': role,
            'profile_image': image,
            'is_active': 1,
            'is_verified': 1,
            'created_at': now,
            'updated_at': now,
          });

      final driverId = await addUser('driver', 'History driver');
      final passengerId = await addUser(
        'passenger',
        'History passenger',
        image: 'assets/avatar.png',
      );
      final outsiderId = await addUser('passenger', 'History outsider');
      final vehicleId = await db.insert('vehicles', {
        'user_id': driverId,
        'brand': 'Test',
        'model': 'History',
        'license_plate': 'HIST-$suffix',
        'seats': 4,
        'created_at': now,
      });

      Future<int> addTrip(String status, String date) => db.insert('trips', {
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'departure': 'Tunis',
        'destination': 'Sousse',
        'departure_date': date,
        'departure_time': '09:00',
        'total_seats': 4,
        'available_seats': 3,
        'price': 10.0,
        'meeting_point': '',
        'description': null,
        'status': status,
        'created_at': now,
        'updated_at': now,
      });

      final olderTrip = await addTrip('completed', '2035-06-10');
      final newerTrip = await addTrip('completed', '2035-06-11');
      final invalidTrip = await addTrip('available', '2035-06-12');
      final tripIds = [olderTrip, newerTrip, invalidTrip];
      for (final tripId in tripIds) {
        await db.insert('bookings', {
          'trip_id': tripId,
          'passenger_id': passengerId,
          'seats_reserved': 1,
          'status': 'accepted',
          'created_at': now,
          'updated_at': now,
        });
      }

      Future<void> addRating({
        required int tripId,
        required int reviewer,
        required int reviewed,
        required int score,
        required String createdAt,
        String? comment,
      }) async {
        await db.insert('ratings', {
          'trip_id': tripId,
          'reviewer_id': reviewer,
          'reviewed_id': reviewed,
          'score': score,
          'comment': comment,
          'created_at': createdAt,
        });
      }

      final oldestAt = '2025-01-01T10:00:00.000';
      final newestAt = '2025-02-01T10:00:00.000';
      await addRating(
        tripId: olderTrip,
        reviewer: passengerId,
        reviewed: driverId,
        score: 4,
        createdAt: oldestAt,
        comment: 'Très bon trajet',
      );
      await addRating(
        tripId: newerTrip,
        reviewer: passengerId,
        reviewed: driverId,
        score: 5,
        createdAt: newestAt,
      );
      await addRating(
        tripId: newerTrip,
        reviewer: driverId,
        reviewed: passengerId,
        score: 3,
        createdAt: newestAt,
      );
      await addRating(
        tripId: invalidTrip,
        reviewer: outsiderId,
        reviewed: driverId,
        score: 1,
        createdAt: newestAt,
      );

      addTearDown(() async {
        await db.delete(
          'ratings',
          where: 'trip_id IN (?, ?, ?)',
          whereArgs: tripIds,
        );
        await db.delete(
          'bookings',
          where: 'trip_id IN (?, ?, ?)',
          whereArgs: tripIds,
        );
        await db.delete('trips', where: 'id IN (?, ?, ?)', whereArgs: tripIds);
        await db.delete('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
        await db.delete(
          'users',
          where: 'id IN (?, ?, ?)',
          whereArgs: [driverId, passengerId, outsiderId],
        );
      });

      final repository = RatingRepository();
      final received = await repository.getRatingHistoryReceivedByUser(
        driverId,
      );
      expect(received.map((entry) => entry.rating.score), [5, 4]);
      expect(received.first.otherUserName, 'History passenger');
      expect(received.first.otherUserProfileImage, 'assets/avatar.png');
      expect(received.first.departure, 'Tunis');
      expect(received.first.destination, 'Sousse');
      expect(received.last.rating.comment, 'Très bon trajet');

      final given = await repository.getRatingHistoryGivenByUser(driverId);
      expect(given.map((entry) => entry.rating.score), [3]);
      expect(given.single.otherUserName, 'History passenger');
    },
  );

  testWidgets('received reviews empty state is clear', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RatingHistoryEmptyState(received: true)),
    );
    expect(find.text('Vous n’avez pas encore reçu d’avis.'), findsOneWidget);
  });

  testWidgets('given reviews empty state is clear', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RatingHistoryEmptyState(received: false)),
    );
    expect(find.text('Vous n’avez pas encore donné d’avis.'), findsOneWidget);
  });
}
