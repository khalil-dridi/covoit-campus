import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/trip.dart';
import '../../../models/user.dart';
import '../../../repositories/trip_favorite_repository.dart';
import 'trip_details_screen.dart';

class PassengerFavoritesScreen extends StatefulWidget {
  final User user;

  const PassengerFavoritesScreen({super.key, required this.user});

  @override
  State<PassengerFavoritesScreen> createState() =>
      _PassengerFavoritesScreenState();
}

class _PassengerFavoritesScreenState extends State<PassengerFavoritesScreen> {
  static const _blue = Color(0xFF123D68);
  static const _green = Color(0xFF20B978);
  final _repository = TripFavoriteRepository();
  List<Trip> _trips = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
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
      final trips = await _repository.getFavoriteTrips(passengerId);
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger vos trajets favoris.';
      });
    }
  }

  Future<void> _removeFavorite(Trip trip) async {
    final id = widget.user.id;
    final tripId = trip.id;
    if (id == null || tripId == null) return;
    setState(() => _trips = _trips.where((item) => item.id != tripId).toList());
    try {
      await _repository.toggleFavorite(passengerId: id, tripId: tripId);
    } catch (_) {
      if (!mounted) return;
      await _loadFavorites();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de retirer ce favori.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4FFFB),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadFavorites,
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
                        'Mes trajets favoris',
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
                child: _FavoriteMessage(
                  title: _error!,
                  message: 'Réessayez dans quelques instants.',
                  action: TextButton(
                    onPressed: _loadFavorites,
                    child: const Text('Réessayer'),
                  ),
                ),
              )
            else if (_trips.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _FavoriteMessage(
                  title: 'Aucun trajet favori',
                  message: 'Ajoutez un trajet depuis les résultats de recherche pour le retrouver ici.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                sliver: SliverList.separated(
                  itemCount: _trips.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _favoriteCard(_trips[index]),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _favoriteCard(Trip trip) {
    final active = _isReservable(trip);
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2EBE7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${trip.departure} → ${trip.destination}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Retirer des favoris',
                  onPressed: () => _removeFavorite(trip),
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFD85B72),
                  ),
                ),
              ],
            ),
            Text(
              '${_date(trip.departureDate)} • ${trip.departureTime}',
              style: const TextStyle(color: Color(0xFF547080), fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              'Conducteur : ${trip.driverName.isEmpty ? 'Non disponible' : trip.driverName}',
              style: const TextStyle(color: Color(0xFF547080), fontSize: 12),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    active
                        ? '${trip.availableSeats} places disponibles'
                        : _tripStatus(trip.status),
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF547080)
                          : const Color(0xFFB63A3A),
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '${trip.price.toStringAsFixed(2)} TND',
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: trip.id == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TripDetailsScreen(
                            tripId: trip.id!,
                            user: widget.user,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Voir détails'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isReservable(Trip trip) {
    final departure = DateTime.tryParse(
      '${trip.departureDate} ${trip.departureTime}',
    );
    return trip.status == 'available' &&
        trip.availableSeats > 0 &&
        departure != null &&
        departure.isAfter(DateTime.now());
  }

  String _tripStatus(String status) => switch (status) {
    'completed' => 'Trajet terminé · non réservable',
    'cancelled' => 'Trajet annulé · non réservable',
    'in_progress' => 'Trajet en cours · non réservable',
    _ => 'Trajet indisponible · non réservable',
  };

  String _date(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : DateFormat('dd/MM/yyyy').format(parsed);
  }
}

class _FavoriteMessage extends StatelessWidget {
  final String title;
  final String message;
  final Widget? action;

  const _FavoriteMessage({
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
          const Icon(
            Icons.favorite_border_rounded,
            size: 42,
            color: Color(0xFFD85B72),
          ),
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
