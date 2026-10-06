import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/booking.dart';
import '../../../models/trip.dart';
import '../../../models/trip_details.dart';
import '../../../models/user.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/trip_repository.dart';

class AdminTripsScreen extends StatefulWidget {
  final User admin;
  const AdminTripsScreen({super.key, required this.admin});

  @override
  State<AdminTripsScreen> createState() => _AdminTripsScreenState();
}

class _AdminTripsScreenState extends State<AdminTripsScreen> {
  static const _navy = Color(0xFF123D68),
      _blue = Color(0xFF1E5AA8),
      _green = Color(0xFF18A974),
      _red = Color(0xFFC94A4A),
      _bg = Color(0xFFF6F9FC),
      _muted = Color(0xFF71879A);
  final _trips = TripRepository();
  final _search = TextEditingController();
  List<Trip> _all = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await _trips.getAllTripsForAdmin();
      if (!mounted) return;
      setState(() {
        _all = trips;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les trajets.';
      });
    }
  }

  bool _upcoming(Trip t) =>
      t.status == 'available' && _dateTime(t).isAfter(DateTime.now());
  DateTime _dateTime(Trip t) =>
      DateTime.tryParse('${t.departureDate} ${t.departureTime}') ??
      DateTime(1900);
  List<Trip> get _visible => _all.where((t) {
    final stateMatch = switch (_filter) {
      'upcoming' => _upcoming(t),
      'completed' => t.status == 'completed',
      'cancelled' => t.status == 'cancelled',
      _ => true,
    };
    final text = '${t.departure} ${t.destination} ${t.driverName}'
        .toLowerCase();
    return stateMatch && (_query.isEmpty || text.contains(_query));
  }).toList();

  @override
  Widget build(BuildContext context) {
    final upcoming = _all.where(_upcoming).length;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gestion des trajets',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Suivez les trajets publiés sur la plateforme',
                                style: TextStyle(color: _muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _load,
                          tooltip: 'Actualiser',
                          icon: const Icon(Icons.refresh_rounded, color: _blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        _stat('Total', _all.length, Icons.route_rounded, _blue),
                        _stat(
                          'À venir',
                          upcoming,
                          Icons.schedule_rounded,
                          _green,
                        ),
                        _stat(
                          'Terminés',
                          _all.where((t) => t.status == 'completed').length,
                          Icons.check_circle_outline_rounded,
                          const Color(0xFF7A63A8),
                        ),
                        _stat(
                          'Annulés',
                          _all.where((t) => t.status == 'cancelled').length,
                          Icons.cancel_outlined,
                          _red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'Départ, destination ou conducteur',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _muted,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFE6EDF3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFE6EDF3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final item in const [
                            ('all', 'Tous'),
                            ('upcoming', 'À venir'),
                            ('completed', 'Terminés'),
                            ('cancelled', 'Annulés'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(item.$2),
                                selected: _filter == item.$1,
                                onSelected: (_) =>
                                    setState(() => _filter = item.$1),
                                selectedColor: const Color(0xFFEAF3FC),
                                labelStyle: TextStyle(
                                  color: _filter == item.$1 ? _blue : _muted,
                                  fontWeight: FontWeight.w700,
                                ),
                                side: BorderSide(
                                  color: _filter == item.$1
                                      ? const Color(0xFFBCD4ED)
                                      : const Color(0xFFE6EDF3),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(color: _blue),
                        ),
                      )
                    else if (_error != null)
                      _message(
                        Icons.cloud_off_outlined,
                        _error!,
                        'Réessayer',
                        _load,
                      )
                    else if (_visible.isEmpty)
                      _message(
                        Icons.route_outlined,
                        _all.isEmpty
                            ? 'Aucun trajet enregistré.'
                            : 'Aucun trajet ne correspond à votre recherche.',
                        'Actualiser',
                        _load,
                      )
                    else
                      ..._visible.map(_tripCard),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int count, IconData icon, Color color) =>
      Container(
        width: (MediaQuery.sizeOf(context).width - 45) / 2,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE6EDF3)),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: .035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tripCard(Trip t) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6EDF3)),
      boxShadow: [
        BoxShadow(
          color: _navy.withValues(alpha: .035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdminTripDetailsScreen(trip: t, canCancel: _upcoming(t)),
          ),
        );
        await _load();
      },
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t.departure}  →  ${t.destination}',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _badge(_status(t, _upcoming(t))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _meta(Icons.calendar_month_outlined, _dateLabel(t.departureDate)),
              _meta(Icons.access_time_rounded, t.departureTime),
              _meta(
                Icons.person_outline_rounded,
                t.driverName.isEmpty ? 'Conducteur' : t.driverName,
              ),
              _meta(
                Icons.event_seat_outlined,
                '${t.availableSeats}/${t.totalSeats} places',
              ),
              _meta(Icons.payments_outlined, '${_money(t.price)} TND'),
            ],
          ),
          if (t.meetingPoint.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            _meta(Icons.place_outlined, t.meetingPoint),
          ],
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Voir les détails  ›',
              style: TextStyle(
                color: _blue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: _muted),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(
          color: _muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
  Widget _badge(String label) {
    final color = label == 'Annulé'
        ? _red
        : label == 'Terminé'
        ? const Color(0xFF7A63A8)
        : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String action,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 58),
    child: Column(
      children: [
        Icon(icon, size: 42, color: const Color(0xFF9AAEBC)),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
  String _status(Trip t, bool upcoming) => t.status == 'cancelled'
      ? 'Annulé'
      : t.status == 'completed'
      ? 'Terminé'
      : upcoming
      ? 'À venir'
      : 'Disponible';
}

class AdminTripDetailsScreen extends StatefulWidget {
  final Trip trip;
  final bool canCancel;
  const AdminTripDetailsScreen({
    super.key,
    required this.trip,
    required this.canCancel,
  });
  @override
  State<AdminTripDetailsScreen> createState() => _AdminTripDetailsScreenState();
}

class _AdminTripDetailsScreenState extends State<AdminTripDetailsScreen> {
  static const _navy = Color(0xFF123D68),
      _blue = Color(0xFF1E5AA8),
      _muted = Color(0xFF71879A),
      _bg = Color(0xFFF6F9FC),
      _red = Color(0xFFC94A4A);
  final _repo = TripRepository();
  TripDetails? _details;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await _repo.getTripDetails(widget.trip.id!);
      if (mounted) {
        setState(() {
          _details = v;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les détails.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    final d = _details;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _navy,
        title: const Text(
          'Détails du trajet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${t.departure} → ${t.destination}',
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _pill(t.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _line(
                        Icons.calendar_month_outlined,
                        _dateLabel(t.departureDate),
                      ),
                      _line(Icons.access_time_rounded, t.departureTime),
                      _line(
                        Icons.payments_outlined,
                        '${_money(t.price)} TND par passager',
                      ),
                      _line(
                        Icons.event_seat_outlined,
                        '${t.availableSeats} disponibles sur ${t.totalSeats} places',
                      ),
                      if (t.meetingPoint.trim().isNotEmpty)
                        _line(Icons.place_outlined, t.meetingPoint),
                      if (t.description?.trim().isNotEmpty == true)
                        _line(Icons.notes_rounded, t.description!.trim()),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conducteur',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _line(Icons.person_outline_rounded, t.driverName),
                      if (d != null) ...[
                        _line(
                          Icons.verified_user_outlined,
                          d.driverIsVerified ? 'Compte vérifié' : 'Non vérifié',
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Véhicule',
                          style: TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _line(
                          Icons.directions_car_outlined,
                          '${d.vehicleBrand} ${d.vehicleModel}${d.vehicleColor?.isNotEmpty == true ? ' • ${d.vehicleColor}' : ''}',
                        ),
                        _line(
                          Icons.event_seat_outlined,
                          '${d.vehicleSeats} places véhicule',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                FutureBuilder<List<Booking>>(
                  future: BookingRepository().getBookingsForAdminTrip(t.id!),
                  builder: (context, s) => _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Réservations',
                                style: TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              '${s.data?.length ?? 0}',
                              style: const TextStyle(
                                color: _blue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Suivi des réservations et places réservées',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminTripBookingsScreen(
                                  tripId: t.id!,
                                  route: '${t.departure} → ${t.destination}',
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.groups_2_outlined),
                            label: const Text('Consulter les réservations'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.canCancel) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 49,
                    child: OutlinedButton.icon(
                      onPressed: _confirmCancel,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Annuler ce trajet'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: Color(0xFFF0CACA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler ce trajet ?'),
        content: const Text(
          'Le trajet sera marqué comme annulé et ne sera pas supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.cancelTripAsAdmin(widget.trip.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Trajet annulé.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    }
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6EDF3)),
      boxShadow: [
        BoxShadow(
          color: _navy.withValues(alpha: .035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _blue, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _pill(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      value,
      style: const TextStyle(
        color: _blue,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class AdminTripBookingsScreen extends StatefulWidget {
  final int tripId;
  final String route;
  const AdminTripBookingsScreen({
    super.key,
    required this.tripId,
    required this.route,
  });
  @override
  State<AdminTripBookingsScreen> createState() =>
      _AdminTripBookingsScreenState();
}

class _AdminTripBookingsScreenState extends State<AdminTripBookingsScreen> {
  final _repo = BookingRepository();
  late Future<List<Booking>> _future;
  @override
  void initState() {
    super.initState();
    _future = _repo.getBookingsForAdminTrip(widget.tripId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F9FC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF6F9FC),
      foregroundColor: const Color(0xFF123D68),
      elevation: 0,
      title: const Text(
        'Réservations',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: FutureBuilder<List<Booking>>(
      future: _future,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) {
          return const Center(
            child: Text('Impossible de charger les réservations.'),
          );
        }
        final bookings = s.data ?? [];
        if (bookings.isEmpty) {
          return const Center(
            child: Text(
              'Aucune réservation pour ce trajet.',
              style: TextStyle(color: Color(0xFF71879A)),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(
            () => _future = _repo.getBookingsForAdminTrip(widget.tripId),
          ),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                widget.route,
                style: const TextStyle(
                  color: Color(0xFF71879A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 13),
              ...bookings.map(
                (b) => Container(
                  margin: const EdgeInsets.only(bottom: 11),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0xFFE6EDF3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.passengerName ?? 'Passager',
                              style: const TextStyle(
                                color: Color(0xFF123D68),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            b.status,
                            style: const TextStyle(
                              color: Color(0xFF1E5AA8),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (b.passengerEmail?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            b.passengerEmail!,
                            style: const TextStyle(
                              color: Color(0xFF71879A),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_seat_outlined,
                            size: 16,
                            color: Color(0xFF71879A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${b.seatsReserved} place(s)',
                            style: const TextStyle(
                              color: Color(0xFF71879A),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Color(0xFF71879A),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _dateLabel(b.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF71879A),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

String _dateLabel(String value) {
  final d = DateTime.tryParse(value);
  return d == null ? value : DateFormat('dd MMM yyyy', 'fr_FR').format(d);
}

String _money(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
