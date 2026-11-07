import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

class PlaceSearchResult {
  final String name;
  final String subtitle;
  final String label;
  final LatLng point;

  const PlaceSearchResult({
    required this.name,
    required this.subtitle,
    required this.label,
    required this.point,
  });
}

/// Photon-backed OSM geocoder. Requests are serialized and cached in memory
/// to keep use of the shared public instance reasonable.
class PlaceGeocodingService {
  static const _baseHost = 'photon.komoot.io';
  static const _minimumRequestGap = Duration(seconds: 1);
  static Future<void> _requestQueue = Future<void>.value();
  static DateTime? _lastRequestAt;

  final Map<String, List<PlaceSearchResult>> _searchCache = {};
  final Map<String, PlaceSearchResult?> _reverseCache = {};

  Future<List<PlaceSearchResult>> search(String query, {LatLng? near}) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return const [];
    final cacheKey = near == null
        ? normalized
        : '$normalized:${near.latitude.toStringAsFixed(2)},${near.longitude.toStringAsFixed(2)}';
    final cached = _searchCache[cacheKey];
    if (cached != null) return cached;

    final parameters = <String, String>{
      'q': query.trim(),
      'lang': 'fr',
      'limit': '7',
    };
    if (near != null) {
      parameters['lat'] = near.latitude.toStringAsFixed(4);
      parameters['lon'] = near.longitude.toStringAsFixed(4);
    }
    final payload = await _getJson(Uri.https(_baseHost, '/api/', parameters));
    final features = payload['features'] as List<dynamic>? ?? const [];
    final results = features
        .whereType<Map<String, dynamic>>()
        .map(_parseFeature)
        .whereType<PlaceSearchResult>()
        .toList(growable: false);
    _remember(_searchCache, cacheKey, results);
    return results;
  }

  Future<PlaceSearchResult?> reverse(LatLng point) async {
    final cacheKey =
        '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    if (_reverseCache.containsKey(cacheKey)) return _reverseCache[cacheKey];

    final payload = await _getJson(
      Uri.https(_baseHost, '/reverse', {
        'lat': point.latitude.toStringAsFixed(6),
        'lon': point.longitude.toStringAsFixed(6),
        'lang': 'fr',
      }),
    );
    final features = payload['features'] as List<dynamic>? ?? const [];
    final result = features
        .whereType<Map<String, dynamic>>()
        .map(_parseFeature)
        .whereType<PlaceSearchResult>()
        .firstOrNull;
    _remember(_reverseCache, cacheKey, result);
    return result;
  }

  PlaceSearchResult? _parseFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.length < 2) return null;
    final longitude = (coordinates[0] as num?)?.toDouble();
    final latitude = (coordinates[1] as num?)?.toDouble();
    if (longitude == null || latitude == null) return null;

    final properties =
        feature['properties'] as Map<String, dynamic>? ?? const {};
    String? value(String key) {
      final raw = properties[key];
      final text = raw?.toString();
      return text == null || text.trim().isEmpty ? null : text.trim();
    }

    final locality =
        value('city') ?? value('town') ?? value('village') ?? value('county');
    final state = value('state');
    final street = [
      value('housenumber'),
      value('street'),
    ].whereType<String>().join(' ');
    final name =
        value('name') ?? (street.isNotEmpty ? street : null) ?? locality;
    if (name == null) return null;

    final subtitleParts = <String?>[
      if (street.isNotEmpty && street != name) street,
      value('postcode'),
      if (locality != null && locality != name) locality,
      if (state != null && state != locality && state != name) state,
      if (value('country') != name) value('country'),
    ];
    final subtitle = subtitleParts.whereType<String>().toSet().join(' · ');
    final labelParts = <String>[
      name,
      if (locality != null && locality != name) locality,
      if (state != null && state != locality && state != name) state,
    ];
    return PlaceSearchResult(
      name: name,
      subtitle: subtitle,
      label: labelParts.join(', '),
      point: LatLng(latitude, longitude),
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async => _throttle(() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'CovoitCampus/1.0');
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw GeocodingException(
          'Le service de recherche est momentanément indisponible.',
        );
      }
      return jsonDecode(await response.transform(utf8.decoder).join())
          as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  });

  Future<T> _throttle<T>(Future<T> Function() request) async {
    final previous = _requestQueue;
    final release = Completer<void>();
    _requestQueue = release.future;
    await previous;
    try {
      final last = _lastRequestAt;
      if (last != null) {
        final elapsed = DateTime.now().difference(last);
        if (elapsed < _minimumRequestGap) {
          await Future<void>.delayed(_minimumRequestGap - elapsed);
        }
      }
      return await request();
    } finally {
      _lastRequestAt = DateTime.now();
      release.complete();
    }
  }

  void _remember<T>(Map<String, T> cache, String key, T value) {
    cache.remove(key);
    cache[key] = value;
    if (cache.length > 80) cache.remove(cache.keys.first);
  }
}

class GeocodingException implements Exception {
  final String message;
  const GeocodingException(this.message);
  @override
  String toString() => message;
}
