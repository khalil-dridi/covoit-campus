import 'package:flutter/material.dart';

import '../../../models/trip.dart';
import '../../../models/user.dart';
import '../../../repositories/trip_repository.dart';
import '../trips/trip_details_screen.dart';
import '../../../widgets/passenger/passenger_header.dart';

class PassengerSearchScreen extends StatefulWidget {
  final User user;

  const PassengerSearchScreen({
    super.key,
    required this.user,
  });

  @override
  State<PassengerSearchScreen> createState() => _PassengerSearchScreenState();
}

class _PassengerSearchScreenState extends State<PassengerSearchScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightGreen = Color(0xFFE8F8F1);

  static const List<String> _cities = [
    'Tunis',
    'Ariana',
    'Manouba',
    'Ben Arous',
    'La Marsa',
    'Nabeul',
    'Sousse',
    'Monastir',
    'Bizerte',
    'Béja',
    'Medjez El Bab',
  ];

  final TripRepository _tripRepository = TripRepository();
  final GlobalKey _criteriaKey = GlobalKey();

  String? _departure;
  String? _destination;
  DateTime? _date;
  TimeOfDay? _time;
  int _seats = 1;
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _verifiedDriversOnly = false;
  bool _flexibleTime = false;
  double? _maxPrice;
  TripSort _sort = TripSort.earliest;
  List<Trip> _results = const [];
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PassengerHeader(
                user: widget.user,
                onNotificationTap: () => _showInfoDialog(
                  context,
                  title: 'Notifications',
                  message: 'Vos notifications seront disponibles ici.',
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Rechercher un trajet',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Trouvez facilement un trajet adapté à vos besoins.',
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.82),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 17),
              Container(
                key: _criteriaKey,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2EBE7)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.055),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCityField(
                      label: 'Ville de départ',
                      value: _departure,
                      icon: Icons.trip_origin_rounded,
                      iconColor: green,
                      onTap: () => _selectCity(isDeparture: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Row(
                        children: [
                          Container(
                            width: 1,
                            height: 14,
                            color: const Color(0xFFDCE7E3),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Inverser départ et destination',
                            onPressed: _swapLocations,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.swap_vert_rounded,
                              color: secondaryBlue,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCityField(
                      label: 'Ville d’arrivée',
                      value: _destination,
                      icon: Icons.location_on_rounded,
                      iconColor: secondaryBlue,
                      onTap: () => _selectCity(isDeparture: false),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeField(
                            label: 'Date du trajet',
                            value: _date == null ? 'Choisir une date' : _formatDate(_date!),
                            icon: Icons.calendar_today_rounded,
                            onTap: _selectDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDateTimeField(
                            label: 'Heure',
                            value: _time == null ? 'Choisir une heure' : _formatTime(_time!),
                            icon: Icons.access_time_rounded,
                            onTap: _selectTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildSeatSelector(),
                    const SizedBox(height: 13),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _showFilters,
                        icon: const Icon(Icons.tune_rounded, size: 17),
                        label: Text(_activeFilterCount == 0
                            ? 'Filtres'
                            : 'Filtres ($_activeFilterCount)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: secondaryBlue,
                          side: const BorderSide(color: Color(0xFFDCE7E3)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      _buildInlineError(_errorMessage!),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSearching ? null : _searchTrips,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 20),
                        label: Text(
                          _isSearching
                              ? 'Recherche…'
                              : 'Rechercher des trajets',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: green.withValues(alpha: 0.7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 23),
              _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityField({
    required String label,
    required String? value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return _TappableField(
      onTap: onTap,
      leading: Icon(icon, color: iconColor, size: 20),
      label: label,
      value: value ?? 'Choisir une ville',
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _TappableField(
      onTap: onTap,
      compact: true,
      leading: Icon(icon, color: secondaryBlue, size: 17),
      label: label,
      value: value,
    );
  }

  Widget _buildSeatSelector() {
    return Row(
      children: [
        const Icon(Icons.event_seat_outlined, color: secondaryBlue, size: 20),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Nombre de places',
            style: TextStyle(
              color: textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _SeatButton(
          icon: Icons.remove_rounded,
          label: 'Retirer une place',
          onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$_seats ${_seats == 1 ? 'place' : 'places'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _SeatButton(
          icon: Icons.add_rounded,
          label: 'Ajouter une place',
          onPressed: _seats < 4 ? () => setState(() => _seats++) : null,
        ),
      ],
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3D0CD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB93E36), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9F352F),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (!_hasSearched) {
      return const _SearchEmptyState(
        icon: Icons.route_outlined,
        title: 'Recherchez votre prochain trajet',
        message: 'Choisissez votre départ, votre destination et votre date.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Trajets disponibles',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${_results.length} ${_results.length == 1 ? 'trajet trouvé' : 'trajets trouvés'}',
              style: TextStyle(
                color: textGrey.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_results.isEmpty)
          _SearchEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Aucun trajet trouvé',
            message:
                'Nous n’avons trouvé aucun trajet correspondant à vos critères.',
            actionLabel: 'Modifier ma recherche',
            onAction: _focusCriteria,
          )
        else ...[
          _buildResultControls(),
          const SizedBox(height: 10),
          ..._results.map((trip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TripResultCard(
                  trip: trip,
                  onDetails: () => _openTripDetails(trip),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildResultControls() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _showFilters,
          icon: const Icon(Icons.tune_rounded, size: 15),
          label: const Text('Filtres'),
          style: _smallControlStyle(),
        ),
        const SizedBox(width: 8),
        const Text(
          'Tri',
          style: TextStyle(color: textGrey, fontSize: 11),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: DropdownButtonFormField<TripSort>(
            initialValue: _sort,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDCE7E3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDCE7E3)),
              ),
            ),
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            items: const [
              DropdownMenuItem(value: TripSort.earliest, child: Text('Plus tôt')),
              DropdownMenuItem(value: TripSort.cheapest, child: Text('Moins cher')),
              DropdownMenuItem(value: TripSort.bestRated, child: Text('Mieux noté')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _sort = value);
              _searchTrips();
            },
          ),
        ),
      ],
    );
  }

  ButtonStyle _smallControlStyle() => OutlinedButton.styleFrom(
        foregroundColor: secondaryBlue,
        side: const BorderSide(color: Color(0xFFDCE7E3)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      );

  Future<void> _selectCity({required bool isDeparture}) async {
    final current = isDeparture ? _departure : _destination;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _CityPickerSheet(
        cities: _cities,
        selectedCity: current,
        title: isDeparture ? 'Ville de départ' : 'Ville d’arrivée',
      ),
    );

    if (!mounted || selected == null) return;
    if ((isDeparture && selected == _destination) ||
        (!isDeparture && selected == _departure)) {
      setState(() {
        _errorMessage =
            'Les villes de départ et d’arrivée doivent être différentes.';
      });
      return;
    }

    setState(() {
      if (isDeparture) {
        _departure = selected;
      } else {
        _destination = selected;
      }
      _errorMessage = null;
    });
  }

  void _swapLocations() {
    setState(() {
      final previousDeparture = _departure;
      _departure = _destination;
      _destination = previousDeparture;
      _errorMessage = null;
    });
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date != null && !_date!.isBefore(today) ? _date! : today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: green,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
        ),
        child: child!,
      ),
    );

    if (!mounted || picked == null) return;
    setState(() {
      _date = picked;
      _errorMessage = null;
    });
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: green,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
        ),
        child: child!,
      ),
    );

    if (!mounted || picked == null) return;
    setState(() {
      _time = picked;
      _errorMessage = null;
    });
  }

  Future<void> _showFilters() async {
    final selection = await showModalBottomSheet<_FilterSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        initialMaxPrice: _maxPrice,
        initialVerifiedOnly: _verifiedDriversOnly,
        initialFlexibleTime: _flexibleTime,
      ),
    );

    if (!mounted || selection == null) return;
    setState(() {
      _maxPrice = selection.maxPrice;
      _verifiedDriversOnly = selection.verifiedOnly;
      _flexibleTime = selection.flexibleTime;
    });
    if (_hasSearched) _searchTrips();
  }

  Future<void> _searchTrips() async {
    if (_departure == null) {
      setState(() => _errorMessage = 'Veuillez choisir une ville de départ.');
      return;
    }
    if (_destination == null) {
      setState(() => _errorMessage = 'Veuillez choisir une ville d’arrivée.');
      return;
    }
    if (_departure == _destination) {
      setState(() => _errorMessage =
          'Les villes de départ et d’arrivée doivent être différentes.');
      return;
    }
    if (_date == null) {
      setState(() => _errorMessage = 'Veuillez choisir une date de trajet.');
      return;
    }
    if (_time == null) {
      setState(() => _errorMessage = 'Veuillez choisir une heure de départ.');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final trips = await _tripRepository.searchAvailableTrips(
        passengerId: widget.user.id ?? -1,
        departure: _departure!,
        destination: _destination!,
        departureDate: _formatIsoDate(_date!),
        departureTime: _formatTime(_time!),
        seats: _seats,
        flexibleTime: _flexibleTime,
        verifiedDriversOnly: _verifiedDriversOnly,
        maxPrice: _maxPrice,
        sort: _sort,
      );
      if (!mounted) return;
      setState(() {
        _results = trips;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _hasSearched = true;
        _results = const [];
        _errorMessage = 'La recherche a échoué. Veuillez réessayer.';
      });
    }
  }

  int get _activeFilterCount =>
      (_verifiedDriversOnly ? 1 : 0) +
      (_flexibleTime ? 1 : 0) +
      (_maxPrice != null ? 1 : 0);

  void _focusCriteria() {
    final targetContext = _criteriaKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openTripDetails(Trip trip) async {
    final tripId = trip.id;
    if (tripId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailsScreen(
          tripId: tripId,
          user: widget.user,
        ),
      ),
    );
    if (!mounted) return;
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: green, size: 28),
              ),
              const SizedBox(height: 17),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.84),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 21),
              SizedBox(
                width: double.infinity,
                height: 47,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Compris',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _TappableField extends StatelessWidget {
  final Widget leading;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool compact;

  const _TappableField({
    required this.leading,
    required this.label,
    required this.value,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCFDFC),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 57 : 64),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 13,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFDCE7E3)),
          ),
          child: Row(
            children: [
              leading,
              SizedBox(width: compact ? 7 : 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PassengerSearchScreenStateColors.textGrey,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PassengerSearchScreenStateColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: PassengerSearchScreenStateColors.textGrey,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SeatButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: PassengerSearchScreenStateColors.secondaryBlue,
          backgroundColor: const Color(0xFFEAF3FC),
          disabledForegroundColor: const Color(0xFF9EADB5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

class _CityPickerSheet extends StatelessWidget {
  final List<String> cities;
  final String? selectedCity;
  final String title;

  const _CityPickerSheet({
    required this.cities,
    required this.selectedCity,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.72),
        padding: const EdgeInsets.fromLTRB(20, 13, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E4DF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 17),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: PassengerSearchScreenStateColors.primaryBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cities.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final selected = city == selectedCity;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: selected
                          ? PassengerSearchScreenStateColors.green
                          : PassengerSearchScreenStateColors.secondaryBlue,
                    ),
                    title: Text(
                      city,
                      style: const TextStyle(
                        color: PassengerSearchScreenStateColors.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded,
                            color: PassengerSearchScreenStateColors.green)
                        : null,
                    onTap: () => Navigator.of(context).pop(city),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSelection {
  final double? maxPrice;
  final bool verifiedOnly;
  final bool flexibleTime;

  const _FilterSelection({
    required this.maxPrice,
    required this.verifiedOnly,
    required this.flexibleTime,
  });
}

class _FilterSheet extends StatefulWidget {
  final double? initialMaxPrice;
  final bool initialVerifiedOnly;
  final bool initialFlexibleTime;

  const _FilterSheet({
    required this.initialMaxPrice,
    required this.initialVerifiedOnly,
    required this.initialFlexibleTime,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _limitPrice;
  late double _maxPrice;
  late bool _verifiedOnly;
  late bool _flexibleTime;

  @override
  void initState() {
    super.initState();
    _limitPrice = widget.initialMaxPrice != null;
    _maxPrice = widget.initialMaxPrice ?? 30;
    _verifiedOnly = widget.initialVerifiedOnly;
    _flexibleTime = widget.initialFlexibleTime;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 13, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E4DF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filtres',
                style: TextStyle(
                  color: PassengerSearchScreenStateColors.primaryBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: PassengerSearchScreenStateColors.green,
              title: const Text('Prix maximum'),
              subtitle: Text(_limitPrice ? '${_maxPrice.round()} DT maximum' : 'Aucune limite'),
              value: _limitPrice,
              onChanged: (value) => setState(() => _limitPrice = value),
            ),
            if (_limitPrice)
              Slider(
                value: _maxPrice,
                min: 1,
                max: 100,
                divisions: 99,
                activeColor: PassengerSearchScreenStateColors.green,
                onChanged: (value) => setState(() => _maxPrice = value),
              ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: PassengerSearchScreenStateColors.green,
              title: const Text('Conducteur vérifié'),
              value: _verifiedOnly,
              onChanged: (value) => setState(() => _verifiedOnly = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Départ proche'),
              subtitle: const Text('Indisponible : aucune donnée de distance'),
              value: false,
              onChanged: null,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: PassengerSearchScreenStateColors.green,
              title: const Text('Heure flexible'),
              subtitle: const Text('Dans une fenêtre d’une heure'),
              value: _flexibleTime,
              onChanged: (value) => setState(() => _flexibleTime = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(
                  _FilterSelection(
                    maxPrice: _limitPrice ? _maxPrice : null,
                    verifiedOnly: _verifiedOnly,
                    flexibleTime: _flexibleTime,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PassengerSearchScreenStateColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Appliquer les filtres'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripResultCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onDetails;

  const _TripResultCard({required this.trip, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(trip.departureDate);
    final month = date == null ? '' : _frenchMonth(date.month);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE2EBE7)),
        boxShadow: [
          BoxShadow(
            color: PassengerSearchScreenStateColors.primaryBlue.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: PassengerSearchScreenStateColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  date == null ? '--' : '${date.day}',
                  style: const TextStyle(
                    color: PassengerSearchScreenStateColors.primaryBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  month,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PassengerSearchScreenStateColors.secondaryBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.departure,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PassengerSearchScreenStateColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(width: 1, height: 12, color: PassengerSearchScreenStateColors.green),
                    const SizedBox(width: 5),
                    Text(
                      trip.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PassengerSearchScreenStateColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _DriverAvatar(image: trip.driverProfileImage),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        trip.driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PassengerSearchScreenStateColors.textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trip.driverIsVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          color: PassengerSearchScreenStateColors.green, size: 14),
                    ],
                    if (trip.driverRating != null) ...[
                      const SizedBox(width: 7),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFE7AD34), size: 14),
                      Text(
                        trip.driverRating!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: PassengerSearchScreenStateColors.textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip.departureTime,
                style: const TextStyle(
                  color: PassengerSearchScreenStateColors.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${trip.price.toStringAsFixed(2)} DT',
                style: const TextStyle(
                  color: PassengerSearchScreenStateColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${trip.availableSeats} places',
                style: const TextStyle(
                  color: PassengerSearchScreenStateColors.textGrey,
                  fontSize: 9,
                ),
              ),
              TextButton.icon(
                onPressed: onDetails,
                style: TextButton.styleFrom(
                  foregroundColor: PassengerSearchScreenStateColors.secondaryBlue,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                label: const Text('Voir détails'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _frenchMonth(int month) => const [
        'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
        'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
      ][month - 1];
}

class _DriverAvatar extends StatelessWidget {
  final String? image;

  const _DriverAvatar({this.image});

  @override
  Widget build(BuildContext context) {
    final path = image?.trim();
    final uri = path == null ? null : Uri.tryParse(path);
    final isNetwork = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final isAsset = path?.startsWith('assets/') == true;
    Widget content;
    if (path == null || path.isEmpty) {
      content = _fallback();
    } else if (isNetwork) {
      content = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else if (isAsset) {
      content = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else {
      content = _fallback();
    }

    return ClipOval(
      child: SizedBox(width: 23, height: 23, child: content),
    );
  }

  Widget _fallback() => Container(
        color: PassengerSearchScreenStateColors.lightBlue,
        alignment: Alignment.center,
        child: const Icon(
          Icons.person_rounded,
          color: PassengerSearchScreenStateColors.secondaryBlue,
          size: 15,
        ),
      );
}

class _SearchEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SearchEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE7)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: PassengerSearchScreenStateColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: PassengerSearchScreenStateColors.green,
              size: 26,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PassengerSearchScreenStateColors.primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PassengerSearchScreenStateColors.textGrey,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 13),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: PassengerSearchScreenStateColors.secondaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

abstract final class PassengerSearchScreenStateColors {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);
  static const Color lightGreen = Color(0xFFE8F8F1);
}

String _formatDate(DateTime date) {
  const months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _formatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
