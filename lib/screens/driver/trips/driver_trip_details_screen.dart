import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/trip_details.dart';
import '../../../models/user.dart';
import '../../../repositories/trip_repository.dart';
import '../bookings/driver_trip_bookings_screen.dart';

class DriverTripDetailsScreen extends StatefulWidget {
  final int tripId;
  final User user;
  final Future<bool> Function()? onEditTrip;

  const DriverTripDetailsScreen({
    super.key,
    required this.tripId,
    required this.user,
    this.onEditTrip,
  });

  @override
  State<DriverTripDetailsScreen> createState() => _DriverTripDetailsScreenState();
}

class _DriverTripDetailsScreenState extends State<DriverTripDetailsScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);
  static const Color lightGreen = Color(0xFFE8F8F1);

  final TripRepository _repository = TripRepository();
  TripDetails? _trip;
  bool _loading = true;
  bool _loadFailed = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final driverId = widget.user.id;
    if (driverId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final trip = await _repository.getDriverTripDetails(
        tripId: widget.tripId,
        driverId: driverId,
      );
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? _loadingState()
                  : _loadFailed
                      ? _errorState()
                      : trip == null
                          ? _notFoundState()
                          : _content(trip),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: Row(
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              elevation: 1,
              shadowColor: primaryBlue.withValues(alpha: 0.12),
              child: IconButton(
                tooltip: 'Retour',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: primaryBlue),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Détails du trajet',
              style: TextStyle(color: primaryBlue, fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );

  Widget _content(TripDetails trip) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(19, 10, 19, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(trip),
            const SizedBox(height: 18),
            _section('Véhicule'),
            const SizedBox(height: 8),
            _card(
              icon: Icons.directions_car_rounded,
              iconColor: secondaryBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${trip.vehicleBrand} ${trip.vehicleModel}', style: _strongStyle()),
                  const SizedBox(height: 5),
                  Text(
                    [
                      if (trip.vehicleColor?.trim().isNotEmpty == true) trip.vehicleColor!.trim(),
                      '${trip.vehicleSeats} places',
                    ].join(' • '),
                    style: const TextStyle(color: textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            _section('Point de rendez-vous'),
            const SizedBox(height: 8),
            _card(
              icon: Icons.location_on_rounded,
              iconColor: green,
              child: Text(
                trip.meetingPoint.trim().isEmpty
                    ? 'Point de rendez-vous non renseigné'
                    : trip.meetingPoint.trim(),
                style: const TextStyle(color: primaryBlue, fontSize: 12, height: 1.4),
              ),
            ),
            if (trip.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 17),
              _section('Informations supplémentaires'),
              const SizedBox(height: 8),
              _card(
                icon: Icons.notes_rounded,
                iconColor: secondaryBlue,
                child: Text(
                  trip.description!.trim(),
                  style: const TextStyle(color: primaryBlue, fontSize: 12, height: 1.45),
                ),
              ),
            ],
            const SizedBox(height: 17),
            _section('Réservations'),
            const SizedBox(height: 8),
            _bookingCard(trip),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 47,
              child: OutlinedButton.icon(
                onPressed: _openTripBookings,
                icon: const Icon(Icons.people_outline_rounded, size: 18),
                label: const Text('Voir les réservations'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryBlue,
                  side: const BorderSide(color: Color(0xFFDCE7E3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 49,
              child: OutlinedButton.icon(
                onPressed: trip.status == 'available' && widget.onEditTrip != null ? _editTrip : null,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier le trajet'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryBlue,
                  disabledForegroundColor: textGrey,
                  side: const BorderSide(color: Color(0xFFDCE7E3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 49,
              child: ElevatedButton.icon(
                onPressed: _cancelling || trip.status != 'available' ? null : _confirmCancel,
                icon: _cancelling
                    ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Annuler le trajet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB63A3A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD4DAD7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _summaryCard(TripDetails trip) {
    final date = DateTime.tryParse(trip.departureDate);
    final dateLabel = date == null
        ? trip.departureDate
        : DateFormat('dd MMM yyyy', 'fr_FR').format(date).toUpperCase();
    final booked = (trip.totalSeats - trip.availableSeats).clamp(0, trip.totalSeats);
    final status = trip.status == 'cancelled'
        ? 'Annulé'
        : trip.availableSeats <= 0
            ? 'Complet'
            : trip.status == 'available'
                ? 'Disponible'
                : trip.status;
    final statusColor = trip.status == 'cancelled' ? const Color(0xFFB63A3A) : green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(dateLabel, style: const TextStyle(color: secondaryBlue, fontSize: 12, fontWeight: FontWeight.w800))),
              _badge(status, statusColor),
              const SizedBox(width: 8),
              Text(trip.departureTime, style: const TextStyle(color: primaryBlue, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 19),
          _routeRow(trip.departure, start: true),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(height: 22, child: VerticalDivider(width: 2, thickness: 2, color: Color(0xFFDCE7E3))),
          ),
          _routeRow(trip.destination, start: false),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1, color: Color(0xFFE8EFEC))),
          _metricRow('Prix par passager', '${_formatPrice(trip.price)} TND', icon: Icons.payments_outlined),
          const SizedBox(height: 9),
          _metricRow('Places disponibles', '${trip.availableSeats}', icon: Icons.event_seat_outlined),
          const SizedBox(height: 9),
          _metricRow('Places réservées', '$booked', icon: Icons.people_outline_rounded),
          const SizedBox(height: 9),
          _metricRow('Places restantes', '${trip.availableSeats}', icon: Icons.airline_seat_recline_normal_rounded),
        ],
      ),
    );
  }

  Widget _routeRow(String city, {required bool start}) => Row(
        children: [
          Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color: start ? lightGreen : lightBlue,
              shape: BoxShape.circle,
              border: Border.all(color: start ? green : secondaryBlue, width: 1.5),
            ),
            child: Center(child: Container(width: 5, height: 5, decoration: BoxDecoration(color: start ? green : secondaryBlue, shape: BoxShape.circle))),
          ),
          const SizedBox(width: 11),
          Expanded(child: Text(city, maxLines: 2, overflow: TextOverflow.ellipsis, style: _strongStyle())),
        ],
      );

  Widget _metricRow(String label, String value, {required IconData icon}) => Row(
        children: [
          Icon(icon, color: green, size: 17),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _bookingCard(TripDetails trip) {
    final bookedSeats = (trip.totalSeats - trip.availableSeats).clamp(0, trip.totalSeats);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metricRow('Places réservées', '$bookedSeats', icon: Icons.event_seat_rounded),
          const SizedBox(height: 9),
          _metricRow('Demandes en attente', '${trip.pendingRequests}', icon: Icons.hourglass_bottom_rounded),
          const SizedBox(height: 9),
          _metricRow('Places restantes', '${trip.availableSeats}', icon: Icons.airline_seat_recline_normal_rounded),
          if (bookedSeats == 0 && trip.pendingRequests == 0) ...[
            const SizedBox(height: 9),
            const Text('Aucune réservation pour le moment.', style: TextStyle(color: textGrey, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _section(String text) => Text(text, style: const TextStyle(color: primaryBlue, fontSize: 15, fontWeight: FontWeight.w800));

  Widget _card({required IconData icon, required Color iconColor, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: _decoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Icon(icon, color: iconColor, size: 19), const SizedBox(width: 10), Expanded(child: child)],
        ),
      );

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
        child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
      );

  BoxDecoration _decoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2EBE7)),
        boxShadow: [BoxShadow(color: primaryBlue.withValues(alpha: 0.045), blurRadius: 12, offset: const Offset(0, 4))],
      );

  TextStyle _strongStyle() => const TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.w800);

  Widget _loadingState() => const Center(child: CircularProgressIndicator(color: green));

  Widget _errorState() => _messageState('Impossible de charger le trajet', 'Ce trajet n’est peut-être plus disponible.', retry: true);

  Widget _notFoundState() => _messageState('Trajet introuvable', 'Ce trajet n’existe pas ou ne vous appartient pas.');

  Widget _messageState(String title, String message, {bool retry = false}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_outlined, color: secondaryBlue, size: 42),
              const SizedBox(height: 13),
              Text(title, textAlign: TextAlign.center, style: _strongStyle()),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: textGrey, fontSize: 12)),
              if (retry) TextButton(onPressed: _loadTrip, child: const Text('Réessayer')),
              TextButton.icon(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_rounded), label: const Text('Retour')),
            ],
          ),
        ),
      );

  Future<void> _editTrip() async {
    final editTrip = widget.onEditTrip;
    if (editTrip == null) return;
    final updated = await editTrip();
    if (!mounted) return;
    if (updated) await _loadTrip();
  }

  Future<void> _openTripBookings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DriverTripBookingsScreen(
          tripId: widget.tripId,
          user: widget.user,
        ),
      ),
    );
    if (!mounted) return;
    await _loadTrip();
    if (!mounted) return;
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 23, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEFEF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB63A3A), size: 27),
              ),
              const SizedBox(height: 15),
              const Text(
                'Annuler ce trajet ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryBlue, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les réservations associées à ce trajet devront être traitées.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textGrey, fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlue,
                        side: const BorderSide(color: Color(0xFFDCE7E3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Retour'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB63A3A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Annuler le trajet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    final driverId = widget.user.id;
    if (driverId == null) return;
    setState(() => _cancelling = true);
    try {
      final changed = await _repository.cancelTrip(tripId: widget.tripId, driverId: driverId);
      if (!mounted) return;
      setState(() => _cancelling = false);
      if (changed == 0) {
        _showMessage('Le trajet n’a pas pu être annulé.');
        await _loadTrip();
        if (!mounted) return;
        return;
      }
      await _loadTrip();
      if (!mounted) return;
      _showMessage('Le trajet a été annulé.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      _showMessage('Impossible d’annuler ce trajet. Réessayez plus tard.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  String _formatPrice(double price) => price == price.roundToDouble() ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
}
