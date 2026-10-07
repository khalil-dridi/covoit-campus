import '../database/database_helper.dart';
import '../models/report.dart';

class ReportRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  static const _joinedSelect = '''
    SELECT
      reports.id,
      reports.reporter_id,
      reports.reported_user_id,
      reports.trip_id,
      reports.reason,
      reports.description,
      reports.status,
      reports.created_at,
      reporter.full_name AS reporter_name,
      reporter.email AS reporter_email,
      target.full_name AS reported_user_name,
      target.email AS reported_user_email,
      trips.departure AS trip_departure,
      trips.destination AS trip_destination,
      trips.departure_date AS trip_date,
      trips.departure_time AS trip_time
    FROM reports
    LEFT JOIN users AS reporter ON reporter.id = reports.reporter_id
    LEFT JOIN users AS target ON target.id = reports.reported_user_id
    LEFT JOIN trips ON trips.id = reports.trip_id
  ''';

  Future<int> createReportFromPassengerBooking({
    required int reporterId,
    required int bookingId,
    required String reason,
    String? description,
  }) => _createReportForBooking(
    reporterId: reporterId,
    bookingId: bookingId,
    reporterRole: 'passenger',
    targetRole: 'driver',
    reason: reason,
    description: description,
  );

  Future<int> createReportFromDriverBooking({
    required int reporterId,
    required int bookingId,
    required String reason,
    String? description,
  }) => _createReportForBooking(
    reporterId: reporterId,
    bookingId: bookingId,
    reporterRole: 'driver',
    targetRole: 'passenger',
    reason: reason,
    description: description,
  );

  Future<int> _createReportForBooking({
    required int reporterId,
    required int bookingId,
    required String reporterRole,
    required String targetRole,
    required String reason,
    required String? description,
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      throw ArgumentError('Choisissez un motif pour le signalement.');
    }
    final db = await _databaseHelper.database;
    return db.transaction<int>((transaction) async {
      final reporterRows = await transaction.query(
        'users',
        columns: ['id', 'role', 'is_active'],
        where: 'id = ?',
        whereArgs: [reporterId],
        limit: 1,
      );
      if (reporterRows.isEmpty ||
          reporterRows.first['role'] != reporterRole ||
          reporterRows.first['is_active'] != 1) {
        throw StateError('Votre compte ne peut pas envoyer ce signalement.');
      }

      final relationRows = await transaction.rawQuery(
        '''
        SELECT
          bookings.trip_id,
          bookings.passenger_id,
          bookings.status AS booking_status,
          trips.driver_id,
          driver.role AS driver_role,
          passenger.role AS passenger_role
        FROM bookings
        INNER JOIN trips ON trips.id = bookings.trip_id
        INNER JOIN users AS driver ON driver.id = trips.driver_id
        INNER JOIN users AS passenger ON passenger.id = bookings.passenger_id
        WHERE bookings.id = ?
        LIMIT 1
      ''',
        [bookingId],
      );
      if (relationRows.isEmpty) {
        throw StateError('La réservation ou le trajet est introuvable.');
      }
      final relation = relationRows.first;
      final bookingStatus = relation['booking_status'];
      if (bookingStatus != 'pending' && bookingStatus != 'accepted') {
        throw StateError('Cette réservation ne permet plus de signalement.');
      }

      final targetId = reporterRole == 'passenger'
          ? relation['driver_id'] as int
          : relation['passenger_id'] as int;
      final actualTargetRole = reporterRole == 'passenger'
          ? relation['driver_role']
          : relation['passenger_role'];
      final ownsRelation = reporterRole == 'passenger'
          ? relation['passenger_id'] == reporterId
          : relation['driver_id'] == reporterId;
      if (targetId == reporterId) {
        throw StateError('Vous ne pouvez pas signaler votre propre compte.');
      }
      if (!ownsRelation || actualTargetRole != targetRole) {
        throw StateError('Cette réservation ne vous est pas associée.');
      }

      final report = Report(
        reporterId: reporterId,
        reportedUserId: targetId,
        tripId: relation['trip_id'] as int,
        reason: normalizedReason,
        description: description?.trim().isNotEmpty == true
            ? description!.trim()
            : null,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );
      return transaction.insert('reports', report.toMap());
    });
  }

  Future<List<Report>> getAllReports() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '$_joinedSelect ORDER BY reports.created_at DESC, reports.id DESC',
    );
    return rows.map(Report.fromMap).toList(growable: false);
  }

  Future<List<Report>> getReportsForUser(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '$_joinedSelect WHERE reports.reporter_id = ? '
      'ORDER BY reports.created_at DESC, reports.id DESC',
      [userId],
    );
    return rows.map(Report.fromMap).toList(growable: false);
  }

  Future<Report?> getReportById(int reportId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '$_joinedSelect WHERE reports.id = ? LIMIT 1',
      [reportId],
    );
    return rows.isEmpty ? null : Report.fromMap(rows.first);
  }

  Future<ReportCounts> getReportCounts() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending,
        SUM(CASE WHEN status = 'reviewed' THEN 1 ELSE 0 END) AS reviewed,
        SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) AS resolved
      FROM reports
    ''');
    final row = rows.first;
    return ReportCounts(
      total: row['total'] as int? ?? 0,
      pending: row['pending'] as int? ?? 0,
      reviewed: row['reviewed'] as int? ?? 0,
      resolved: row['resolved'] as int? ?? 0,
    );
  }

  Future<int> updateStatus({
    required int reportId,
    required String status,
  }) async {
    if (status != 'reviewed' && status != 'resolved') {
      throw ArgumentError.value(status, 'status');
    }
    final db = await _databaseHelper.database;
    return db.transaction<int>((transaction) async {
      final rows = await transaction.query(
        'reports',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [reportId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Signalement introuvable.');
      final current = rows.first['status'] as String? ?? 'pending';
      final canReview = status == 'reviewed' && current == 'pending';
      final canResolve = status == 'resolved' && current == 'reviewed';
      if (!canReview && !canResolve) {
        throw StateError(
          'Le statut du signalement a changé. Actualisez la liste.',
        );
      }
      final changed = await transaction.update(
        'reports',
        {'status': status},
        where: 'id = ? AND status = ?',
        whereArgs: [reportId, current],
      );
      if (changed != 1) {
        throw StateError(
          'Le statut du signalement a changé. Actualisez la liste.',
        );
      }
      return changed;
    });
  }
}
