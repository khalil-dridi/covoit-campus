import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:covoit_campus/models/trip.dart';
import 'package:covoit_campus/services/trip_matching_service.dart';

void main() {
  const matcher = TripMatchingService();
  const tunis = LatLng(36.8065, 10.1815);
  const sousse = LatLng(35.8256, 10.63699);
  // City-center coordinates used for a realistic nearby case: Ariana and Monastir.
  const ariana = LatLng(36.8625, 10.1956);
  const monastir = LatLng(35.777, 10.8262);
  final now = DateTime(2026, 1, 1, 8);

  List<TripMatch> run(Iterable<Trip> trips) => matcher.matchTrips(
    candidates: trips,
    requestedDeparture: tunis,
    requestedDestination: sousse,
    passengerId: 99,
    seats: 1,
    now: now,
  );

  test('exact Tunis to Sousse is an exact match', () {
    final matches = run([_trip(start: tunis, end: sousse)]);

    expect(matches, hasLength(1));
    expect(matches.single.type, TripMatchType.exact);
    expect(matches.single.relevanceScore, 100);
  });

  test('Ariana to Monastir is a nearby match within both 20 km limits', () {
    final matches = run([_trip(start: ariana, end: monastir)]);

    expect(matches, hasLength(1));
    expect(matches.single.type, TripMatchType.nearby);
    expect(matches.single.departureDistanceKm, lessThan(20));
    expect(matches.single.destinationDistanceKm, lessThan(20));
  });

  test('rejects a departure or destination more than 20 km away', () {
    expect(run([_trip(start: const LatLng(37.1, 10.2), end: sousse)]), isEmpty);
    expect(run([_trip(start: tunis, end: const LatLng(35.55, 10.8))]), isEmpty);
  });

  test('rejects an itinerary in the reverse direction', () {
    expect(run([_trip(start: monastir, end: ariana)]), isEmpty);
  });

  test('missing and invalid trip coordinates are not matches', () {
    expect(run([_trip(start: null, end: sousse)]), isEmpty);
    expect(run([_trip(start: const LatLng(91, 10), end: sousse)]), isEmpty);
  });

  test(
    'exact matches rank before nearby matches, then by score descending',
    () {
      final lowerScore = _trip(start: ariana, end: monastir, id: 1);
      final higherScore = _trip(
        start: const LatLng(36.82, 10.19),
        end: const LatLng(35.83, 10.64),
        id: 2,
      );
      final exact = _trip(start: tunis, end: sousse, id: 3);

      final matches = run([lowerScore, higherScore, exact]);

      expect(matches.map((match) => match.trip.id), [3, 2, 1]);
    },
  );

  test('existing sort selection is used as a tie-breaker', () {
    final expensive = _trip(start: tunis, end: sousse, id: 1, price: 20);
    final cheaper = _trip(start: tunis, end: sousse, id: 2, price: 10);
    final matches = matcher.matchTrips(
      candidates: [expensive, cheaper],
      requestedDeparture: tunis,
      requestedDestination: sousse,
      passengerId: 99,
      seats: 1,
      now: now,
      tieBreakSort: 'cheapest',
    );

    expect(matches.map((match) => match.trip.id), [2, 1]);
  });

  test(
    'rejects full, past, inactive, wrong-role and mismatched-vehicle trips',
    () {
      final full = _trip(start: tunis, end: sousse, availableSeats: 0);
      final past = _trip(
        start: tunis,
        end: sousse,
        departureDate: '2025-12-31',
      );
      final inactive = _trip(start: tunis, end: sousse, driverIsActive: false);
      final wrongRole = _trip(
        start: tunis,
        end: sousse,
        driverRole: 'passenger',
      );
      final wrongVehicle = _trip(
        start: tunis,
        end: sousse,
        vehicleBelongsToDriver: false,
      );

      expect(run([full, past, inactive, wrongRole, wrongVehicle]), isEmpty);
    },
  );

  test('excludes the passenger own trip and enforces requested date/time', () {
    final own = _trip(start: tunis, end: sousse, driverId: 99);
    final laterDate = _trip(
      start: tunis,
      end: sousse,
      departureDate: '2026-01-02',
    );
    final earlierTime = _trip(
      start: tunis,
      end: sousse,
      departureTime: '07:30',
    );

    expect(run([own]), isEmpty);
    expect(
      matcher.matchTrips(
        candidates: [laterDate, earlierTime],
        requestedDeparture: tunis,
        requestedDestination: sousse,
        passengerId: 99,
        seats: 1,
        now: now,
        departureDate: '2026-01-01',
        departureTime: '08:00',
      ),
      isEmpty,
    );
  });
}

Trip _trip({
  required LatLng? start,
  required LatLng? end,
  int id = 1,
  int driverId = 5,
  double price = 10,
  int availableSeats = 3,
  String departureDate = '2026-01-01',
  String departureTime = '09:00',
  bool driverIsActive = true,
  String driverRole = 'driver',
  bool vehicleBelongsToDriver = true,
}) => Trip(
  id: id,
  driverId: driverId,
  vehicleId: 7,
  departure: 'Départ',
  destination: 'Destination',
  departureLatitude: start?.latitude,
  departureLongitude: start?.longitude,
  arrivalLatitude: end?.latitude,
  arrivalLongitude: end?.longitude,
  departureDate: departureDate,
  departureTime: departureTime,
  totalSeats: 3,
  availableSeats: availableSeats,
  price: price,
  createdAt: '2025-12-01T10:00:00',
  updatedAt: '2025-12-01T10:00:00',
  driverIsActive: driverIsActive,
  driverRole: driverRole,
  vehicleBelongsToDriver: vehicleBelongsToDriver,
);
