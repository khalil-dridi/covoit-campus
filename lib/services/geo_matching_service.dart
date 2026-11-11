import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Computes direct, great-circle distances. This is not a road distance.
class GeoMatchingService {
  const GeoMatchingService();

  static const double _earthRadiusKm = 6371.0088;
  static const double maximumTripValidationDistanceMeters = 2000;

  /// Returns null for missing or invalid coordinates.
  double? distanceKm(LatLng? first, LatLng? second) {
    if (!_isValid(first) || !_isValid(second)) return null;

    final lat1 = _toRadians(first!.latitude);
    final lat2 = _toRadians(second!.latitude);
    final deltaLat = lat2 - lat1;
    final deltaLon = _toRadians(second.longitude - first.longitude);
    final haversine =
        math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
    final bounded = haversine.clamp(0.0, 1.0).toDouble();
    return 2 * _earthRadiusKm * math.asin(math.sqrt(bounded));
  }

  bool isWithinTripValidationDistanceKm(double distanceKm) =>
      distanceKm.isFinite &&
      distanceKm >= 0 &&
      distanceKm * 1000 <= maximumTripValidationDistanceMeters;

  bool _isValid(LatLng? point) =>
      point != null &&
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude >= -180 &&
      point.longitude <= 180;

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
