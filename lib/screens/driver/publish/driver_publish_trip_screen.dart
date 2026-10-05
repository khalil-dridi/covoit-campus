import 'package:flutter/material.dart';

import '../../../models/trip.dart';
import '../../../models/user.dart';
import '../../../models/vehicle.dart';
import '../../../repositories/trip_repository.dart';
import '../../../repositories/vehicle_repository.dart';
import '../../../widgets/driver/driver_header.dart';

class DriverPublishTripScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onTripPublished;
  final VoidCallback? onViewTripsTap;
  final VoidCallback? onAddVehicleTap;

  const DriverPublishTripScreen({
    super.key,
    required this.user,
    this.onTripPublished,
    this.onViewTripsTap,
    this.onAddVehicleTap,
  });

  @override
  State<DriverPublishTripScreen> createState() =>
      _DriverPublishTripScreenState();
}

class _DriverPublishTripScreenState extends State<DriverPublishTripScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);
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

  final _descriptionController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _tripRepository = TripRepository();
  final _vehicleRepository = VehicleRepository();

  List<Vehicle> _vehicles = const [];
  Vehicle? _selectedVehicle;
  String? _departure;
  String? _destination;
  DateTime? _date;
  TimeOfDay? _time;
  int _availableSeats = 1;
  bool _automaticBooking = false;
  bool _allowLuggage = true;
  bool _music = true;
  bool _smoking = false;
  bool _isLoadingVehicles = true;
  bool _isPublishing = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _meetingPointController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final userId = widget.user.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingVehicles = false);
      return;
    }

    try {
      final vehicles = await _vehicleRepository.getVehiclesForUser(userId);
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        if (_selectedVehicle == null && vehicles.isNotEmpty) {
          _selectedVehicle = vehicles.first;
        }
        _isLoadingVehicles = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingVehicles = false);
      _showMessage('Impossible de charger vos véhicules.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(19, 12, 19, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DriverHeader(
                  user: widget.user,
                  onNotificationTap: () => _showInfoDialog(
                    title: 'Notifications',
                    message: 'Vos notifications seront disponibles ici.',
                    icon: Icons.notifications_none_rounded,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Publier un trajet',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Proposez vos places à d’autres étudiants.',
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                _buildRouteSection(),
                const SizedBox(height: 14),
                _buildDateTimeSection(),
                const SizedBox(height: 14),
                _buildSeatsAndPriceSection(),
                const SizedBox(height: 14),
                _buildMeetingSection(),
                const SizedBox(height: 14),
                _buildVehicleSection(),
                const SizedBox(height: 14),
                _buildOptionsSection(),
                const SizedBox(height: 14),
                _buildSummarySection(),
                if (_formError != null) ...[
                  const SizedBox(height: 12),
                  _errorPanel(_formError!),
                ],
                const SizedBox(height: 16),
                _publishButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSection() => _sectionCard(
        title: 'Trajet',
        icon: Icons.route_rounded,
        child: Column(
          children: [
            _cityField(
              label: 'Ville de départ',
              value: _departure,
              icon: Icons.trip_origin_rounded,
              iconColor: green,
              onTap: () => _selectCity(isDeparture: true),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 23),
              child: Row(
                children: [
                  Container(height: 13, width: 1, color: const Color(0xFFDCE7E3)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Inverser les villes',
                    onPressed: _swapCities,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.swap_vert_rounded, color: secondaryBlue),
                  ),
                ],
              ),
            ),
            _cityField(
              label: 'Ville d’arrivée',
              value: _destination,
              icon: Icons.location_on_rounded,
              iconColor: secondaryBlue,
              onTap: () => _selectCity(isDeparture: false),
            ),
          ],
        ),
      );

  Widget _buildDateTimeSection() => _sectionCard(
        title: 'Date et heure',
        icon: Icons.calendar_month_rounded,
        child: Row(
          children: [
            Expanded(
              child: _selectionField(
                label: 'Date du trajet',
                value: _date == null ? 'Choisir une date' : _formatDate(_date!),
                icon: Icons.calendar_today_rounded,
                onTap: _selectDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _selectionField(
                label: 'Heure de départ',
                value: _time == null ? 'Choisir une heure' : _formatTime(_time!),
                icon: Icons.access_time_rounded,
                onTap: _selectTime,
              ),
            ),
          ],
        ),
      );

  Widget _buildSeatsAndPriceSection() => _sectionCard(
        title: 'Places et prix',
        icon: Icons.event_seat_outlined,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nombre de places disponibles',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _stepButton(
                  icon: Icons.remove_rounded,
                  label: 'Retirer une place',
                  onPressed: _availableSeats > 1
                      ? () => setState(() => _availableSeats--)
                      : null,
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '$_availableSeats',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _stepButton(
                  icon: Icons.add_rounded,
                  label: 'Ajouter une place',
                  onPressed: _availableSeats < _seatLimit
                      ? () => setState(() => _availableSeats++)
                      : null,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Maximum : $_seatLimit place${_seatLimit == 1 ? '' : 's'} selon le véhicule',
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Prix par passager',
                icon: Icons.payments_outlined,
                suffix: 'DT',
              ),
              validator: (value) {
                final price = double.tryParse((value ?? '').replaceAll(',', '.'));
                if (price == null || price < 0) {
                  return 'Veuillez indiquer un prix valide.';
                }
                return null;
              },
            ),
          ],
        ),
      );

  int get _seatLimit {
    final capacity = _selectedVehicle?.seats ?? 7;
    return capacity.clamp(1, 7);
  }

  Widget _buildMeetingSection() => _sectionCard(
        title: 'Rendez-vous',
        icon: Icons.place_outlined,
        child: Column(
          children: [
            TextFormField(
              controller: _meetingPointController,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Point de rendez-vous',
                icon: Icons.location_on_outlined,
                hint: 'Ex. Entrée principale du campus',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Veuillez indiquer le point de rendez-vous.'
                  : null,
            ),
            const SizedBox(height: 11),
            TextFormField(
              controller: _descriptionController,
              maxLength: 240,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                label: 'Informations supplémentaires (optionnel)',
                icon: Icons.notes_rounded,
                hint: 'Précisions pour vos passagers…',
              ),
            ),
          ],
        ),
      );

  Widget _buildVehicleSection() => _sectionCard(
        title: 'Véhicule',
        icon: Icons.directions_car_rounded,
        child: _isLoadingVehicles
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator(color: green)),
              )
            : _vehicles.isEmpty
                ? _vehicleEmptyState()
                : Column(
                    children: [
                      for (final vehicle in _vehicles)
                        _vehicleOption(vehicle),
                    ],
                  ),
      );

  Widget _vehicleEmptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.directions_car_outlined, color: secondaryBlue, size: 28),
            const SizedBox(height: 8),
            const Text(
              'Aucun véhicule configuré',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ajoutez d’abord un véhicule depuis votre profil.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey, fontSize: 11),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: widget.onAddVehicleTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter un véhicule'),
              style: OutlinedButton.styleFrom(
                foregroundColor: secondaryBlue,
                side: const BorderSide(color: Color(0xFFC9DBE9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _vehicleOption(Vehicle vehicle) {
    final selected = _selectedVehicle?.id == vehicle.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? lightGreen : const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => setState(() {
            _selectedVehicle = vehicle;
            _availableSeats = _availableSeats.clamp(1, _seatLimit);
          }),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? green.withValues(alpha: 0.65) : const Color(0xFFDCE7E3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: secondaryBlue,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.brand} ${vehicle.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${vehicle.seats} places',
                        style: const TextStyle(color: textGrey, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? green : textGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsSection() => _sectionCard(
        title: 'Options du trajet',
        icon: Icons.tune_rounded,
        child: Column(
          children: [
            _optionSwitch(
              icon: Icons.bolt_rounded,
              label: 'Réservation automatique',
              value: _automaticBooking,
              onChanged: (value) => setState(() => _automaticBooking = value),
            ),
            const Divider(height: 1, indent: 48),
            _optionSwitch(
              icon: Icons.luggage_outlined,
              label: 'Autoriser les bagages',
              value: _allowLuggage,
              onChanged: (value) => setState(() => _allowLuggage = value),
            ),
            const Divider(height: 1, indent: 48),
            _optionSwitch(
              icon: Icons.music_note_rounded,
              label: 'Musique',
              value: _music,
              onChanged: (value) => setState(() => _music = value),
            ),
            const Divider(height: 1, indent: 48),
            _optionSwitch(
              icon: Icons.smoking_rooms_outlined,
              label: 'Fumeur accepté',
              value: _smoking,
              onChanged: (value) => setState(() => _smoking = value),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 13),
              child: Text(
                'Ces options sont temporaires et ne sont pas enregistrées.',
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _optionSwitch({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: secondaryBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              activeTrackColor: green,
              onChanged: onChanged,
            ),
          ],
        ),
      );

  Widget _buildSummarySection() => _sectionCard(
        title: 'Résumé du trajet',
        icon: Icons.fact_check_outlined,
        child: Column(
          children: [
            _summaryRow('Départ', _departure ?? '—'),
            _summaryRow('Destination', _destination ?? '—'),
            _summaryRow('Date', _date == null ? '—' : _formatDate(_date!)),
            _summaryRow('Heure', _time == null ? '—' : _formatTime(_time!)),
            _summaryRow('Places', '$_availableSeats'),
            _summaryRow('Prix', _priceController.text.trim().isEmpty
                ? '—'
                : '${_priceController.text.trim()} DT'),
            _summaryRow(
              'Véhicule',
              _selectedVehicle == null
                  ? '—'
                  : '${_selectedVehicle!.brand} ${_selectedVehicle!.model}',
            ),
            _summaryRow(
              'Rendez-vous',
              _meetingPointController.text.trim().isEmpty
                  ? '—'
                  : _meetingPointController.text.trim(),
              isLast: true,
            ),
          ],
        ),
      );

  Widget _summaryRow(String label, String value, {bool isLast = false}) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) const Divider(height: 1, indent: 16),
        ],
      );

  Widget _publishButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isPublishing || _isLoadingVehicles || _vehicles.isEmpty
              ? null
              : _validateAndConfirm,
          icon: _isPublishing
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_road_rounded, size: 20),
          label: Text(
            _isPublishing ? 'Publication…' : 'Publier le trajet',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: green.withValues(alpha: 0.55),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );

  Future<void> _selectCity({required bool isDeparture}) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CityPickerSheet(
        cities: _cities,
        title: isDeparture ? 'Ville de départ' : 'Ville d’arrivée',
        selected: isDeparture ? _departure : _destination,
      ),
    );
    if (!mounted || chosen == null) return;
    if ((isDeparture && chosen == _destination) ||
        (!isDeparture && chosen == _departure)) {
      setState(() => _formError =
          'Les villes de départ et d’arrivée doivent être différentes.');
      return;
    }
    setState(() {
      if (isDeparture) {
        _departure = chosen;
      } else {
        _destination = chosen;
      }
      _formError = null;
    });
  }

  void _swapCities() {
    setState(() {
      final previous = _departure;
      _departure = _destination;
      _destination = previous;
      _formError = null;
    });
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _date != null && !_date!.isBefore(today) ? _date! : today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
      builder: (context, child) => _pickerTheme(context, child),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _date = selected;
      _formError = null;
    });
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => _pickerTheme(context, child),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _time = selected;
      _formError = null;
    });
  }

  Widget _pickerTheme(BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: green,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
        ),
        child: child!,
      );

  Future<void> _validateAndConfirm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_departure == null) {
      setState(() => _formError = 'Veuillez choisir une ville de départ.');
      return;
    }
    if (_destination == null) {
      setState(() => _formError = 'Veuillez choisir une ville d’arrivée.');
      return;
    }
    if (_departure == _destination) {
      setState(() => _formError =
          'Les villes de départ et d’arrivée doivent être différentes.');
      return;
    }
    if (_date == null) {
      setState(() => _formError = 'Veuillez choisir la date du trajet.');
      return;
    }
    if (_time == null) {
      setState(() => _formError = 'Veuillez choisir l’heure de départ.');
      return;
    }
    if (_selectedVehicle == null) {
      setState(() => _formError = 'Veuillez sélectionner un véhicule.');
      return;
    }
    if (_availableSeats < 1 || _availableSeats > _seatLimit) {
      setState(() => _formError = 'Veuillez indiquer un nombre de places valide.');
      return;
    }
    if (widget.user.id == null) {
      setState(() => _formError = 'Impossible d’identifier votre compte.');
      return;
    }

    setState(() => _formError = null);
    final confirmed = await _showConfirmation();
    if (!mounted || !confirmed) return;
    await _publish();
  }

  Future<bool> _showConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _CustomDialog(
            icon: Icons.add_road_rounded,
            title: 'Publier ce trajet ?',
            message:
                'Votre trajet sera visible par les étudiants correspondant '
                'à vos critères.',
            cancelLabel: 'Modifier',
            confirmLabel: 'Publier',
            onCancel: () => Navigator.of(dialogContext).pop(false),
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        ) ??
        false;
  }

  Future<void> _publish() async {
    final now = DateTime.now().toIso8601String();
    final numericPrice =
        double.parse(_priceController.text.trim().replaceAll(',', '.'));
    final seatLimit = _selectedVehicle!.seats.clamp(1, 7);
    final seats = _availableSeats.clamp(1, seatLimit);

    setState(() => _isPublishing = true);
    try {
      final tripId = await _tripRepository.createTrip(
        Trip(
          driverId: widget.user.id!,
          vehicleId: _selectedVehicle!.id!,
          departure: _departure!,
          destination: _destination!,
          departureDate: _formatIsoDate(_date!),
          departureTime: _formatTime(_time!),
          totalSeats: seats,
          availableSeats: seats,
          price: numericPrice,
          meetingPoint: _meetingPointController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          status: 'available',
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (tripId <= 0) {
        throw StateError('SQLite did not return a valid trip ID.');
      }
      if (!mounted) return;
      setState(() => _isPublishing = false);
      widget.onTripPublished?.call();
      await _showSuccess(tripId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      _showInfoDialog(
        title: 'Publication impossible',
        message: 'Impossible de publier le trajet. Vérifiez vos informations '
            'et réessayez.',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _showSuccess(int tripId) async {
    final viewTrips = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CustomDialog(
        icon: Icons.check_rounded,
        title: 'Trajet publié !',
        message: 'Votre trajet a été publié avec succès.',
        confirmLabel: 'Voir mes trajets',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        showCancel: false,
      ),
    );
    if (!mounted || viewTrips != true) return;
    widget.onViewTripsTap?.call();
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1ECE8)),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: secondaryBlue, size: 19),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _cityField({
    required String label,
    required String? value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) => _selectionField(
        label: label,
        value: value ?? 'Choisir une ville',
        icon: icon,
        iconColor: iconColor,
        onTap: onTap,
      );

  Widget _selectionField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = secondaryBlue,
  }) => Material(
        color: const Color(0xFFFCFDFC),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE7E3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: textGrey, size: 19),
              ],
            ),
          ),
        ),
      );

  Widget _stepButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) => SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            foregroundColor: secondaryBlue,
            backgroundColor: lightBlue,
            disabledForegroundColor: const Color(0xFF9EADB5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
          icon: Icon(icon, size: 18),
        ),
      );

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? suffix,
  }) => InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: secondaryBlue, size: 19),
        filled: true,
        fillColor: const Color(0xFFFCFDFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE7E3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE7E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: secondaryBlue, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.3),
        ),
      );

  Widget _errorPanel(String message) => Container(
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

  Future<void> _showInfoDialog({
    required String title,
    required String message,
    required IconData icon,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(23, 23, 23, 19),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
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
                child: Icon(icon, color: green, size: 27),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textGrey, fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

class _CityPickerSheet extends StatelessWidget {
  final List<String> cities;
  final String title;
  final String? selected;

  const _CityPickerSheet({
    required this.cities,
    required this.title,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.72),
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF123D68),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = city == selected;
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: Color(0xFF1E5AA8)),
                      title: Text(city),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF20B978))
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

class _CustomDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;
  final bool showCancel;

  const _CustomDialog({
    required this.icon,
    required this.title,
    required this.message,
    this.cancelLabel,
    required this.confirmLabel,
    this.onCancel,
    required this.onConfirm,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(23, 23, 23, 19),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF20B978), size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF123D68),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF547080),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (showCancel) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF547080),
                          minimumSize: const Size.fromHeight(46),
                          side: const BorderSide(color: Color(0xFFD8E6E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(cancelLabel ?? 'Annuler'),
                      ),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF123D68),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
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
