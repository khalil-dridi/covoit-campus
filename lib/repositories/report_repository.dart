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

  Future<List<Report>> getAllReports() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '$_joinedSelect ORDER BY reports.created_at DESC, reports.id DESC',
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
