import 'dart:async';
import 'dart:io';

import 'package:covoit_campus/screens/driver/publish/location_picker_screen.dart';
import 'package:covoit_campus/services/location_service.dart';
import 'package:covoit_campus/services/place_geocoding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const medjezFeature = {
    'name': 'Medjez El Bab',
    'city': 'Medjez El Bab',
    'country': 'Tunisie',
    'lat': 36.649,
    'lon': 9.613,
  };
  const tunisFeature = {
    'name': 'Tunis',
    'city': 'Tunis',
    'country': 'Tunisie',
    'lat': 36.8065,
    'lon': 10.1815,
  };

  PlaceGeocodingService serviceWith(
    Future<Map<String, dynamic>> Function(Uri) loader, {
    Duration timeout = const Duration(seconds: 1),
  }) => PlaceGeocodingService(
    loadJson: loader,
    apiKey: 'test-api-key',
    minimumRequestGap: Duration.zero,
    requestTimeout: timeout,
  );

  test(
    'search finds Medjez El Bab and Tunis and returns coordinates',
    () async {
      final service = serviceWith((uri) async {
        expect(uri.host, 'api.geoapify.com');
        expect(uri.path, '/v1/geocode/autocomplete');
        expect(uri.queryParameters['format'], 'json');
        expect(uri.queryParameters['apiKey'], 'test-api-key');
        expect(uri.queryParameters['lang'], 'fr');
        final query = uri.queryParameters['text'];
        return {
          'results': [
            if (query == 'Medjez El Bab') medjezFeature,
            if (query == 'Tunis') tunisFeature,
          ],
        };
      });

      final medjez = await service.search('Medjez El Bab');
      final tunis = await service.search('Tunis');

      expect(medjez.single.label, 'Medjez El Bab');
      expect(medjez.single.point, const LatLng(36.649, 9.613));
      expect(tunis.single.label, 'Tunis');
      expect(tunis.single.point, const LatLng(36.8065, 10.1815));
    },
  );

  test('unknown place returns an empty result list', () async {
    final service = serviceWith((_) async => {'results': []});

    expect(await service.search('Lieu inexistant xyz'), isEmpty);
  });

  test('empty autocomplete falls back to forward geocoding', () async {
    final requestedPaths = <String>[];
    final service = serviceWith((uri) async {
      requestedPaths.add(uri.path);
      return uri.path.endsWith('/search')
          ? {
              'results': [tunisFeature],
            }
          : {'results': []};
    });

    expect((await service.search('Tunis')).single.label, 'Tunis');
    expect(requestedPaths, ['/v1/geocode/autocomplete', '/v1/geocode/search']);
  });

  test(
    'reverse geocoding returns coordinates and accepts empty results',
    () async {
      final service = serviceWith((uri) async {
        expect(uri.path, '/v1/geocode/reverse');
        expect(uri.queryParameters['lat'], '36.806500');
        expect(uri.queryParameters['lon'], '10.181500');
        return {
          'results': [tunisFeature],
        };
      });

      final result = await service.reverse(const LatLng(36.8065, 10.1815));
      expect(result?.label, 'Tunis');
      expect(result?.point, const LatLng(36.8065, 10.1815));

      final emptyService = serviceWith((_) async => {'results': []});
      expect(await emptyService.reverse(const LatLng(0, 0)), isNull);
    },
  );

  test('missing API key is reported clearly', () async {
    final service = PlaceGeocodingService(
      apiKey: '',
      minimumRequestGap: Duration.zero,
      loadJson: (_) async => {'results': []},
    );

    await expectLater(
      service.search('Tunis'),
      throwsA(
        isA<GeocodingException>().having(
          (error) => error.message,
          'message',
          contains('GEOAPIFY_API_KEY'),
        ),
      ),
    );
  });

  test('network failure is reported as a readable geocoding error', () async {
    final service = serviceWith(
      (_) async => throw const SocketException('offline'),
    );

    await expectLater(
      service.search('Tunis'),
      throwsA(
        isA<GeocodingException>().having(
          (error) => error.message,
          'message',
          contains('Vérifiez Internet'),
        ),
      ),
    );
  });

  test(
    'a stalled response times out instead of waiting indefinitely',
    () async {
      final service = serviceWith(
        (_) => Completer<Map<String, dynamic>>().future,
        timeout: const Duration(milliseconds: 30),
      );

      await expectLater(
        service.search('Tunis'),
        throwsA(
          isA<GeocodingException>().having(
            (error) => error.message,
            'message',
            contains('trop de temps'),
          ),
        ),
      );
    },
  );

  testWidgets('search result can be selected and keeps its GPS point', (
    tester,
  ) async {
    final service = serviceWith(
      (uri) async => {
        'results': uri.queryParameters['text'] == 'Medjez El Bab'
            ? [medjezFeature]
            : [],
      },
    );
    final harnessKey = GlobalKey<_PickerHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: _PickerHarness(
          key: harnessKey,
          geocodingService: service,
          locationService: _FakeLocationService(const LatLng(36.9, 10.2)),
        ),
      ),
    );
    await tester.tap(find.text('Choisir un emplacement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Medjez El Bab');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();
    expect(find.text('Medjez El Bab'), findsWidgets);
    await tester.tap(find.text('Medjez El Bab').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer cet emplacement'));
    await tester.pumpAndSettle();

    expect(harnessKey.currentState!.selection?.label, 'Medjez El Bab');
    expect(
      harnessKey.currentState!.selection?.point,
      const LatLng(36.649, 9.613),
    );
  });

  testWidgets('manual map movement and Ma position preserve GPS coordinates', (
    tester,
  ) async {
    final harnessKey = GlobalKey<_PickerHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: _PickerHarness(
          key: harnessKey,
          geocodingService: serviceWith((_) async => {'results': []}),
          locationService: _FakeLocationService(const LatLng(36.9, 10.2)),
        ),
      ),
    );
    await tester.tap(find.text('Choisir un emplacement'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ma position'));
    await tester.pumpAndSettle();
    expect(find.text('Ma position'), findsOneWidget);
    expect(find.text('36.90000, 10.20000'), findsOneWidget);

    final mapCenter = tester.getCenter(find.byType(FlutterMap));
    await tester.dragFrom(mapCenter, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer cet emplacement'));
    await tester.pumpAndSettle();

    final selected = harnessKey.currentState!.selection!;
    expect(selected.point, isNot(const LatLng(36.9, 10.2)));
    expect(selected.point.latitude, inInclusiveRange(-90, 90));
    expect(selected.point.longitude, inInclusiveRange(-180, 180));
  });
}

class _FakeLocationService extends LocationService {
  final LatLng point;
  _FakeLocationService(this.point);

  @override
  Future<LatLng> getCurrentLocation() async => point;
}

class _PickerHarness extends StatefulWidget {
  final PlaceGeocodingService geocodingService;
  final LocationService locationService;

  const _PickerHarness({
    super.key,
    required this.geocodingService,
    required this.locationService,
  });

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  LocationSelection? selection;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () async {
              selection = await Navigator.of(context).push<LocationSelection>(
                MaterialPageRoute(
                  builder: (_) => LocationPickerScreen(
                    title: 'Ville de départ',
                    initialPoint: const LatLng(36.8065, 10.1815),
                    locationService: widget.locationService,
                    geocodingService: widget.geocodingService,
                    showMapTiles: false,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            child: const Text('Choisir un emplacement'),
          ),
          if (selection != null)
            Text(
              '${selection!.label} ${selection!.point.latitude}, ${selection!.point.longitude}',
            ),
        ],
      ),
    ),
  );
}
