import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/rating.dart';
import '../models/rating_history_entry.dart';

enum RatingEligibility { eligible, alreadyRated, unavailable }

class RatingRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Shared SQL predicate for every displayed rating aggregate.
  /// The trip/booking joins ensure the two users are its driver and an
  /// accepted passenger, in either review direction.
  static const validRatingPredicate = '''
    ratings.is_legacy_duplicate = 0
    AND ratings.score BETWEEN 1 AND 5
    AND ratings.reviewer_id != ratings.reviewed_id
    AND EXISTS (
      SELECT 1
      FROM trips AS rating_trip
      WHERE rating_trip.id = ratings.trip_id
        AND rating_trip.status = 'completed'
        AND (
          (
            ratings.reviewer_id = rating_trip.driver_id
            AND EXISTS (
              SELECT 1 FROM users AS rating_driver
              WHERE rating_driver.id = ratings.reviewer_id
                AND rating_driver.role = 'driver'
            )
            AND EXISTS (
              SELECT 1 FROM users AS rating_passenger
              WHERE rating_passenger.id = ratings.reviewed_id
                AND rating_passenger.role = 'passenger'
            )
            AND EXISTS (
              SELECT 1 FROM bookings AS rating_booking
              WHERE rating_booking.trip_id = rating_trip.id
                AND rating_booking.passenger_id = ratings.reviewed_id
                AND rating_booking.status = 'accepted'
            )
          )
          OR
          (
            ratings.reviewed_id = rating_trip.driver_id
            AND EXISTS (
              SELECT 1 FROM users AS rating_driver
              WHERE rating_driver.id = ratings.reviewed_id
                AND rating_driver.role = 'driver'
            )
            AND EXISTS (
              SELECT 1 FROM users AS rating_passenger
              WHERE rating_passenger.id = ratings.reviewer_id
                AND rating_passenger.role = 'passenger'
            )
            AND EXISTS (
              SELECT 1 FROM bookings AS rating_booking
              WHERE rating_booking.trip_id = rating_trip.id
                AND rating_booking.passenger_id = ratings.reviewer_id
                AND rating_booking.status = 'accepted'
            )
          )
        )
    )
  ''';

  Future<RatingEligibility> getEligibility({
    required int tripId,
    required int reviewerId,
    required int reviewedId,
  }) async {
    if (reviewerId == reviewedId) return RatingEligibility.unavailable;
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT trips.driver_id, trips.status AS trip_status,
             reviewer.role AS reviewer_role, reviewer.is_active AS reviewer_active,
             reviewed.role AS reviewed_role, reviewed.is_active AS reviewed_active
      FROM trips
      INNER JOIN users AS reviewer ON reviewer.id = ?
      INNER JOIN users AS reviewed ON reviewed.id = ?
      WHERE trips.id = ?
      LIMIT 1
    ''',
      [reviewerId, reviewedId, tripId],
    );
    if (rows.isEmpty) return RatingEligibility.unavailable;
    final row = rows.first;
    final reviewerRole = row['reviewer_role'];
    final reviewedRole = row['reviewed_role'];
    if (row['trip_status'] != 'completed' ||
        row['reviewer_active'] != 1 ||
        row['reviewed_active'] != 1) {
      return RatingEligibility.unavailable;
    }
    final driverId = row['driver_id'] as int;
    final participantRows = await db.query(
      'bookings',
      columns: ['passenger_id'],
      where: 'trip_id = ? AND status = ?',
      whereArgs: [tripId, 'accepted'],
    );
    final passengerIds = participantRows
        .map((r) => r['passenger_id'] as int)
        .toSet();
    final reviewerParticipates =
        reviewerId == driverId || passengerIds.contains(reviewerId);
    final reviewedParticipates =
        reviewedId == driverId || passengerIds.contains(reviewedId);
    final counterpartRoles =
        (reviewerId == driverId &&
            reviewerRole == 'driver' &&
            reviewedRole == 'passenger' &&
            passengerIds.contains(reviewedId)) ||
        (reviewedId == driverId &&
            reviewerRole == 'passenger' &&
            reviewedRole == 'driver' &&
            passengerIds.contains(reviewerId));
    if (!reviewerParticipates || !reviewedParticipates || !counterpartRoles) {
      return RatingEligibility.unavailable;
    }
    final existing = await db.query(
      'ratings',
      columns: ['id'],
      where: 'trip_id = ? AND reviewer_id = ? AND reviewed_id = ?',
      whereArgs: [tripId, reviewerId, reviewedId],
      limit: 1,
    );
    return existing.isEmpty
        ? RatingEligibility.eligible
        : RatingEligibility.alreadyRated;
  }

  Future<int> submitRating({
    required int tripId,
    required int reviewerId,
    required int reviewedId,
    required int score,
    String? comment,
  }) async {
    if (score < 1 || score > 5) {
      throw ArgumentError('La note doit être comprise entre 1 et 5.');
    }
    final normalizedComment = comment?.trim();
    if ((normalizedComment?.length ?? 0) > 1000) {
      throw ArgumentError('Le commentaire dépasse 1000 caractères.');
    }
    final db = await _databaseHelper.database;
    return db.transaction<int>((txn) async {
      final tripRows = await txn.query(
        'trips',
        columns: ['driver_id', 'status'],
        where: 'id = ?',
        whereArgs: [tripId],
        limit: 1,
      );
      if (tripRows.isEmpty || tripRows.first['status'] != 'completed') {
        throw StateError('Seuls les trajets terminés peuvent être évalués.');
      }
      if (reviewerId == reviewedId) {
        throw StateError('Vous ne pouvez pas vous évaluer.');
      }
      final users = await txn.query(
        'users',
        columns: ['id', 'role', 'is_active'],
        where: 'id IN (?, ?) AND is_active = 1',
        whereArgs: [reviewerId, reviewedId],
      );
      if (users.length != 2) {
        throw StateError('Un participant n’est plus actif.');
      }
      final byId = {for (final user in users) user['id'] as int: user};
      final driverId = tripRows.first['driver_id'] as int;
      final passengerRows = await txn.query(
        'bookings',
        columns: ['passenger_id'],
        where: 'trip_id = ? AND status = ?',
        whereArgs: [tripId, 'accepted'],
      );
      final passengers = passengerRows
          .map((r) => r['passenger_id'] as int)
          .toSet();
      final reviewerRole = byId[reviewerId]!['role'];
      final reviewedRole = byId[reviewedId]!['role'];
      final isCounterpart =
          (reviewerId == driverId &&
              reviewerRole == 'driver' &&
              reviewedRole == 'passenger' &&
              passengers.contains(reviewedId)) ||
          (reviewedId == driverId &&
              reviewerRole == 'passenger' &&
              reviewedRole == 'driver' &&
              passengers.contains(reviewerId));
      if (!isCounterpart) {
        throw StateError(
          'Vous n’avez pas participé à ce trajet avec cette personne.',
        );
      }
      final duplicate = await txn.query(
        'ratings',
        columns: ['id'],
        where: 'trip_id = ? AND reviewer_id = ? AND reviewed_id = ?',
        whereArgs: [tripId, reviewerId, reviewedId],
        limit: 1,
      );
      if (duplicate.isNotEmpty) {
        throw StateError(
          'Vous avez déjà évalué cette personne pour ce trajet.',
        );
      }
      final rating = Rating(
        tripId: tripId,
        reviewerId: reviewerId,
        reviewedId: reviewedId,
        score: score,
        comment: normalizedComment?.isEmpty == true ? null : normalizedComment,
        createdAt: DateTime.now().toIso8601String(),
      );
      try {
        return await txn.insert('ratings', rating.toMap());
      } on DatabaseException catch (error) {
        if (error.isUniqueConstraintError('ratings.trip_id')) {
          throw StateError(
            'Vous avez déjà évalué cette personne pour ce trajet.',
          );
        }
        rethrow;
      }
    });
  }

  Future<({double? average, int count})> getPublicStats(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT AVG(ratings.score) AS average_score, COUNT(*) AS rating_count
      FROM ratings
      WHERE ratings.reviewed_id = ?
        AND $validRatingPredicate
      ''',
      [userId],
    );
    final row = rows.first;
    return (
      average: (row['average_score'] as num?)?.toDouble(),
      count: row['rating_count'] as int? ?? 0,
    );
  }

  Future<List<Rating>> getRatingsReceivedByUser(int userId) async {
    final entries = await getRatingHistoryReceivedByUser(userId);
    return entries.map((entry) => entry.rating).toList(growable: false);
  }

  Future<List<Rating>> getRatingsGivenByUser(int userId) async {
    final entries = await getRatingHistoryGivenByUser(userId);
    return entries.map((entry) => entry.rating).toList(growable: false);
  }

  Future<List<RatingHistoryEntry>> getRatingHistoryReceivedByUser(int userId) =>
      _getRatingHistory(userId: userId, received: true);

  Future<List<RatingHistoryEntry>> getRatingHistoryGivenByUser(int userId) =>
      _getRatingHistory(userId: userId, received: false);

  Future<List<RatingHistoryEntry>> _getRatingHistory({
    required int userId,
    required bool received,
  }) async {
    final db = await _databaseHelper.database;
    final userColumn = received ? 'reviewed_id' : 'reviewer_id';
    final otherUserColumn = received ? 'reviewer_id' : 'reviewed_id';
    final rows = await db.rawQuery(
      '''
      SELECT ratings.*, other_user.full_name AS other_user_name,
             other_user.profile_image AS other_user_profile_image,
             trips.departure, trips.destination,
             trips.departure_date AS departure_date
      FROM ratings
      INNER JOIN users AS other_user
        ON other_user.id = ratings.$otherUserColumn
      LEFT JOIN trips ON trips.id = ratings.trip_id
      WHERE ratings.$userColumn = ?
        AND $validRatingPredicate
      ORDER BY ratings.created_at DESC, ratings.id DESC
      ''',
      [userId],
    );
    return rows.map(RatingHistoryEntry.fromMap).toList(growable: false);
  }
}
