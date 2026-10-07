import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/booking.dart';
import '../../../models/user.dart';
import '../../../repositories/booking_repository.dart';
import '../../shared/reporting/report_form_screen.dart';

class PassengerBookingDetailsScreen extends StatefulWidget {
  final int bookingId;
  final User user;

  const PassengerBookingDetailsScreen({
    super.key,
    required this.bookingId,
    required this.user,
  });

  @override
  State<PassengerBookingDetailsScreen> createState() => _PassengerBookingDetailsScreenState();
}

class _PassengerBookingDetailsScreenState extends State<PassengerBookingDetailsScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);

  final BookingRepository _repository = BookingRepository();
  Booking? _booking;
  bool _loading = true;
  bool _loadFailed = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final passengerId = widget.user.id;
    if (passengerId == null) {
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
      final booking = await _repository.getBookingForPassenger(
        bookingId: widget.bookingId,
        passengerId: passengerId,
      );
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : _loadFailed
                      ? _messageState('Impossible de charger la réservation', 'Réessayez dans quelques instants.', retry: true)
                      : booking == null
                          ? _messageState('Réservation introuvable', 'Cette réservation n’existe plus ou ne vous appartient pas.')
                          : _content(booking),
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
              child: IconButton(
                tooltip: 'Retour',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: primaryBlue),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Détails de la réservation', style: TextStyle(color: primaryBlue, fontSize: 19, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

  Widget _content(Booking booking) {
    final tripDate = _departure(booking);
    final canCancel = (booking.status == 'pending' || booking.status == 'accepted') &&
        booking.tripStatus == 'available' &&
        tripDate != null &&
        tripDate.isAfter(DateTime.now());
    final canReport = booking.status == 'pending' || booking.status == 'accepted';
    final total = (booking.pricePerSeat ?? 0) * booking.seatsReserved;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(19, 10, 19, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: 'Trajet',
            icon: Icons.route_rounded,
            children: [
              Text('${booking.departure ?? 'Départ'} → ${booking.destination ?? 'Destination'}', style: const TextStyle(color: primaryBlue, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              _line(Icons.calendar_today_rounded, _dateTime(booking)),
              const SizedBox(height: 8),
              _line(Icons.payments_outlined, '${_money(booking.pricePerSeat ?? 0)} TND par place'),
              const SizedBox(height: 8),
              _line(Icons.event_seat_outlined, '${booking.seatsReserved} ${booking.seatsReserved == 1 ? 'place réservée' : 'places réservées'}'),
              const Divider(height: 20, color: Color(0xFFE8EFEC)),
              _line(Icons.receipt_long_outlined, 'Total : ${_money(total)} TND', strong: true),
              const SizedBox(height: 8),
              _line(Icons.info_outline_rounded, 'Réservation : ${_bookingStatus(booking.status)}'),
              const SizedBox(height: 8),
              _line(Icons.directions_car_outlined, 'Trajet : ${_tripStatus(booking.tripStatus)}'),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Point de rendez-vous',
            icon: Icons.location_on_rounded,
            children: [
              Text(
                booking.meetingPoint?.trim().isNotEmpty == true
                    ? booking.meetingPoint!.trim()
                    : 'Point de rendez-vous non renseigné',
                style: const TextStyle(color: primaryBlue, fontSize: 12, height: 1.45),
              ),
            ],
          ),
          if (booking.driverName != null || booking.vehicleBrand != null) ...[
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Conducteur et véhicule',
              icon: Icons.directions_car_rounded,
              children: [
                if (booking.driverName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, color: secondaryBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(booking.driverName!, style: const TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w700))),
                      if (booking.driverIsVerified == true)
                        const Icon(Icons.verified_rounded, color: green, size: 17),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (booking.vehicleBrand != null || booking.vehicleModel != null)
                  _line(
                    Icons.directions_car_rounded,
                    [
                      if (booking.vehicleBrand?.isNotEmpty == true) booking.vehicleBrand,
                      if (booking.vehicleModel?.isNotEmpty == true) booking.vehicleModel,
                      if (booking.vehicleColor?.trim().isNotEmpty == true) booking.vehicleColor!.trim(),
                      if (booking.vehicleSeats != null) '${booking.vehicleSeats} places',
                    ].join(' • '),
                  ),
              ],
            ),
          ],
          if (booking.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Informations supplémentaires',
              icon: Icons.notes_rounded,
              children: [Text(booking.description!.trim(), style: const TextStyle(color: primaryBlue, fontSize: 12, height: 1.45))],
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _cancelling ? null : _confirmCancellation,
                icon: _cancelling
                    ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Annuler la réservation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB63A3A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
          if (canReport) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _openReport(booking),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Signaler un problème'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryBlue,
                  side: const BorderSide(color: Color(0xFFDCE7E3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openReport(Booking booking) async {
    final bookingId = booking.id;
    if (bookingId == null || widget.user.role != 'passenger') return;
    final route = '${booking.departure ?? 'Départ'} → ${booking.destination ?? 'Destination'}';
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReportFormScreen(
          reporter: widget.user,
          bookingId: bookingId,
          flow: ReportFlow.passengerReportsDriver,
          targetName: booking.driverName ?? 'Conducteur',
          routeLabel: route,
        ),
      ),
    );
    if (!mounted || submitted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Votre signalement a été envoyé.')),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EBE7)),
          boxShadow: [BoxShadow(color: primaryBlue.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: secondaryBlue, size: 18), const SizedBox(width: 8), Text(title, style: const TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 13),
            ...children,
          ],
        ),
      );

  Widget _line(IconData icon, String text, {bool strong = false}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green, size: 17),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: strong ? primaryBlue : textGrey, fontSize: 11.5, height: 1.4, fontWeight: strong ? FontWeight.w800 : FontWeight.w600))),
        ],
      );

  Widget _messageState(String title, String message, {bool retry = false}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.confirmation_number_outlined, color: secondaryBlue, size: 42),
              const SizedBox(height: 13),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: primaryBlue, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: textGrey, fontSize: 12)),
              if (retry) TextButton(onPressed: _loadBooking, child: const Text('Réessayer')),
              TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Retour')),
            ],
          ),
        ),
      );

  Future<void> _confirmCancellation() async {
    final booking = _booking;
    final passengerId = widget.user.id;
    if (booking?.id == null || passengerId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB63A3A), size: 38),
              const SizedBox(height: 12),
              const Text('Annuler la réservation ?', textAlign: TextAlign.center, style: TextStyle(color: primaryBlue, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Les places seront remises à disposition si le trajet est toujours disponible.', textAlign: TextAlign.center, style: TextStyle(color: textGrey, fontSize: 12, height: 1.45)),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Retour'))),
                  const SizedBox(width: 9),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB63A3A), foregroundColor: Colors.white),
                      child: const Text('Annuler la réservation'),
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
    setState(() => _cancelling = true);
    try {
      await _repository.cancelBooking(bookingId: booking!.id!, passengerId: passengerId);
      if (!mounted) return;
      setState(() => _cancelling = false);
      await _loadBooking();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      await _showErrorDialog();
      if (!mounted) return;
    }
  }

  Future<void> _showErrorDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annulation impossible'),
        content: const Text('La réservation n’a pas pu être annulée. Actualisez puis réessayez.'),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Compris'))],
      ),
    );
    if (!mounted) return;
  }

  DateTime? _departure(Booking booking) {
    final date = booking.departureDate;
    final time = booking.departureTime;
    if (date == null || time == null) return null;
    final parsedDate = DateTime.tryParse(date);
    final parts = time.split(':');
    if (parsedDate == null || parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
  }

  String _dateTime(Booking booking) {
    final date = booking.departureDate == null ? null : DateTime.tryParse(booking.departureDate!);
    final formatted = date == null ? booking.departureDate ?? 'Date inconnue' : DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    return booking.departureTime == null ? formatted : '$formatted • ${booking.departureTime}';
  }

  String _bookingStatus(String status) => switch (status) {
        'pending' => 'En attente',
      'accepted' => 'Acceptée',
      'rejected' => 'Refusée',
        'cancelled' => 'Annulée',
        _ => status,
      };

  String _tripStatus(String? status) => switch (status) {
        'available' => 'Disponible',
        'cancelled' => 'Annulé',
        'completed' => 'Terminé',
        null => 'Indisponible',
        _ => status,
      };

  String _money(double amount) => amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
}
