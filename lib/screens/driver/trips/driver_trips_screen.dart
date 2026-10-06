import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/trip.dart';
import '../../../models/user.dart';
import '../../../models/vehicle.dart';
import '../../../repositories/trip_repository.dart';
import '../../../repositories/vehicle_repository.dart';
import '../../../widgets/driver/driver_header.dart';
import 'driver_trip_details_screen.dart';

enum DriverTripsFilter { upcoming, past, cancelled }

class DriverTripsScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onPublishTap;

  const DriverTripsScreen({
    super.key,
    required this.user,
    this.onPublishTap,
  });

  @override
  State<DriverTripsScreen> createState() => DriverTripsScreenState();
}

class DriverTripsScreenState extends State<DriverTripsScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);

  final TripRepository _tripRepository = TripRepository();
  final VehicleRepository _vehicleRepository = VehicleRepository();
  final Map<int, Vehicle> _vehicles = {};

  DriverTripsFilter _filter = DriverTripsFilter.upcoming;
  bool _isLoading = true;
  String? _errorMessage;
  List<Trip> _upcomingTrips = const [];
  List<Trip> _pastTrips = const [];
  List<Trip> _cancelledTrips = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadTrips();
    });
  }

  Future<void> _loadTrips() async {
    final userId = widget.user.id;
    debugPrint('Loading driver trips for user: $userId');

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible d’identifier votre compte.';
      });
      return;
    }

    try {
      final vehicles = await _vehicleRepository.getVehiclesForUser(userId);
      if (!mounted) return;
      final trips = await _tripRepository.getTripsForDriver(userId);
      debugPrint('Loaded trips: ${trips.length}');

      if (!mounted) return;
      setState(() {
        _vehicles
          ..clear()
          ..addEntries(
            vehicles.map((vehicle) => MapEntry(vehicle.id!, vehicle)),
          );
        _upcomingTrips = trips
            .where((trip) => trip.status == 'available' && _isDateTimeFuture(trip))
            .toList();
        _pastTrips = trips
            .where((trip) => trip.status == 'available' && _isDateTimePast(trip))
            .toList();
        _cancelledTrips = trips
            .where((trip) => trip.status == 'cancelled')
            .toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error, stackTrace) {
      debugPrint('LOAD DRIVER TRIPS ERROR: $error');
      debugPrint('$stackTrace');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger vos trajets.';
      });
    }
  }

  void refresh() => _loadTrips();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTrips,
          color: primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(19, 12, 19, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DriverHeader(
                        user: widget.user,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Mes trajets',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Gérez vos trajets et suivez vos réservations.',
                        style: TextStyle(
                          color: textGrey.withValues(alpha: 0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildStatsRow(),
                      const SizedBox(height: 18),
                      _buildFilterTabs(),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(child: _LoadingState()),
              if (!_isLoading && _errorMessage != null)
                SliverToBoxAdapter(child: _ErrorState(_errorMessage!)),
              if (!_isLoading && _errorMessage == null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(19, 14, 19, 30),
                  sliver: _buildSelectedList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final upcoming = _upcomingTrips.length;
    final totalSeats = _upcomingTrips.fold<int>(0, (sum, trip) => sum + trip.totalSeats);
    final availableSeats = _upcomingTrips.fold<int>(0, (sum, trip) => sum + trip.availableSeats);

    return Row(
      children: [
        Expanded(child: _statCard('Trajets', upcoming.toString())),
        const SizedBox(width: 9),
        Expanded(child: _statCard('Places partagées', totalSeats.toString())),
        const SizedBox(width: 9),
        Expanded(child: _statCard('Places disponibles', availableSeats.toString())),
      ],
    );
  }

  Widget _statCard(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1EAE7)),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: primaryBlue,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textGrey.withValues(alpha: 0.7),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterTabs() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1EAE7)),
        ),
        child: Row(
          children: DriverTripsFilter.values.map((filter) {
            final selected = _filter == filter;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: selected ? lightBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _filter = filter),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        _labelForFilter(filter),
                        style: TextStyle(
                          color: selected ? secondaryBlue : textGrey,
                          fontSize: 12.5,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  String _labelForFilter(DriverTripsFilter filter) => switch (filter) {
        DriverTripsFilter.upcoming => 'À venir',
        DriverTripsFilter.past => 'Terminé',
        DriverTripsFilter.cancelled => 'Annulés',
      };

  Widget _buildSelectedList() {
    final items = switch (_filter) {
      DriverTripsFilter.upcoming => _upcomingTrips,
      DriverTripsFilter.past => _pastTrips,
      DriverTripsFilter.cancelled => _cancelledTrips,
    };

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: switch (_filter) {
          DriverTripsFilter.upcoming => _EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'Aucun trajet à venir',
              description:
                  'Publiez un trajet pour proposer vos places aux autres étudiants.',
              buttonLabel: 'Publier un trajet',
              onPressed: () => _showPublishTrip(),
            ),
          DriverTripsFilter.past => _EmptyState(
              icon: Icons.history_rounded,
              title: 'Aucun trajet terminé',
              description: 'Vos trajets passés apparaîtront ici.',
            ),
          DriverTripsFilter.cancelled => _EmptyState(
              icon: Icons.cancel_outlined,
              title: 'Aucun trajet annulé',
              description: 'Vos trajets annulés apparaîtront ici.',
            ),
        },
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: items.length,
        (context, index) => _TripCard(
          trip: items[index],
          vehicle: _vehicles[items[index].vehicleId],
          onDetails: () => _openTripDetails(items[index]),
          onEdit: () => _editTrip(items[index]),
          onCancel: () => _cancelTrip(items[index]),
        ),
      ),
    );
  }

  void _showPublishTrip() {
    widget.onPublishTap?.call();
  }

  Future<bool> _editTrip(Trip trip) async {
    final userId = widget.user.id;
    if (userId == null) return false;
    final vehicles = await _vehicleRepository.getVehiclesForUser(userId);
    if (!mounted) return false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTripSheet(
        trip: trip,
        vehicles: vehicles,
        user: widget.user,
      ),
    );
    if (!mounted) return false;
    if (result == true) await _loadTrips();
    return result == true;
  }

  Future<void> _openTripDetails(Trip trip) async {
    final tripId = trip.id;
    if (tripId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DriverTripDetailsScreen(
          tripId: tripId,
          user: widget.user,
          onEditTrip: () => _editTrip(trip),
        ),
      ),
    );
    if (!mounted) return;
    await _loadTrips();
  }

  Future<void> _cancelTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _CustomDialog(
        icon: Icons.warning_amber_rounded,
        title: 'Annuler ce trajet ?',
        message: 'Les passagers ayant réservé ce trajet devront être informés.',
        cancelLabel: 'Retour',
        confirmLabel: 'Annuler le trajet',
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      final updated = await _tripRepository.cancelTrip(
        tripId: trip.id!,
        driverId: widget.user.id!,
      );
      if (updated == 0) {
        throw StateError('Le trajet n’a pas été trouvé ou ne vous appartient pas.');
      }
      if (!mounted) return;
      refresh();
      _showInfoDialog(
        title: 'Trajet annulé',
        message: 'Le trajet a été marqué comme annulé.',
        icon: Icons.check_circle_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      _showInfoDialog(
        title: 'Annulation impossible',
        message: 'Impossible d’annuler ce trajet. Réessayez plus tard.',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _showInfoDialog({
    required String title,
    required String message,
    required IconData icon,
  }) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _CustomDialog(
        icon: icon,
        title: title,
        message: message,
        cancelLabel: 'Fermer',
        confirmLabel: 'Compris',
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  bool _isDateTimeFuture(Trip trip) {
    final dateTime = _tripDateTime(trip);
    return dateTime.isAfter(DateTime.now());
  }

  bool _isDateTimePast(Trip trip) {
    final dateTime = _tripDateTime(trip);
    return dateTime.isBefore(DateTime.now());
  }

  DateTime _tripDateTime(Trip trip) {
    final parts = trip.departureDate.split('-');
    final timeParts = trip.departureTime.split(':');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.vehicle,
    required this.onDetails,
    required this.onEdit,
    required this.onCancel,
  });

  final Trip trip;
  final Vehicle? vehicle;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color textGrey = Color(0xFF547080);
  static const Color green = Color(0xFF20B978);
  static const Color lightBlue = Color(0xFFEAF3FC);

  @override
  Widget build(BuildContext context) {
    final bookingSummary = _bookingSummary();
    final statusLabel = trip.status == 'cancelled' ? 'Annulé' : trip.status == 'available' ? 'Disponible' : trip.status;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1EAE7)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  DateFormat('dd MMM', 'fr_FR').format(DateTime.parse(trip.departureDate)).toUpperCase(),
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: trip.status == 'cancelled' ? const Color(0xFFFFEFEF) : lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: trip.status == 'cancelled' ? const Color(0xFFBA3A3A) : secondaryBlue,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                trip.departureTime,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.trip_origin_rounded, color: green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.departure,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, color: textGrey, size: 18),
              ),
              const Icon(Icons.location_on_rounded, color: Color(0xFF1E5AA8), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.destination,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _metaRow(Icons.directions_car_rounded, vehicle == null ? 'Véhicule' : '${vehicle!.brand} ${vehicle!.model}'),
              if (trip.meetingPoint.trim().isNotEmpty)
                _metaRow(Icons.location_pin, trip.meetingPoint),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.event_seat_rounded, color: green, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        bookingSummary,
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${trip.price.toStringAsFixed(0)} TND',
                  style: const TextStyle(
                    color: secondaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (trip.status == 'available') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionButton(
                  label: 'Voir détails',
                  icon: Icons.visibility_outlined,
                  onPressed: onDetails,
                ),
                _ActionButton(
                  label: 'Modifier',
                  icon: Icons.edit_outlined,
                  onPressed: onEdit,
                ),
                _ActionButton(
                  label: 'Annuler',
                  icon: Icons.cancel_outlined,
                  onPressed: onCancel,
                  danger: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _bookingSummary() {
    final booked = trip.totalSeats - trip.availableSeats;
    final remaining = trip.availableSeats;
    final pending = trip.pendingRequests;
    if (pending > 0 && booked == 0) {
      return '$pending demande${pending == 1 ? '' : 's'} en attente';
    }
    return '$booked place${booked == 1 ? '' : 's'} réservée${booked == 1 ? '' : 's'} • $remaining place${remaining == 1 ? '' : 's'} restante${remaining == 1 ? '' : 's'}';
  }

  Widget _metaRow(IconData icon, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textGrey, size: 15),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textGrey.withValues(alpha: 0.92),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB63A3A) : const Color(0xFF1E5AA8);
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: danger ? const Color(0xFFFFF1F1) : const Color(0xFFF6F9FD),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _EditTripSheet extends StatefulWidget {
  const _EditTripSheet({
    required this.trip,
    required this.vehicles,
    required this.user,
  });

  final Trip trip;
  final List<Vehicle> vehicles;
  final User user;

  @override
  State<_EditTripSheet> createState() => _EditTripSheetState();
}

class _EditTripSheetState extends State<_EditTripSheet> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color textGrey = Color(0xFF547080);
  static const Color green = Color(0xFF20B978);

  final _formKey = GlobalKey<FormState>();
  final _tripRepository = TripRepository();
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  Vehicle? _selectedVehicle;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _departureController.text = widget.trip.departure;
    _destinationController.text = widget.trip.destination;
    _meetingPointController.text = widget.trip.meetingPoint;
    _priceController.text = widget.trip.price.toStringAsFixed(0);
    _seatsController.text = widget.trip.totalSeats.toString();
    _descriptionController.text = widget.trip.description ?? '';
    _date = DateTime.parse(widget.trip.departureDate);
    _time = TimeOfDay(hour: int.parse(widget.trip.departureTime.split(':')[0]), minute: int.parse(widget.trip.departureTime.split(':')[1]));
    _selectedVehicle = widget.vehicles.firstWhere(
      (vehicle) => vehicle.id == widget.trip.vehicleId,
      orElse: () => widget.vehicles.first,
    );
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _meetingPointController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E4DF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modifier le trajet',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Modifiez uniquement les informations disponibles pour ce trajet.',
                        style: TextStyle(color: textGrey, fontSize: 12.5, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      _field('Ville de départ', _departureController, Icons.trip_origin_rounded, true),
                      const SizedBox(height: 12),
                      _field('Ville d’arrivée', _destinationController, Icons.location_on_rounded, true),
                      const SizedBox(height: 12),
                      _dateTimeRow(),
                      const SizedBox(height: 12),
                      _field('Point de rendez-vous', _meetingPointController, Icons.location_pin, false),
                      const SizedBox(height: 12),
                      _vehicleSelector(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _numericField('Places', _seatsController, Icons.event_seat_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: _numericField('Prix (TND)', _priceController, Icons.euro_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field('Description', _descriptionController, Icons.notes_outlined, false, maxLines: 3),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Enregistrer les modifications'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon, bool required, {int maxLines = 1}) => TextFormField(
        controller: controller,
        validator: required ? (value) => (value == null || value.trim().isEmpty) ? 'Ce champ est obligatoire.' : null : null,
        maxLines: maxLines,
        style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
        decoration: _inputDecoration(label, icon),
      );

  Widget _numericField(String label, TextEditingController controller, IconData icon) => TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Obligatoire.';
          return null;
        },
        decoration: _inputDecoration(label, icon),
      );

  Widget _dateTimeRow() => Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDCE7E3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: green, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _date == null ? 'Date du trajet' : DateFormat('dd MMM yyyy', 'fr_FR').format(_date!),
                        style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickTime,
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDCE7E3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: secondaryBlue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _time == null ? 'Heure' : _time!.format(context),
                        style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _vehicleSelector() => DropdownButtonFormField<Vehicle>(
        initialValue: _selectedVehicle,
        isExpanded: true,
        decoration: _inputDecoration('Véhicule', Icons.directions_car_rounded),
        items: widget.vehicles.map((vehicle) {
          return DropdownMenuItem<Vehicle>(
            value: vehicle,
            child: Text('${vehicle.brand} ${vehicle.model} • ${vehicle.licensePlate}'),
          );
        }).toList(),
        onChanged: (vehicle) => setState(() => _selectedVehicle = vehicle),
      );

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: secondaryBlue, size: 19),
        filled: true,
        fillColor: const Color(0xFFFCFDFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
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
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Choisissez la date',
    );
    if (!mounted) return;
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      helpText: 'Choisissez l’heure de départ',
    );
    if (!mounted) return;
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null || _selectedVehicle == null) {
      _showMessage('Veuillez compléter la date, l’heure et le véhicule.');
      return;
    }

    final seats = int.tryParse(_seatsController.text.trim());
    final price = double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    if (seats == null || seats < 1 || seats > _selectedVehicle!.seats) {
      _showMessage('Le nombre de places doit être valide pour ce véhicule.');
      return;
    }
    if (price == null || price < 0) {
      _showMessage('Le prix doit être un nombre valide.');
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await _tripRepository.updateTrip(
        tripId: widget.trip.id!,
        driverId: widget.user.id!,
        departure: _departureController.text.trim(),
        destination: _destinationController.text.trim(),
        departureDate: DateFormat('yyyy-MM-dd').format(_date!),
        departureTime: '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
        totalSeats: seats,
        availableSeats: math.max(0, seats - (widget.trip.totalSeats - widget.trip.availableSeats)),
        price: price,
        meetingPoint: _meetingPointController.text.trim(),
        description: _descriptionController.text.trim(),
        vehicleId: _selectedVehicle!.id!,
      );
      if (updated == 0) throw StateError('Aucune modification effectuée.');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Impossible de modifier ce trajet.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _CustomDialog extends StatelessWidget {
  const _CustomDialog({
    required this.icon,
    required this.title,
    required this.message,
    this.cancelLabel,
    this.confirmLabel,
    this.onCancel,
    this.onConfirm,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? cancelLabel;
  final String? confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
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
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF547080),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF123D68),
                      side: const BorderSide(color: Color(0xFFD7E5E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(cancelLabel ?? 'Retour'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF123D68),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmLabel ?? 'Valider'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1EAE7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8F1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF20B978), size: 38),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF123D68),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF547080),
              fontSize: 12.7,
              height: 1.45,
            ),
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add_road_rounded),
                label: Text(buttonLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF123D68),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: const Center(
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF123D68)),
            ),
            SizedBox(height: 12),
            Text(
              'Chargement de vos trajets...',
              style: TextStyle(color: Color(0xFF547080), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 30),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0D4D2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFB93E36)),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB93E36), fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
