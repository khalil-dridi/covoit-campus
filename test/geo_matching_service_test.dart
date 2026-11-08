import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:covoit_campus/services/geo_matching_service.dart';

void main() {
  const service = GeoMatchingService();

  test('identical coordinates have zero distance', () {
    expect(
      service.distanceKm(
        const LatLng(36.8065, 10.1815),
        const LatLng(36.8065, 10.1815),
      ),
      0,
    );
  });

  test('Tunis to Sousse uses the direct great-circle distance', () {
    // City-center coordinates: Tunis (36.8065, 10.1815), Sousse (35.8256, 10.63699).
    final distance = service.distanceKm(
      const LatLng(36.8065, 10.1815),
      const LatLng(35.8256, 10.63699),
    );

    expect(distance, isNotNull);
    expect(distance!, greaterThan(110));
    expect(distance, lessThan(120));
  });

  test('missing and invalid coordinates do not produce distances', () {
    expect(service.distanceKm(null, const LatLng(36.8, 10.1)), isNull);
    expect(
      service.distanceKm(const LatLng(91, 10), const LatLng(36.8, 10.1)),
      isNull,
    );
    expect(
      service.distanceKm(
        const LatLng(36.8, double.nan),
        const LatLng(36.8, 10.1),
      ),
      isNull,
    );
  });
}
