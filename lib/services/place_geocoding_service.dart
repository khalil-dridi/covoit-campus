import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
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

typedef PlaceJsonLoader = Future<Map<String, dynamic>> Function(Uri uri);

/// Geoapify geocoder. Requests are serialized and cached in memory.
class PlaceGeocodingService {
  static const _baseHost = 'api.geoapify.com';
  static const _defaultMinimumRequestGap = Duration(seconds: 1);
  static const _defaultRequestTimeout = Duration(seconds: 12);
  static Future<void> _requestQueue = Future<void>.value();
  static DateTime? _lastRequestAt;

  final PlaceJsonLoader _loadJson;
  final String? _apiKeyOverride;
  final Duration minimumRequestGap;
  final Duration requestTimeout;

  PlaceGeocodingService({
    PlaceJsonLoader? loadJson,
    String? apiKey,
    this.minimumRequestGap = _defaultMinimumRequestGap,
    this.requestTimeout = _defaultRequestTimeout,
  }) : _loadJson = loadJson ?? _httpGetJson,
       _apiKeyOverride = apiKey;

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
      'text': query.trim(),
      'format': 'json',
      'apiKey': _requireApiKey(),
      'lang': 'fr',
      'limit': '7',
    };
    if (near != null) {
      parameters['bias'] =
          'proximity:${near.longitude.toStringAsFixed(4)},${near.latitude.toStringAsFixed(4)}';
    }
    var results = await _loadResults('/v1/geocode/autocomplete', parameters);
    // Autocomplete may have no prediction for a complete city/address query.
    // Try forward geocoding in that case while retaining the same public API.
    if (results.isEmpty) {
      results = await _loadResults('/v1/geocode/search', parameters);
    }
    _remember(_searchCache, cacheKey, results);
    return results;
  }

  Future<PlaceSearchResult?> reverse(LatLng point) async {
    final cacheKey =
        '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    if (_reverseCache.containsKey(cacheKey)) return _reverseCache[cacheKey];

    final payload = await _getJson(
      Uri.https(_baseHost, '/v1/geocode/reverse', {
        'lat': point.latitude.toStringAsFixed(6),
        'lon': point.longitude.toStringAsFixed(6),
        'format': 'json',
        'apiKey': _requireApiKey(),
        'lang': 'fr',
      }),
    );
    final results = _resultItems(payload);
    final result = results
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
    final longitude = _coordinate(
      coordinates != null && coordinates.length >= 2
          ? coordinates[0]
          : feature['lon'],
    );
    final latitude = _coordinate(
      coordinates != null && coordinates.length >= 2
          ? coordinates[1]
          : feature['lat'],
    );
    if (longitude == null ||
        latitude == null ||
        !longitude.isFinite ||
        !latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    final properties =
        feature['properties'] as Map<String, dynamic>? ?? feature;
    String? value(String key) {
      final raw = properties[key];
      final text = raw?.toString();
      return text == null || text.trim().isEmpty ? null : text.trim();
    }

    final locality =
        value('city') ??
        value('town') ??
        value('village') ??
        value('county') ??
        value('municipality');
    final state = value('state');
    final street = [
      value('housenumber'),
      value('street') ?? value('road'),
    ].whereType<String>().join(' ');
    final name =
        value('name') ??
        value('address_line1') ??
        (street.isNotEmpty ? street : null) ??
        locality ??
        value('formatted');
    if (name == null) return null;

    final subtitleParts = <String?>[
      if (street.isNotEmpty && street != name) street,
      value('postcode'),
      if (locality != null && locality != name) locality,
      if (state != null && state != locality && state != name) state,
      if (value('address_line2') != name) value('address_line2'),
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

  double? _coordinate(Object? value) => switch (value) {
    num number => number.toDouble(),
    String text => double.tryParse(text),
    _ => null,
  };

  Future<List<PlaceSearchResult>> _loadResults(
    String path,
    Map<String, String> parameters,
  ) async {
    final payload = await _getJson(Uri.https(_baseHost, path, parameters));
    return _resultItems(payload)
        .whereType<Map<String, dynamic>>()
        .map(_parseFeature)
        .whereType<PlaceSearchResult>()
        .toList(growable: false);
  }

  List<dynamic> _resultItems(Map<String, dynamic> payload) {
    final results = payload['results'];
    if (results is List<dynamic>) return results;
    final features = payload['features'];
    return features is List<dynamic> ? features : const [];
  }

  String _requireApiKey() {
    final key =
        _apiKeyOverride ??
        (dotenv.isInitialized ? dotenv.env['GEOAPIFY_API_KEY'] ?? '' : '');
    if (key.trim().isEmpty) {
      throw const GeocodingException(
        'La clé Geoapify est absente. Lancez l’application avec '
        '--dart-define=GEOAPIFY_API_KEY=<votre_clé>.',
      );
    }
    return key.trim();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      return await _throttle(() => _loadJson(uri));
    } on TimeoutException {
      throw const GeocodingException(
        'La recherche a pris trop de temps. Vérifiez la connexion puis réessayez.',
      );
    } on GeocodingException {
      rethrow;
    } on SocketException {
      throw const GeocodingException(
        'Connexion au service de recherche impossible. Vérifiez Internet puis réessayez.',
      );
    } on HttpException {
      throw const GeocodingException(
        'Le service de recherche est momentanément indisponible.',
      );
    } on FormatException {
      throw const GeocodingException(
        'Le service de recherche a renvoyé une réponse illisible.',
      );
    }
  }

  static Future<Map<String, dynamic>> _httpGetJson(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      return await _readJsonResponse(
        client,
        uri,
      ).timeout(_defaultRequestTimeout);
    } finally {
      client.close(force: true);
    }
  }

  static Future<Map<String, dynamic>> _readJsonResponse(
    HttpClient client,
    Uri uri,
  ) async {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 8));
    request.headers.set(HttpHeaders.userAgentHeader, 'CovoitCampus/1.0');
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode != HttpStatus.ok) {
      throw const GeocodingException(
        'Le service de recherche est momentanément indisponible.',
      );
    }
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 8));
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<T> _throttle<T>(Future<T> Function() request) async {
    final previous = _requestQueue;
    final release = Completer<void>();
    _requestQueue = release.future;
    try {
      await previous.timeout(requestTimeout);
      final last = _lastRequestAt;
      if (last != null) {
        final elapsed = DateTime.now().difference(last);
        if (elapsed < minimumRequestGap) {
          await Future<void>.delayed(minimumRequestGap - elapsed);
        }
      }
      return await request().timeout(requestTimeout);
    } on TimeoutException {
      throw TimeoutException('Place geocoding request timed out');
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
