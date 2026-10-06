import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/booking.dart';
import '../../../models/user.dart';
import '../../../repositories/booking_repository.dart';
import 'passenger_booking_details_screen.dart';

enum _BookingFilter { upcoming, past, cancelled }

class PassengerBookingsScreen extends StatefulWidget {
  final User user;

  const PassengerBookingsScreen({super.key, required this.user});

  @override
  State<PassengerBookingsScreen> createState() => _PassengerBookingsScreenState();
}

class _PassengerBookingsScreenState extends State<PassengerBookingsScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);

  final BookingRepository _repository = BookingRepository();
  List<Booking> _bookings = const [];
  bool _loading = true;
  String? _error;
  _BookingFilter _filter = _BookingFilter.upcoming;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final passengerId = widget.user.id;
    if (passengerId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible d’identifier votre compte.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await _repository.getBookingsForPassenger(passengerId);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger vos réservations.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _bookings.where(_matchesFilter).toList(growable: false);
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryBlue,
          onRefresh: _loadBookings,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(19, 18, 19, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mes réservations',
                        style: TextStyle(color: primaryBlue, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Retrouvez vos trajets réservés.',
                        style: TextStyle(color: textGrey.withValues(alpha: 0.82), fontSize: 13),
                      ),
                      const SizedBox(height: 17),
                      _filterBar(),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: green)),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _messageState(
                    icon: Icons.error_outline_rounded,
                    title: _error!,
                    message: 'Vérifiez votre connexion puis réessayez.',
                    action: 'Réessayer',
                    onAction: _loadBookings,
                  ),
                )
              else if (_bookings.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _messageState(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Aucune réservation',
                    message: 'Vos réservations apparaîtront ici.',
                  ),
                )
              else if (bookings.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _messageState(
                    icon: Icons.event_busy_rounded,
                    title: _emptyTitle,
                    message: 'Aucune réservation dans cette catégorie.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(19, 0, 19, 26),
                  sliver: SliverList.separated(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) => _bookingCard(bookings[index]),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterBar() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE2EBE7)),
        ),
        child: Row(
          children: _BookingFilter.values.map((filter) {
            final selected = filter == _filter;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => setState(() => _filter = filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? lightBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    _filterLabel(filter),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? secondaryBlue : textGrey,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      );

  Widget _bookingCard(Booking booking) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _openDetails(booking),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2EBE7)),
              boxShadow: [
                BoxShadow(color: primaryBlue.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${booking.departure ?? 'Départ'} → ${booking.destination ?? 'Destination'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(booking.status),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: secondaryBlue, size: 15),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_dateTimeLabel(booking), style: const TextStyle(color: textGrey, fontSize: 11))),
                    Text('${booking.seatsReserved} ${booking.seatsReserved == 1 ? 'place' : 'places'}', style: const TextStyle(color: primaryBlue, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text('Trajet : ${_tripStatusLabel(booking.tripStatus)}', style: const TextStyle(color: textGrey, fontSize: 10.5))),
                    Text('${_money(_total(booking))} TND', style: const TextStyle(color: green, fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _statusBadge(String status) {
    final cancelled = status == 'cancelled';
    final color = cancelled || status == 'rejected'
      ? const Color(0xFFB63A3A)
      : status == 'pending'
        ? secondaryBlue
        : green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
      child: Text(_bookingStatusLabel(status), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  bool _matchesFilter(Booking booking) {
    final cancelled = booking.status == 'cancelled' ||
      booking.status == 'rejected' ||
      booking.tripStatus == 'cancelled';
    if (_filter == _BookingFilter.cancelled) return cancelled;
    if (cancelled) return false;
    final date = _departure(booking);
    if (_filter == _BookingFilter.past) return date != null && date.isBefore(DateTime.now());
    return date == null || !date.isBefore(DateTime.now());
  }

  DateTime? _departure(Booking booking) {
    final date = booking.departureDate;
    final time = booking.departureTime;
    if (date == null || time == null) return null;
    final dateParts = date.split('-');
    final timeParts = time.split(':');
    if (dateParts.length != 3 || timeParts.length < 2) return null;
    final parts = [
      int.tryParse(dateParts[0]),
      int.tryParse(dateParts[1]),
      int.tryParse(dateParts[2]),
      int.tryParse(timeParts[0]),
      int.tryParse(timeParts[1]),
    ];
    if (parts.contains(null)) return null;
    return DateTime(parts[0]!, parts[1]!, parts[2]!, parts[3]!, parts[4]!);
  }

  Future<void> _openDetails(Booking booking) async {
    final bookingId = booking.id;
    final passengerId = widget.user.id;
    if (bookingId == null || passengerId == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PassengerBookingDetailsScreen(
          bookingId: bookingId,
          user: widget.user,
        ),
      ),
    );
    if (!mounted) return;
    if (changed == true) await _loadBookings();
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    String? action,
    VoidCallback? onAction,
  }) => Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: secondaryBlue, size: 42),
              const SizedBox(height: 13),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: primaryBlue, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: textGrey, fontSize: 12, height: 1.4)),
              if (action != null) TextButton(onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
      );

  String get _emptyTitle => switch (_filter) {
        _BookingFilter.upcoming => 'Aucune réservation à venir',
        _BookingFilter.past => 'Aucune réservation passée',
        _BookingFilter.cancelled => 'Aucune réservation annulée',
      };

  String _filterLabel(_BookingFilter filter) => switch (filter) {
        _BookingFilter.upcoming => 'À venir',
        _BookingFilter.past => 'Passées',
        _BookingFilter.cancelled => 'Annulées',
      };

  String _bookingStatusLabel(String status) => switch (status) {
        'pending' => 'En attente',
      'accepted' => 'Acceptée',
      'rejected' => 'Refusée',
        'cancelled' => 'Annulée',
        _ => status,
      };

  String _tripStatusLabel(String? status) => switch (status) {
        'available' => 'Disponible',
        'cancelled' => 'Annulé',
        'completed' => 'Terminé',
        null => 'Indisponible',
        _ => status,
      };

  String _dateTimeLabel(Booking booking) {
    final rawDate = booking.departureDate;
    final time = booking.departureTime;
    final date = rawDate == null ? null : DateTime.tryParse(rawDate);
    final dateText = date == null ? rawDate ?? 'Date inconnue' : DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    return time == null ? dateText : '$dateText • $time';
  }

  double _total(Booking booking) => (booking.pricePerSeat ?? 0) * booking.seatsReserved;

  String _money(double amount) => amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
}
