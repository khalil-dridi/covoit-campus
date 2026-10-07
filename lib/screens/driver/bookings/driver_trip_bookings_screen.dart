import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/booking.dart';
import '../../../models/user.dart';
import '../../../repositories/booking_repository.dart';
import '../../shared/messages/chat_screen.dart';
import '../../shared/notifications_screen.dart';
import '../../shared/reporting/report_form_screen.dart';

class DriverTripBookingsScreen extends StatefulWidget {
  final int tripId;
  final User user;
  final int? focusBookingId;

  const DriverTripBookingsScreen({
    super.key,
    required this.tripId,
    required this.user,
    this.focusBookingId,
  });

  @override
  State<DriverTripBookingsScreen> createState() => _DriverTripBookingsScreenState();
}

class _DriverTripBookingsScreenState extends State<DriverTripBookingsScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);

  final BookingRepository _repository = BookingRepository();
  List<Booking> _bookings = const [];
  bool _loading = true;
  String? _error;
  int? _workingBookingId;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final driverId = widget.user.id;
    if (driverId == null || widget.user.role != 'driver') {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible d’identifier votre compte conducteur.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await _repository.getBookingsForDriverTrip(
        tripId: widget.tripId,
        driverId: driverId,
      );
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les réservations de ce trajet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: primaryBlue),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(child: Text('Réservations du trajet', style: TextStyle(color: primaryBlue, fontSize: 19, fontWeight: FontWeight.w800))),
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: _openNotifications,
                      icon: const Icon(Icons.notifications_none_rounded, color: primaryBlue),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : _error != null
                        ? _empty(_error!, 'Réessayez dans quelques instants.', action: 'Réessayer', onAction: _loadBookings)
                        : _bookings.isEmpty
                            ? _empty('Aucune réservation', 'Les demandes reçues pour ce trajet apparaîtront ici.')
                            : RefreshIndicator(
                                color: primaryBlue,
                                onRefresh: _loadBookings,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                                  itemCount: _bookings.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) => _bookingCard(_bookings[index]),
                                ),
                              ),
              ),
            ],
          ),
        ),
      );

  Widget _bookingCard(Booking booking) {
    final pending = booking.status == 'pending';
    final amount = (booking.pricePerSeat ?? 0) * booking.seatsReserved;
    final focused = booking.id == widget.focusBookingId;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: focused ? green : const Color(0xFFE2EBE7), width: focused ? 1.5 : 1),
        boxShadow: [BoxShadow(color: primaryBlue.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(booking.passengerName ?? 'Passager', style: const TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.w800))),
              _badge(_bookingStatus(booking.status), _statusColor(booking.status)),
            ],
          ),
          if (booking.passengerUniversity?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(booking.passengerUniversity!.trim(), style: const TextStyle(color: textGrey, fontSize: 10.5)),
          ],
          const SizedBox(height: 10),
          _detailLine(Icons.event_seat_outlined, '${booking.seatsReserved} ${booking.seatsReserved == 1 ? 'place demandée' : 'places demandées'}'),
          const SizedBox(height: 6),
          _detailLine(Icons.payments_outlined, '${_money(amount)} TND au total'),
          const SizedBox(height: 6),
          _detailLine(Icons.calendar_today_rounded, _dateTime(booking.createdAt)),
          const SizedBox(height: 6),
          _detailLine(Icons.route_rounded, '${booking.departure ?? 'Départ'} → ${booking.destination ?? 'Destination'}'),
          if (pending) ...[
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _workingBookingId == booking.id ? null : () => _confirmDecision(booking, accept: false),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB63A3A),
                      side: const BorderSide(color: Color(0xFFE8C9C8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _workingBookingId == booking.id ? null : () => _confirmDecision(booking, accept: true),
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (booking.status == 'pending' || booking.status == 'accepted') ...[
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openChat(booking),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Contacter le passager'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryBlue,
                  side: const BorderSide(color: Color(0xFFDCE7E3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: booking.id == null || _workingBookingId == booking.id
                    ? null
                    : () => _openReport(booking),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Signaler ce passager'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryBlue,
                  side: const BorderSide(color: Color(0xFFDCE7E3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
    if (bookingId == null || widget.user.id == null || widget.user.role != 'driver') {
      return;
    }
    final route = '${booking.departure ?? 'Départ'} → ${booking.destination ?? 'Destination'}';
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReportFormScreen(
          reporter: widget.user,
          bookingId: bookingId,
          flow: ReportFlow.driverReportsPassenger,
          targetName: booking.passengerName ?? 'Passager',
          routeLabel: route,
        ),
      ),
    );
    if (!mounted || submitted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Votre signalement a été envoyé.')),
    );
  }

  Future<void> _confirmDecision(Booking booking, {required bool accept}) async {
    final bookingId = booking.id;
    final driverId = widget.user.id;
    if (bookingId == null || driverId == null || widget.user.role != 'driver') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(accept ? 'Accepter la réservation ?' : 'Refuser la réservation ?'),
        content: Text(accept
            ? 'Confirmez-vous la réservation de ${booking.seatsReserved} place(s) par ${booking.passengerName ?? 'ce passager'} ?'
            : 'Confirmez-vous le refus de cette demande ? Les places seront remises à disposition.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Retour')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accept ? green : const Color(0xFFB63A3A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(accept ? 'Accepter' : 'Refuser'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _workingBookingId = bookingId);
    try {
      await _repository.decideBooking(
        bookingId: bookingId,
        driverId: driverId,
        accept: accept,
      );
      if (!mounted) return;
      setState(() => _workingBookingId = null);
      await _loadBookings();
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _workingBookingId = null);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Action impossible'),
          content: const Text('La demande n’a pas pu être mise à jour. Actualisez puis réessayez.'),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Compris'))],
        ),
      );
      if (!mounted) return;
    }
  }

  void _openChat(Booking booking) {
    final driverId = widget.user.id;
    final passengerId = booking.passengerId;
    final passengerName = booking.passengerName ?? 'Passager';
    if (driverId == null) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          tripId: booking.tripId,
          currentUser: widget.user,
          otherUserId: passengerId,
          otherUserName: passengerName,
          tripDeparture: booking.departure,
          tripDestination: booking.destination,
        ),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => NotificationsScreen(user: widget.user)),
    );
    if (!mounted) return;
  }

  Widget _detailLine(IconData icon, String value) => Row(
        children: [
          Icon(icon, color: secondaryBlue, size: 16),
          const SizedBox(width: 7),
          Expanded(child: Text(value, style: const TextStyle(color: textGrey, fontSize: 10.5))),
        ],
      );

  Widget _badge(String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
        child: Text(value, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
      );

  Widget _empty(String title, String message, {String? action, VoidCallback? onAction}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.confirmation_number_outlined, color: secondaryBlue, size: 40),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: primaryBlue, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: textGrey, fontSize: 11.5)),
              if (action != null) TextButton(onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
      );

  String _bookingStatus(String status) => switch (status) {
        'pending' => 'En attente',
        'accepted' => 'Acceptée',
        'rejected' => 'Refusée',
        'cancelled' => 'Annulée',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'pending' => secondaryBlue,
        'accepted' => green,
        'rejected' || 'cancelled' => const Color(0xFFB63A3A),
        _ => textGrey,
      };

  String _dateTime(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(date);
  }

  String _money(double amount) => amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
}
