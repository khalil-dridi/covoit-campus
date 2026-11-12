import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/booking.dart';
import '../../../models/user.dart';
import '../../../repositories/booking_repository.dart';
import 'trip_details_screen.dart';

class PassengerHistoryScreen extends StatefulWidget {
  final User user;

  const PassengerHistoryScreen({super.key, required this.user});

  @override
  State<PassengerHistoryScreen> createState() => _PassengerHistoryScreenState();
}

class _PassengerHistoryScreenState extends State<PassengerHistoryScreen> {
  static const _blue = Color(0xFF123D68);
  static const _green = Color(0xFF20B978);
  final _repository = BookingRepository();
  List<Booking> _bookings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final passengerId = widget.user.id;
    if (passengerId == null) {
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
        _error = 'Impossible de charger votre historique.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4FFFB),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHistory,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: _blue),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Historique',
                        style: TextStyle(
                          color: _blue,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _message(
                  _error!,
                  'Réessayez dans quelques instants.',
                  action: TextButton(
                    onPressed: _loadHistory,
                    child: const Text('Réessayer'),
                  ),
                ),
              )
            else if (_bookings.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _HistoryMessage(
                  title: 'Aucune réservation',
                  message: 'Vos réservations apparaîtront ici, quel que soit leur statut.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                sliver: SliverList.separated(
                  itemCount: _bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _bookingCard(_bookings[index]),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _bookingCard(Booking booking) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE2EBE7)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: booking.tripId > 0
          ? () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TripDetailsScreen(
                  tripId: booking.tripId,
                  user: widget.user,
                ),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(15),
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
                    style: const TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _badge(_bookingStatus(booking.status)),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              '${_date(booking.departureDate)} • ${booking.departureTime ?? '--:--'}',
              style: const TextStyle(color: Color(0xFF547080), fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              'Conducteur : ${booking.driverName ?? 'Non disponible'}',
              style: const TextStyle(color: Color(0xFF547080), fontSize: 12),
            ),
            Text(
              'Réservation : ${_dateTime(booking.createdAt)}',
              style: const TextStyle(color: Color(0xFF547080), fontSize: 11),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Trajet : ${_tripStatus(booking.tripStatus)} · ${booking.seatsReserved} ${booking.seatsReserved == 1 ? 'place' : 'places'}',
                    style: const TextStyle(
                      color: Color(0xFF547080),
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '${((booking.pricePerSeat ?? 0) * booking.seatsReserved).toStringAsFixed(2)} TND',
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _message(String title, String message, {Widget? action}) =>
      _HistoryMessage(title: title, message: message, action: action);

  Widget _badge(String label) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE8F8F1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: _green,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
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

  String _tripStatus(String? status) => switch (status) {
    'completed' => 'Terminé',
    'cancelled' => 'Annulé',
    'in_progress' => 'En cours',
    'available' => 'À venir',
    null => 'Indisponible',
    _ => status,
  };

  String _date(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    return parsed == null
        ? value ?? 'Date inconnue'
        : DateFormat('dd/MM/yyyy').format(parsed);
  }

  String _dateTime(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? value
        : DateFormat('dd/MM/yyyy HH:mm').format(parsed);
  }
}

class _HistoryMessage extends StatelessWidget {
  final String title;
  final String message;
  final Widget? action;

  const _HistoryMessage({
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_rounded, size: 42, color: Color(0xFFB98522)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF547080)),
          ),
          ?action,
        ],
      ),
    ),
  );
}
