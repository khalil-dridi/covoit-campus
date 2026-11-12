import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../database/database_helper.dart';
import 'geo_matching_service.dart';

class CarbonSavingsService {
  CarbonSavingsService({
    this.emissionFactorGramsPerKm = defaultEmissionFactorGramsPerKm,
  });

  static const double defaultEmissionFactorGramsPerKm = 120;
  static final ValueNotifier<int> statsRevision = ValueNotifier<int>(0);

  final double emissionFactorGramsPerKm;
  final GeoMatchingService _geoMatchingService = const GeoMatchingService();

  static void notifyStatsChanged() {
    statsRevision.value++;
  }

  static double? individualSavingsGrams({
    required double distanceKm,
    required int passengerCount,
    double emissionFactorGramsPerKm = defaultEmissionFactorGramsPerKm,
  }) {
    if (!distanceKm.isFinite ||
        distanceKm < 0 ||
        passengerCount < 0 ||
        !emissionFactorGramsPerKm.isFinite ||
        emissionFactorGramsPerKm < 0) {
      return null;
    }
    if (passengerCount == 0) return 0;
    final participantCount = passengerCount + 1;
    return distanceKm *
        emissionFactorGramsPerKm *
        passengerCount /
        participantCount;
  }

  Future<double> getUserTotalSavingsGrams(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT trips.departure_latitude, trips.departure_longitude,
        trips.arrival_latitude, trips.arrival_longitude,
        COUNT(DISTINCT trip_attendance.passenger_id) AS passenger_count
      FROM trips
      LEFT JOIN trip_attendance ON trip_attendance.trip_id = trips.id
      WHERE trips.status = 'completed'
        AND (trips.driver_id = ? OR EXISTS (
          SELECT 1 FROM trip_attendance AS own_attendance
          WHERE own_attendance.trip_id = trips.id
            AND own_attendance.passenger_id = ?
        ))
      GROUP BY trips.id
      ''',
      [userId, userId],
    );

    var total = 0.0;
    for (final row in rows) {
      final departure = _point(
        row['departure_latitude'],
        row['departure_longitude'],
      );
      final arrival = _point(row['arrival_latitude'], row['arrival_longitude']);
      final distance = _geoMatchingService.distanceKm(departure, arrival);
      if (distance == null) continue;
      final savings = individualSavingsGrams(
        distanceKm: distance,
        passengerCount: row['passenger_count'] as int? ?? 0,
        emissionFactorGramsPerKm: emissionFactorGramsPerKm,
      );
      if (savings != null) total += savings;
    }
    return total;
  }

  static LatLng? _point(Object? latitude, Object? longitude) {
    if (latitude is! num || longitude is! num) return null;
    return LatLng(latitude.toDouble(), longitude.toDouble());
  }

  static String formatGrams(double grams) {
    if (!grams.isFinite || grams <= 0) return '0 kg';
    if (grams < 1000) return '${grams.toStringAsFixed(0)} g';
    final kilograms = (grams / 1000).toStringAsFixed(1);
    return '${kilograms.endsWith('.0') ? kilograms.substring(0, kilograms.length - 2) : kilograms} kg';
  }
}
