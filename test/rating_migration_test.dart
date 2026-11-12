import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'ratings migration preserves legacy duplicates and reports bad scores',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);

      await db.execute('''
      CREATE TABLE ratings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        reviewer_id INTEGER NOT NULL,
        reviewed_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL
      )
    ''');
      for (final score in [5, 4, 8]) {
        await db.insert('ratings', {
          'trip_id': score == 8 ? 2 : 1,
          'reviewer_id': 10,
          'reviewed_id': 20,
          'score': score,
          'comment': null,
          'created_at': '2026-01-01T00:00:00.000',
        });
      }

      final audit = await DatabaseHelper.migrateRatingsIndexes(db);

      expect(audit.duplicateRows, 1);
      expect(audit.outOfRangeScores, 1);
      expect(await db.rawQuery('PRAGMA table_info(ratings)'), isNotEmpty);
      final ratings = await db.query('ratings', orderBy: 'id');
      expect(ratings, hasLength(3));
      expect(ratings.map((row) => row['score']), [5, 4, 8]);
      expect(ratings.map((row) => row['is_legacy_duplicate']), [0, 1, 0]);

      final indexes = await db.rawQuery('PRAGMA index_list(ratings)');
      expect(
        indexes.map((row) => row['name']),
        containsAll([
          'idx_ratings_trip_reviewer_reviewed',
          'idx_ratings_reviewed_created',
          'idx_ratings_reviewer_created',
        ]),
      );
      await expectLater(
        db.insert('ratings', {
          'trip_id': 1,
          'reviewer_id': 10,
          'reviewed_id': 20,
          'score': 3,
          'created_at': '2026-01-02T00:00:00.000',
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test('ratings migration can be applied more than once', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('''
      CREATE TABLE ratings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        reviewer_id INTEGER NOT NULL,
        reviewed_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await DatabaseHelper.migrateRatingsIndexes(db);
    final secondAudit = await DatabaseHelper.migrateRatingsIndexes(db);
    expect(secondAudit.duplicateRows, 0);
    expect(secondAudit.outOfRangeScores, 0);
  });
}
