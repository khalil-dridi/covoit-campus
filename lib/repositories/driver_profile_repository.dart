import '../database/database_helper.dart';
import '../services/carbon_savings_service.dart';
import 'rating_repository.dart';

class DriverPreferences {
  final bool smokingAllowed;
  final bool petsAllowed;
  final bool musicAllowed;
  final String conversation;

  const DriverPreferences({
    required this.smokingAllowed,
    required this.petsAllowed,
    required this.musicAllowed,
    required this.conversation,
  });

  factory DriverPreferences.defaults() => const DriverPreferences(
    smokingAllowed: false,
    petsAllowed: false,
    musicAllowed: true,
    conversation: 'Modérée',
  );

  factory DriverPreferences.fromMap(Map<String, Object?> map) =>
      DriverPreferences(
        smokingAllowed: map['smoking_allowed'] == 1,
        petsAllowed: map['pets_allowed'] == 1,
        musicAllowed: map['music_allowed'] == 1,
        conversation: map['conversation_allowed'] == 1 ? 'Modérée' : 'Limitée',
      );
}

class DriverProfileStats {
  final int completedTrips;
  final double? rating;
  final int ratingCount;
  final double co2SavedGrams;

  const DriverProfileStats({
    required this.completedTrips,
    required this.rating,
    required this.ratingCount,
    required this.co2SavedGrams,
  });
}

class DriverProfileRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<DriverPreferences> getPreferences(int userId) async {
    return await getSavedPreferences(userId) ?? DriverPreferences.defaults();
  }

  Future<DriverPreferences?> getSavedPreferences(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'preferences',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : DriverPreferences.fromMap(rows.first);
  }

  Future<void> savePreferences(
    int userId,
    DriverPreferences preferences,
  ) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final rows = await db.query(
      'preferences',
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final values = <String, Object?>{
      'smoking_allowed': preferences.smokingAllowed ? 1 : 0,
      'pets_allowed': preferences.petsAllowed ? 1 : 0,
      'music_allowed': preferences.musicAllowed ? 1 : 0,
      'conversation_allowed': preferences.conversation == 'Modérée' ? 1 : 0,
      'updated_at': now,
    };

    if (rows.isEmpty) {
      await db.insert('preferences', {
        'user_id': userId,
        ...values,
        'created_at': now,
      });
    } else {
      await db.update(
        'preferences',
        values,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  Future<DriverProfileStats> getStats(int userId) async {
    final db = await _databaseHelper.database;
    final tripRows = await db.rawQuery(
      "SELECT COUNT(*) AS trip_count FROM trips WHERE driver_id = ? AND status = 'completed'",
      [userId],
    );
    final ratingStats = await RatingRepository().getPublicStats(userId);
    final co2SavedGrams = await CarbonSavingsService().getUserTotalSavingsGrams(
      userId,
    );
    final tripCount = tripRows.first['trip_count'] as int? ?? 0;

    return DriverProfileStats(
      completedTrips: tripCount,
      rating: ratingStats.average,
      ratingCount: ratingStats.count,
      co2SavedGrams: co2SavedGrams,
    );
  }
}
