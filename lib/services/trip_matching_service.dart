import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import 'geo_matching_service.dart';

enum TripMatchType { exact, nearby, unranked }

class TripMatch {
  final Trip trip;
  final TripMatchType type;
  final double? departureDistanceKm;
  final double? destinationDistanceKm;
  final double? relevanceScore;

  const TripMatch({
    required this.trip,
    required this.type,
    required this.departureDistanceKm,
    required this.destinationDistanceKm,
    required this.relevanceScore,
  });
}

/// Applies endpoint proximity and ranking rules to repository candidates.
class TripMatchingService {
  static const double maximumDistanceKm = 20;
  static const double _exactToleranceKm = 0.001;

  final GeoMatchingService _geoMatchingService;

  const TripMatchingService({GeoMatchingService? geoMatchingService})
    : _geoMatchingService = geoMatchingService ?? const GeoMatchingService();

  List<TripMatch> matchTrips({
    required Iterable<Trip> candidates,
    required LatLng? requestedDeparture,
    required LatLng? requestedDestination,
    required int passengerId,
    required int seats,
    required DateTime now,
    String? departureDate,
    String? departureTime,
    bool flexibleTime = false,
    String tieBreakSort = 'earliest',
  }) {
    if (!_isValidPoint(requestedDeparture) ||
        !_isValidPoint(requestedDestination)) {
      return const [];
    }

    final matches = <TripMatch>[];
    for (final trip in candidates) {
      if (trip.driverId == passengerId ||
          trip.status != 'available' ||
          trip.availableSeats < (seats < 1 ? 1 : seats) ||
          trip.driverIsActive != true ||
          trip.driverRole != 'driver' ||
          !trip.vehicleBelongsToDriver) {
        continue;
      }

      final tripDate = DateTime.tryParse(trip.departureDate);
      final timeParts = trip.departureTime.split(':');
      if (tripDate == null || timeParts.length < 2) continue;
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null || hour > 23 || minute > 59) {
        continue;
      }
      final departure = DateTime(
        tripDate.year,
        tripDate.month,
        tripDate.day,
        hour,
        minute,
      );
      if (!departure.isAfter(now)) continue;
      if (departureDate != null && trip.departureDate != departureDate) {
        continue;
      }
      if (!_matchesTime(departure, departureTime, flexibleTime)) continue;

      final tripDeparture = _point(
        trip.departureLatitude,
        trip.departureLongitude,
      );
      final tripDestination = _point(
        trip.arrivalLatitude,
        trip.arrivalLongitude,
      );
      final departureDistance = _geoMatchingService.distanceKm(
        requestedDeparture,
        tripDeparture,
      );
      final destinationDistance = _geoMatchingService.distanceKm(
        requestedDestination,
        tripDestination,
      );
      if (departureDistance == null || destinationDistance == null) continue;
      if (departureDistance > maximumDistanceKm ||
          destinationDistance > maximumDistanceKm) {
        continue;
      }
      if (!_sameDirection(
        requestedDeparture!,
        requestedDestination!,
        tripDeparture!,
        tripDestination!,
      )) {
        continue;
      }

      final exact =
          departureDistance <= _exactToleranceKm &&
          destinationDistance <= _exactToleranceKm;
      // Each endpoint contributes half of the score, linearly normalized over
      // the 20 km acceptance radius. A zero-distance match scores 100.
      final score =
          (100 *
                  (1 -
                      ((departureDistance / maximumDistanceKm) +
                              (destinationDistance / maximumDistanceKm)) /
                          2))
              .clamp(0.0, 100.0)
              .toDouble();
      matches.add(
        TripMatch(
          trip: trip,
          type: exact ? TripMatchType.exact : TripMatchType.nearby,
          departureDistanceKm: departureDistance,
          destinationDistanceKm: destinationDistance,
          relevanceScore: score,
        ),
      );
    }

    matches.sort((first, second) {
      if (first.type != second.type) {
        return first.type == TripMatchType.exact ? -1 : 1;
      }
      if (first.relevanceScore != null && second.relevanceScore != null) {
        final scoreComparison =
            second.relevanceScore!.compareTo(first.relevanceScore!);
        if (scoreComparison != 0) return scoreComparison;
      }
      final timeComparison = _compareDeparture(first.trip, second.trip);
      switch (tieBreakSort) {
        case 'cheapest':
          final priceComparison = first.trip.price.compareTo(second.trip.price);
          return priceComparison == 0 ? timeComparison : priceComparison;
        case 'bestRated':
          final firstRating = first.trip.driverRating ?? -1;
          final secondRating = second.trip.driverRating ?? -1;
          final ratingComparison = secondRating.compareTo(firstRating);
          return ratingComparison == 0 ? timeComparison : ratingComparison;
        default:
          return timeComparison;
      }
    });
    return List.unmodifiable(matches);
  }

  bool _matchesTime(DateTime trip, String? requested, bool flexible) {
    if (requested == null || requested.trim().isEmpty) return true;
    final parts = requested.split(':');
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return false;
    }
    final tripMinutes = trip.hour * 60 + trip.minute;
    final requestedMinutes = hour * 60 + minute;
    final difference = tripMinutes - requestedMinutes;
    return flexible ? difference.abs() <= 60 : difference >= 0;
  }

  int _compareDeparture(Trip first, Trip second) {
    final dateComparison = first.departureDate.compareTo(second.departureDate);
    return dateComparison == 0
        ? first.departureTime.compareTo(second.departureTime)
        : dateComparison;
  }

  LatLng? _point(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    final point = LatLng(latitude, longitude);
    return _isValidPoint(point) ? point : null;
  }

  bool _isValidPoint(LatLng? point) =>
      point != null &&
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude >= -180 &&
      point.longitude <= 180;

  bool _sameDirection(
    LatLng requestedStart,
    LatLng requestedEnd,
    LatLng tripStart,
    LatLng tripEnd,
  ) {
    final requestedVector = _localVector(requestedStart, requestedEnd);
    final tripVector = _localVector(tripStart, tripEnd);
    final requestedLength =
        requestedVector.$1 * requestedVector.$1 +
        requestedVector.$2 * requestedVector.$2;
    final tripLength =
        tripVector.$1 * tripVector.$1 + tripVector.$2 * tripVector.$2;
    if (requestedLength == 0 || tripLength == 0) return false;
    return requestedVector.$1 * tripVector.$1 +
            requestedVector.$2 * tripVector.$2 >
        0;
  }

  (double, double) _localVector(LatLng start, LatLng end) {
    const radians = 0.017453292519943295;
    final meanLatitude = (start.latitude + end.latitude) / 2;
    final north = end.latitude - start.latitude;
    final east =
        (end.longitude - start.longitude) *
        radians *
        6371.0088 *
        math.cos(meanLatitude * radians);
    return (east, north * radians * 6371.0088);
  }
}
