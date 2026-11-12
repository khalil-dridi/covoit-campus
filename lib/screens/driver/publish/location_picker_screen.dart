import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/location_service.dart';
import '../../../services/place_geocoding_service.dart';

const covoitCampusTileUserAgent =
    'CovoitCampus/1.0.0 (com.khalildridi.covoitcampus)';

TileLayer buildCovoitCampusTileLayer() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.khalildridi.covoitcampus',
  tileProvider: NetworkTileProvider(
    headers: {'User-Agent': covoitCampusTileUserAgent},
  ),
);

class LocationSelection {
  final LatLng point;
  final String label;
  const LocationSelection({required this.point, required this.label});
}

class LocationPickerScreen extends StatefulWidget {
  final String title;
  final LatLng? initialPoint;
  final LocationService? locationService;
  final PlaceGeocodingService? geocodingService;
  final bool showMapTiles;
  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initialPoint,
    this.locationService,
    this.geocodingService,
    this.showMapTiles = true,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const Color navy = Color(0xFF123D68);
  static const Color blue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const double _minimumZoom = 4;
  static const double _maximumZoom = 19;

  late final _locationService = widget.locationService ?? LocationService();
  late final _geocodingService =
      widget.geocodingService ?? PlaceGeocodingService();
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late LatLng _point;
  LatLng? _currentLocation;
  LatLng? _labelPoint;
  Timer? _searchDebounce;
  Timer? _reverseDebounce;
  Timer? _hintTimer;
  List<PlaceSearchResult> _suggestions = const [];
  String _selectedLabel = 'Emplacement sélectionné';
  String? _selectedSubtitle;
  String? _message;
  bool _locating = false;
  bool _searching = false;
  bool _reverseGeocoding = false;
  bool _showSuggestions = false;
  bool _showHint = true;
  bool _confirming = false;
  bool _skipNextReverseLookup = false;
  bool _isApplyingSearchSelection = false;
  int _searchRequestId = 0;
  int _reverseRequestId = 0;
  LatLng? _lastReversePoint;

  @override
  void initState() {
    super.initState();
    _point = widget.initialPoint ?? LocationService.defaultLocation;
    _selectedLabel = widget.initialPoint == null
        ? 'Tunis, Tunisie'
        : 'Emplacement sélectionné';
    _searchController.addListener(_onSearchChanged);
    _hintTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showHint = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialPoint == null) _locate(recenter: true);
      _scheduleReverseLookup(delay: const Duration(milliseconds: 250));
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _reverseDebounce?.cancel();
    _hintTimer?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_isApplyingSearchSelection) return;
    _searchDebounce?.cancel();
    final requestId = ++_searchRequestId;
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = const [];
        _searching = false;
        _showSuggestions = false;
        _message = null;
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
      _suggestions = const [];
      _searching = false;
      _message = null;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query, requestId);
    });
  }

  Future<void> _searchPlaces(String query, int requestId) async {
    if (!mounted || query.trim().length < 2) return;
    setState(() {
      _searching = true;
      _message = null;
      _suggestions = const [];
      _showSuggestions = true;
    });
    try {
      final results = await _geocodingService.search(query, near: _point);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _suggestions = results;
        _searching = false;
        _message = results.isEmpty
            ? 'Aucun lieu trouvé. Essayez un nom ou une adresse plus précise.'
            : null;
      });
    } on GeocodingException catch (error) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _suggestions = const [];
        _searching = false;
        _message = error.message;
      });
    } on Object {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _suggestions = const [];
        _searching = false;
        _message = 'La recherche a échoué. Réessayez dans un instant.';
      });
    }
  }

  void _retrySearch() {
    final query = _searchController.text.trim();
    if (query.length < 2 || _searching) return;
    _searchDebounce?.cancel();
    _searchPlaces(query, ++_searchRequestId);
  }

  void _selectSuggestion(PlaceSearchResult result) {
    FocusScope.of(context).unfocus();
    _searchDebounce?.cancel();
    _reverseDebounce?.cancel();
    _skipNextReverseLookup = true;
    _lastReversePoint = result.point;
    _labelPoint = result.point;
    _isApplyingSearchSelection = true;
    _searchController.text = result.name;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    _isApplyingSearchSelection = false;
    setState(() {
      _point = result.point;
      _selectedLabel = result.label;
      _selectedSubtitle = result.subtitle.isEmpty ? null : result.subtitle;
      _suggestions = const [];
      _showSuggestions = false;
      _searching = false;
      _reverseGeocoding = false;
    });
    if (!_mapController.move(result.point, 16)) {
      _skipNextReverseLookup = false;
    }
    _hideHint();
  }

  Future<void> _locate({bool recenter = true}) async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _message = null;
    });
    try {
      final point = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = point;
        if (recenter) {
          _point = point;
          _selectedLabel = 'Ma position';
          _selectedSubtitle = null;
          _labelPoint = null;
        }
      });
      if (recenter) {
        _mapController.move(point, 16);
        _scheduleReverseLookup(delay: const Duration(milliseconds: 450));
      }
      _hideHint();
    } on LocationException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _message = 'Position indisponible. Vous pouvez choisir un point sur la carte.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart) {
      ++_reverseRequestId;
      _reverseDebounce?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hideHint();
      });
    }
    if (event is! MapEventMoveEnd) return;
    final center = event.camera.center;
    ++_reverseRequestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _point = center);
      _hideHint();
      if (_skipNextReverseLookup) {
        _skipNextReverseLookup = false;
        return;
      }
      final previous = _lastReversePoint;
      if (previous != null &&
          (previous.latitude - center.latitude).abs() < 0.0001 &&
          (previous.longitude - center.longitude).abs() < 0.0001) {
        return;
      }
      _scheduleReverseLookup();
    });
  }

  void _scheduleReverseLookup({
    Duration delay = const Duration(milliseconds: 700),
  }) {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(delay, _lookupSelectedPlace);
  }

  Future<void> _lookupSelectedPlace() async {
    final requestId = ++_reverseRequestId;
    final point = _point;
    _lastReversePoint = point;
    if (mounted) setState(() => _reverseGeocoding = true);
    try {
      final result = await _geocodingService.reverse(point);
      if (!mounted || requestId != _reverseRequestId) return;
      setState(() {
        _selectedLabel = result?.label ?? 'Emplacement sélectionné';
        _selectedSubtitle = result?.subtitle.isNotEmpty == true
            ? result!.subtitle
            : null;
        _labelPoint = point;
        _reverseGeocoding = false;
      });
    } on Object {
      if (!mounted || requestId != _reverseRequestId) return;
      setState(() {
        _selectedLabel = 'Emplacement sélectionné';
        _selectedSubtitle = null;
        _labelPoint = point;
        _reverseGeocoding = false;
      });
    }
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final zoom = (camera.zoom + delta)
        .clamp(_minimumZoom, _maximumZoom)
        .toDouble();
    if (zoom == camera.zoom) return;
    _mapController.move(camera.center, zoom);
    _hideHint();
  }

  void _hideHint() {
    if (!_showHint) return;
    _hintTimer?.cancel();
    setState(() => _showHint = false);
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    FocusScope.of(context).unfocus();
    final point = _mapController.camera.center;
    ++_reverseRequestId;
    setState(() {
      _point = point;
      _confirming = true;
    });
    _reverseDebounce?.cancel();
    final previousLabelPoint = _labelPoint;
    final labelIsStale =
        previousLabelPoint == null ||
        (previousLabelPoint.latitude - point.latitude).abs() >= 0.0001 ||
        (previousLabelPoint.longitude - point.longitude).abs() >= 0.0001;
    String label = labelIsStale ? 'Emplacement sélectionné' : _selectedLabel;
    if (_reverseGeocoding || labelIsStale) {
      try {
        final result = await _geocodingService.reverse(point);
        if (result != null) label = result.label;
      } on Object {
        // Coordinates remain valid when the geocoder is offline.
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(LocationSelection(point: point, label: label));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _point,
              initialZoom: widget.initialPoint == null ? 7 : 14,
              minZoom: _minimumZoom,
              maxZoom: _maximumZoom,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.doubleTapDragZoom,
              ),
              onPositionChanged: (camera, _) {
                _point = camera.center;
              },
              onMapEvent: _onMapEvent,
            ),
            children: [
              if (widget.showMapTiles) buildCovoitCampusTileLayer(),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 5),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors'),
                backgroundColor: Colors.white,
              ),
            ],
          ),
          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -23),
                child: Icon(
                  Icons.location_pin,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _searchBar(),
                if (_showSuggestions) _suggestionPanel(),
                if (_message != null && !_showSuggestions) _errorPanel(),
              ],
            ),
          ),
          if (_showHint)
            Positioned(
              top: 78,
              left: 0,
              right: 0,
              child: Center(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: navy.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      child: Text(
                        'Déplacez la carte pour choisir votre emplacement',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 14,
            bottom: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapControl(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom avant',
                  onPressed: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                _mapControl(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom arrière',
                  onPressed: () => _zoomBy(-1),
                ),
                const SizedBox(height: 8),
                _mapControl(
                  icon: _locating
                      ? Icons.more_horiz_rounded
                      : Icons.my_location_rounded,
                  tooltip: 'Ma position',
                  onPressed: _locating ? null : () => _locate(),
                  child: _locating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _selectedPlaceCard(),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirming ? null : _confirm,
                icon: _confirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Confirmer cet emplacement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() => Material(
    elevation: 5,
    shadowColor: navy.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(16),
    child: TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onTap: _hideHint,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) {
        if (_searchDebounce?.isActive == true || _searching) return;
        _searchPlaces(_searchController.text.trim(), ++_searchRequestId);
      },
      decoration: InputDecoration(
        hintText: 'Rechercher une ville, une adresse…',
        hintStyle: const TextStyle(color: Color(0xFF7D909B), fontSize: 13),
        prefixIcon: _searching
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: green,
                  ),
                ),
              )
            : const Icon(Icons.search_rounded, color: blue),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer la recherche',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _message = null;
                    _showSuggestions = false;
                  });
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _suggestionPanel() => Container(
    margin: const EdgeInsets.only(top: 7),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.42,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: navy.withValues(alpha: 0.16),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: _searching && _suggestions.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator(color: green)),
          )
        : _suggestions.isEmpty
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _message ??
                        'Aucun lieu trouvé. Essayez une autre recherche.',
                    style: const TextStyle(
                      color: Color(0xFF547080),
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _retrySearch,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          )
        : ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _suggestions.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 54),
            itemBuilder: (context, index) {
              final result = _suggestions[index];
              return Material(
                color: Colors.white,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, color: blue),
                  title: Text(
                    result.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: result.subtitle.isEmpty
                      ? null
                      : Text(
                          result.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                  onTap: () => _selectSuggestion(result),
                ),
              );
            },
          ),
  );

  Widget _errorPanel() => Container(
    margin: const EdgeInsets.only(top: 7),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.wifi_off_rounded, color: Color(0xFFB93E36), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _message!,
                style: const TextStyle(color: Color(0xFF8F302B), fontSize: 12),
              ),
              if (_message!.contains('définitivement'))
                TextButton(
                  onPressed: Geolocator.openAppSettings,
                  child: const Text('Ouvrir les réglages'),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _selectedPlaceCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE1ECE8)),
      boxShadow: [
        BoxShadow(
          color: navy.withValues(alpha: 0.07),
          blurRadius: 14,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.location_on_rounded, color: green, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _selectedSubtitle ??
                    '${_point.latitude.toStringAsFixed(5)}, ${_point.longitude.toStringAsFixed(5)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6F838D),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        if (_reverseGeocoding)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2, color: green),
            ),
          ),
      ],
    ),
  );

  Widget _mapControl({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Widget? child,
  }) => Material(
    color: Colors.white,
    elevation: 4,
    shape: const CircleBorder(),
    child: SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: child ?? Icon(icon, color: navy, size: 22),
      ),
    ),
  );
}
