import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/repositories/driver_profile_repository.dart';
import 'package:covoit_campus/repositories/rating_repository.dart';
import 'package:covoit_campus/repositories/trip_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('all rating aggregates exclude invalid reviews consistently', () async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    final token = DateTime.now().microsecondsSinceEpoch;

    Future<int> addUser(String role, String label) => db.insert('users', {
      'full_name': label,
      'email': '$label-$token@test.invalid',
      'password_hash': 'test-only',
      'role': role,
      'is_active': 1,
      'is_verified': 1,
      'created_at': now,
      'updated_at': now,
    });

    final driverId = await addUser('driver', 'stats-driver');
    final passengerId = await addUser('passenger', 'stats-passenger');
    final outsiderId = await addUser('passenger', 'stats-outsider');
    final vehicleId = await db.insert('vehicles', {
      'user_id': driverId,
      'brand': 'Test',
      'model': 'Stats',
      'license_plate': 'STATS-$token',
      'seats': 4,
      'created_at': now,
    });

    Future<int> addTrip(String status) => db.insert('trips', {
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
      'status': status,
      'created_at': now,
      'updated_at': now,
    });

    final completedTrip = await addTrip('completed');
    final markedDuplicateTrip = await addTrip('completed');
    final invalidScoreTrip = await addTrip('completed');
    final incompleteTrip = await addTrip('in_progress');
    final pendingBookingTrip = await addTrip('completed');
    final availableTrip = await addTrip('available');
    final tripIds = [
      completedTrip,
      markedDuplicateTrip,
      invalidScoreTrip,
      incompleteTrip,
      pendingBookingTrip,
      availableTrip,
    ];

    Future<void> addBooking(int tripId, int userId, String status) async {
      await db.insert('bookings', {
        'trip_id': tripId,
        'passenger_id': userId,
        'seats_reserved': 1,
        'status': status,
        'created_at': now,
        'updated_at': now,
      });
    }

    await addBooking(completedTrip, passengerId, 'accepted');
    await addBooking(markedDuplicateTrip, passengerId, 'accepted');
    await addBooking(invalidScoreTrip, passengerId, 'accepted');
    await addBooking(incompleteTrip, passengerId, 'accepted');
    await addBooking(pendingBookingTrip, passengerId, 'pending');

    Future<void> addRating({
      required int tripId,
      required int reviewerId,
      required int reviewedId,
      required int score,
      int legacyDuplicate = 0,
    }) async {
      await db.insert('ratings', {
        'trip_id': tripId,
        'reviewer_id': reviewerId,
        'reviewed_id': reviewedId,
        'score': score,
        'comment': null,
        'created_at': now,
        'is_legacy_duplicate': legacyDuplicate,
      });
    }

    await addRating(
      tripId: completedTrip,
      reviewerId: passengerId,
      reviewedId: driverId,
      score: 5,
    );
    await addRating(
      tripId: completedTrip,
      reviewerId: driverId,
      reviewedId: passengerId,
      score: 3,
    );
    await addRating(
      tripId: completedTrip,
      reviewerId: outsiderId,
      reviewedId: driverId,
      score: 1,
    );
    await addRating(
      tripId: completedTrip,
      reviewerId: driverId,
      reviewedId: driverId,
      score: 1,
    );
    await addRating(
      tripId: markedDuplicateTrip,
      reviewerId: passengerId,
      reviewedId: driverId,
      score: 1,
      legacyDuplicate: 1,
    );
    await addRating(
      tripId: invalidScoreTrip,
      reviewerId: passengerId,
      reviewedId: driverId,
      score: 6,
    );
    await addRating(
      tripId: incompleteTrip,
      reviewerId: passengerId,
      reviewedId: driverId,
      score: 1,
    );
    await addRating(
      tripId: pendingBookingTrip,
      reviewerId: passengerId,
      reviewedId: driverId,
      score: 1,
    );

    addTearDown(() async {
      await db.delete(
        'ratings',
        where: 'trip_id IN (${List.filled(tripIds.length, '?').join(',')})',
        whereArgs: tripIds,
      );
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
      await db.delete(
        'users',
        where: 'id IN (?, ?, ?)',
        whereArgs: [driverId, passengerId, outsiderId],
      );
    });

    final driverStats = await RatingRepository().getPublicStats(driverId);
    expect(driverStats.average, 5);
    expect(driverStats.count, 1);
    final passengerStats = await RatingRepository().getPublicStats(passengerId);
    expect(passengerStats.average, 3);
    expect(passengerStats.count, 1);

    final profileStats = await DriverProfileRepository().getStats(driverId);
    expect(profileStats.rating, 5);
    expect(profileStats.ratingCount, 1);

    final tripRepository = TripRepository();
    final details = await tripRepository.getTripDetails(completedTrip);
    expect(details?.driverRating, 5);
    expect(details?.reviewCount, 1);
    final driverDetails = await tripRepository.getDriverTripDetails(
      tripId: completedTrip,
      driverId: driverId,
    );
    expect(driverDetails?.driverRating, 5);
    expect(driverDetails?.reviewCount, 1);

    final searchResults = await tripRepository.searchAvailableTrips(
      passengerId: outsiderId,
      departureDate: '2035-06-10',
    );
    expect(searchResults.single.id, availableTrip);
    expect(searchResults.single.driverRating, 5);

    final feedResults = await tripRepository.getTripsForCommunityFeed();
    expect(
      feedResults.where((trip) => trip.id == availableTrip).single.driverRating,
      5,
    );
    final adminTrips = await tripRepository.getAllTripsForAdmin();
    expect(
      adminTrips.where((trip) => trip.id == completedTrip).single.driverRating,
      5,
    );
  });
}
