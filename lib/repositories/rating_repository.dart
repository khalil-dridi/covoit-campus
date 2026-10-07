import '../database/database_helper.dart';

enum RatingEligibility { eligible, alreadyRated, unavailable }

class RatingRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

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
      return txn.insert('ratings', {
        'trip_id': tripId,
        'reviewer_id': reviewerId,
        'reviewed_id': reviewedId,
        'score': score,
        'comment': normalizedComment?.isEmpty == true
            ? null
            : normalizedComment,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<({double? average, int count})> getPublicStats(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT AVG(score) AS average_score, COUNT(*) AS rating_count FROM ratings WHERE reviewed_id = ?',
      [userId],
    );
    final row = rows.first;
    return (
      average: (row['average_score'] as num?)?.toDouble(),
      count: row['rating_count'] as int? ?? 0,
    );
  }
}
