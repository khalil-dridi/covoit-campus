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
    'report joins, counts, and pending to reviewed to resolved lifecycle',
    () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();
      final unique = DateTime.now().microsecondsSinceEpoch;
      final reporterId = await db.insert('users', {
        'full_name': 'Report Author',
        'email': 'report-author-$unique@test.invalid',
        'password_hash': 'test-only',
        'role': 'passenger',
        'is_active': 1,
        'is_verified': 1,
        'created_at': now,
        'updated_at': now,
      });
      final targetId = await db.insert('users', {
        'full_name': 'Reported Member',
        'email': 'report-target-$unique@test.invalid',
        'password_hash': 'test-only',
        'role': 'driver',
        'is_active': 1,
        'is_verified': 1,
        'created_at': now,
        'updated_at': now,
      });
      final reportId = await db.insert('reports', {
        'reporter_id': reporterId,
        'reported_user_id': targetId,
        'trip_id': null,
        'reason': 'Comportement inapproprié',
        'description': 'Description de contrôle',
        'status': 'pending',
        'created_at': now,
      });
      addTearDown(() async {
        await db.delete('reports', where: 'id = ?', whereArgs: [reportId]);
        await db.delete(
          'users',
          where: 'id IN (?, ?)',
          whereArgs: [reporterId, targetId],
        );
      });

      final repository = ReportRepository();
      final all = await repository.getAllReports();
      final report = all.firstWhere((item) => item.id == reportId);
      expect(report.reporterName, 'Report Author');
      expect(report.reportedUserName, 'Reported Member');
      expect(report.tripId, isNull);
      expect(report.status, 'pending');
      expect(
        (await repository.getReportById(reportId))?.description,
        'Description de contrôle',
      );

      var counts = await repository.getReportCounts();
      expect(counts.total, greaterThanOrEqualTo(1));
      expect(counts.pending, greaterThanOrEqualTo(1));
      expect(
        await repository.updateStatus(reportId: reportId, status: 'reviewed'),
        1,
      );
      counts = await repository.getReportCounts();
      expect(counts.reviewed, greaterThanOrEqualTo(1));
      expect((await repository.getReportById(reportId))?.status, 'reviewed');

      expect(
        await repository.updateStatus(reportId: reportId, status: 'resolved'),
        1,
      );
      counts = await repository.getReportCounts();
      expect(counts.resolved, greaterThanOrEqualTo(1));
      expect((await repository.getReportById(reportId))?.status, 'resolved');
      await expectLater(
        repository.updateStatus(reportId: reportId, status: 'reviewed'),
        throwsA(isA<StateError>()),
      );
    },
  );
}
