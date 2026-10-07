import '../database/database_helper.dart';
import '../models/ride_request.dart';

class RideRequestRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> createRequest({
    required int passengerId,
    required String departure,
    required String destination,
    required String requestDate,
    String? requestTime,
    required int seatsRequested,
    String? description,
  }) async {
    final normalizedDeparture = departure.trim();
    final normalizedDestination = destination.trim();
    if (normalizedDeparture.isEmpty || normalizedDestination.isEmpty) {
      throw ArgumentError(
        'Veuillez renseigner les villes de départ et d’arrivée.',
      );
    }
    if (normalizedDeparture.toLowerCase() ==
        normalizedDestination.toLowerCase()) {
      throw ArgumentError('Le départ et l’arrivée doivent être différents.');
    }
    if (!_isValidDate(requestDate)) {
      throw ArgumentError('Veuillez choisir une date valide.');
    }
    final time = requestTime?.trim();
    if (time != null && time.isNotEmpty && !_isValidTime(time)) {
      throw ArgumentError('Veuillez choisir une heure valide.');
    }
    if (seatsRequested < 1 || seatsRequested > 8) {
      throw ArgumentError.value(seatsRequested, 'seatsRequested');
    }

    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    return db.transaction<int>((transaction) async {
      final passenger = await transaction.query(
        'users',
        columns: ['role', 'is_active'],
        where: 'id = ?',
        whereArgs: [passengerId],
        limit: 1,
      );
      if (passenger.isEmpty ||
          passenger.first['role'] != 'passenger' ||
          passenger.first['is_active'] != 1) {
        throw StateError('Ce compte ne peut pas publier une demande.');
      }

      return transaction.insert('ride_requests', {
        'passenger_id': passengerId,
        'departure': normalizedDeparture,
        'destination': normalizedDestination,
        'request_date': requestDate,
        'request_time': time == null || time.isEmpty ? null : time,
        'seats_requested': seatsRequested,
        'description': _cleanDescription(description),
        'status': 'active',
        'created_at': now,
        'updated_at': now,
      });
    });
  }

  Future<List<RideRequest>> getRequestsForPassenger(int passengerId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'ride_requests',
      where: 'passenger_id = ?',
      whereArgs: [passengerId],
      orderBy: 'request_date ASC, request_time ASC, id DESC',
    );
    return rows.map(RideRequest.fromMap).toList(growable: false);
  }

  Future<List<RideRequest>> getActiveRequestsForCommunityFeed({
    int limit = 50,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery(
      '''
      SELECT ride_requests.*,
        passengers.full_name AS passenger_name,
        passengers.profile_image AS passenger_image
      FROM ride_requests
      INNER JOIN users AS passengers
        ON passengers.id = ride_requests.passenger_id
        AND passengers.role = 'passenger'
        AND passengers.is_active = 1
      WHERE ride_requests.status = 'active'
        AND ride_requests.request_date >= ?
      ORDER BY ride_requests.created_at DESC, ride_requests.id DESC
      LIMIT ?
      ''',
      [today, limit.clamp(1, 100)],
    );
    return rows.map(RideRequest.fromMap).toList(growable: false);
  }

  Future<RideRequest?> getActiveRequestForPassenger(int passengerId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'ride_requests',
      where: "passenger_id = ? AND status = 'active'",
      whereArgs: [passengerId],
      orderBy: 'created_at DESC, id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : RideRequest.fromMap(rows.first);
  }

  bool _isValidDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return false;
    }
    final today = DateTime.now();
    return !date.isBefore(DateTime(today.year, today.month, today.day));
  }

  bool _isValidTime(String value) =>
      RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value);

  String? _cleanDescription(String? value) {
    final description = value?.trim();
    return description == null || description.isEmpty ? null : description;
  }
}
