import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/trip_details.dart';
import '../../../models/user.dart';
import '../../../repositories/trip_repository.dart';

class TripDetailsScreen extends StatefulWidget {
  final int tripId;
  final User user;

  const TripDetailsScreen({
    super.key,
    required this.tripId,
    required this.user,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);
  static const Color lightGreen = Color(0xFFE8F8F1);

  final TripRepository _tripRepository = TripRepository();
  TripDetails? _details;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final details = await _tripRepository.getTripDetails(widget.tripId);
      if (!mounted) return;
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _isLoading
                  ? _loadingState()
                  : _loadFailed
                      ? _errorState()
                      : _details == null
                          ? _notFoundState()
                          : _detailsContent(_details!),
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
            const Expanded(
              child: Text(
                'Détails du trajet',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _detailsContent(TripDetails details) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(19, 10, 19, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tripSummary(details),
            const SizedBox(height: 22),
            _sectionTitle('Votre conducteur'),
            const SizedBox(height: 9),
            _driverCard(details),
            const SizedBox(height: 20),
            _sectionTitle('Véhicule'),
            const SizedBox(height: 9),
            _vehicleCard(details),
            const SizedBox(height: 20),
            _sectionTitle('Point de rendez-vous'),
            const SizedBox(height: 9),
            _informationCard(
              icon: Icons.location_on_rounded,
              iconColor: green,
              content: details.meetingPoint.trim().isEmpty
                  ? 'Point de rendez-vous non renseigné'
                  : details.meetingPoint.trim(),
            ),
            if (details.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 20),
              _sectionTitle('Informations supplémentaires'),
              const SizedBox(height: 9),
              _informationCard(
                icon: Icons.notes_rounded,
                iconColor: secondaryBlue,
                content: details.description!.trim(),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 49,
              child: OutlinedButton.icon(
                onPressed: () => _showInformationDialog(
                  title: 'Contacter le conducteur',
                  message: 'La messagerie avec le conducteur sera disponible ici.',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Contacter le conducteur'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryBlue,
                  side: const BorderSide(color: Color(0xFFDCE7E3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: details.status == 'available' && details.availableSeats > 0
                    ? () => _startBooking(details)
                    : null,
                icon: const Icon(Icons.event_seat_rounded, size: 19),
                label: const Text('Réserver une place'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB8C8C1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () => _showInformationDialog(
                  title: 'Partager le trajet',
                  message: 'Le partage du trajet sera disponible ici.',
                  icon: Icons.share_outlined,
                ),
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Partager le trajet'),
                style: TextButton.styleFrom(
                  foregroundColor: textGrey,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _tripSummary(TripDetails details) {
    final parsedDate = DateTime.tryParse(details.departureDate);
    final dateLabel = parsedDate == null
        ? details.departureDate
        : DateFormat('dd MMM yyyy', 'fr_FR').format(parsedDate).toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    color: secondaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusBadge(details),
              const SizedBox(width: 9),
              Text(
                details.departureTime,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          _routeStop(details.departure, start: true),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(width: 2, height: 23, color: const Color(0xFFDCE7E3)),
          ),
          _routeStop(details.destination, start: false),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 17),
            child: Divider(height: 1, color: Color(0xFFE8EFEC)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  'Prix par passager',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_formatNumber(details.price)} TND',
                style: const TextStyle(
                  color: secondaryBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.event_seat_outlined, color: green, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${details.availableSeats} ${details.availableSeats == 1 ? 'place disponible' : 'places disponibles'}',
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeStop(String city, {required bool start}) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: start ? lightGreen : lightBlue,
              shape: BoxShape.circle,
              border: Border.all(
                color: start ? green : secondaryBlue,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: start ? green : secondaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              city,
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
      );

  Widget _statusBadge(TripDetails details) {
    final status = details.status;
    final isCancelled = status == 'cancelled';
    final isFull = details.availableSeats <= 0 && status == 'available';
    final isPast = _hasDeparted(details) && status == 'available';
    final label = isCancelled
        ? 'Annulé'
        : isPast
            ? 'Terminé'
            : isFull
                ? 'Complet'
                : status == 'available'
                    ? 'Disponible'
                    : status;
    final color = isCancelled ? const Color(0xFFB63A3A) : green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }

  bool _hasDeparted(TripDetails details) {
    final date = DateTime.tryParse(details.departureDate);
    final parts = details.departureTime.split(':');
    if (date == null || parts.length < 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;
    return DateTime(date.year, date.month, date.day, hour, minute)
        .isBefore(DateTime.now());
  }

  Widget _driverCard(TripDetails details) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            _profileAvatar(details.driverProfileImage),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.driverName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (details.driverIsVerified)
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: green, size: 15),
                        SizedBox(width: 4),
                        Text(
                          'Conducteur vérifié',
                          style: TextStyle(
                            color: green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  if (details.driverIsVerified) const SizedBox(height: 5),
                  Row(
                    children: [
                      if (details.driverRating != null) ...[
                        const Icon(Icons.star_rounded, color: Color(0xFFE7AD34), size: 16),
                        const SizedBox(width: 3),
                        Text(
                          details.driverRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${details.reviewCount} ${details.reviewCount == 1 ? 'avis' : 'avis'}',
                          style: const TextStyle(color: textGrey, fontSize: 10),
                        ),
                      ] else
                        const Text(
                          'Pas encore noté',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _profileAvatar(String? image) {
    final source = image?.trim();
    final uri = source == null ? null : Uri.tryParse(source);
    final isNetwork = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final isAsset = source?.startsWith('assets/') == true;
    Widget content;
    if (source == null || source.isEmpty) {
      content = _avatarFallback();
    } else if (isNetwork) {
      content = Image.network(source, fit: BoxFit.cover, errorBuilder: (_, _, _) => _avatarFallback());
    } else if (isAsset) {
      content = Image.asset(source, fit: BoxFit.cover, errorBuilder: (_, _, _) => _avatarFallback());
    } else {
      content = _avatarFallback();
    }
    return ClipOval(child: SizedBox(width: 58, height: 58, child: content));
  }

  Widget _avatarFallback() => Container(
        color: lightBlue,
        alignment: Alignment.center,
        child: const Icon(Icons.person_rounded, color: secondaryBlue, size: 31),
      );

  Widget _vehicleCard(TripDetails details) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: lightBlue, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.directions_car_rounded, color: secondaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${details.vehicleBrand} ${details.vehicleModel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (details.vehicleColor?.trim().isNotEmpty == true)
                        details.vehicleColor!.trim(),
                      '${details.vehicleSeats} places',
                    ].join(' • '),
                    style: const TextStyle(color: textGrey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _informationCard({
    required IconData icon,
    required Color iconColor,
    required String content,
  }) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                content,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          color: primaryBlue,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EBE7)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.045),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _loadingState() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: green),
            SizedBox(height: 14),
            Text(
              'Chargement du trajet…',
              style: TextStyle(color: textGrey, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  Widget _errorState() => _messageState(
        icon: Icons.cloud_off_rounded,
        title: 'Impossible de charger le trajet',
        message: 'Ce trajet n’est peut-être plus disponible.',
        retry: true,
      );

  Widget _notFoundState() => _messageState(
        icon: Icons.route_outlined,
        title: 'Trajet introuvable',
        message: 'Ce trajet n’existe plus ou a été supprimé.',
      );

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    bool retry = false,
  }) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: secondaryBlue, size: 42),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: primaryBlue, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textGrey, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (retry)
                TextButton.icon(
                  onPressed: _loadTrip,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      );

  Future<void> _showInformationDialog({
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
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(color: lightGreen, shape: BoxShape.circle),
                child: Icon(icon, color: green, size: 25),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: primaryBlue, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textGrey, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
  }

  Future<void> _startBooking(TripDetails details) async {
    final passenger = widget.user;
    if (passenger.id == null || passenger.role != 'passenger' || !passenger.isActive) {
      await _showBookingMessage(
        title: 'Connexion requise',
        message: 'Connectez-vous avec un compte passager actif pour réserver.',
        success: false,
      );
      if (!mounted) return;
      return;
    }
    if (passenger.id == details.driverId) {
      await _showBookingMessage(
        title: 'Réservation impossible',
        message: 'Vous ne pouvez pas réserver votre propre trajet.',
        success: false,
      );
      if (!mounted) return;
      return;
    }

    final result = await showDialog<_BookingDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var selectedSeats = 1;
        var saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final totalPrice = details.price * selectedSeats;
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 21, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.12),
                      blurRadius: 25,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirmer la réservation',
                      style: TextStyle(color: primaryBlue, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    _bookingSummaryLine(
                      Icons.route_rounded,
                      '${details.departure} → ${details.destination}',
                    ),
                    const SizedBox(height: 8),
                    _bookingSummaryLine(
                      Icons.calendar_today_rounded,
                      '${_formatBookingDate(details.departureDate)} • ${details.departureTime}',
                    ),
                    const SizedBox(height: 8),
                    _bookingSummaryLine(
                      Icons.payments_outlined,
                      '${_formatNumber(details.price)} TND par passager',
                    ),
                    const SizedBox(height: 8),
                    _bookingSummaryLine(
                      Icons.event_seat_outlined,
                      '${details.availableSeats} ${details.availableSeats == 1 ? 'place disponible' : 'places disponibles'}',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Places à réserver',
                            style: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Retirer une place',
                          onPressed: selectedSeats > 1 && !saving
                              ? () => setDialogState(() => selectedSeats--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          color: secondaryBlue,
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '$selectedSeats',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: primaryBlue, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ajouter une place',
                          onPressed: selectedSeats < details.availableSeats && !saving
                              ? () => setDialogState(() => selectedSeats++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: green,
                        ),
                      ],
                    ),
                    const Divider(height: 15, color: Color(0xFFE8EFEC)),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${_formatNumber(totalPrice)} TND',
                          style: const TextStyle(color: green, fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryBlue,
                              side: const BorderSide(color: Color(0xFFDCE7E3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            ),
                            child: const Text('Retour'),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saving || selectedSeats < 1 || selectedSeats > details.availableSeats
                                ? null
                                : () async {
                                    setDialogState(() => saving = true);
                                    try {
                                      final passengerId = passenger.id;
                                      if (passengerId == null) {
                                        throw StateError('Session passager invalide.');
                                      }
                                      await _tripRepository.createBooking(
                                        tripId: details.id,
                                        passengerId: passengerId,
                                        seatsReserved: selectedSeats,
                                      );
                                      if (!mounted || !dialogContext.mounted) return;
                                      Navigator.of(dialogContext).pop(
                                        _BookingDialogResult.confirmed,
                                      );
                                    } catch (error) {
                                      if (!mounted || !dialogContext.mounted) return;
                                      Navigator.of(dialogContext).pop(
                                        _BookingDialogResult.failed(_bookingErrorMessage(error)),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Confirmer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    if (result.error != null) {
      await _showBookingMessage(
        title: 'Réservation impossible',
        message: result.error!,
        success: false,
      );
      if (!mounted) return;
      return;
    }

    await _loadTrip();
    if (!mounted) return;
    await _showBookingMessage(
      title: 'Réservation confirmée',
      message: 'Votre réservation a bien été enregistrée.',
      success: true,
    );
    if (!mounted) return;
  }

  Widget _bookingSummaryLine(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: secondaryBlue, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: primaryBlue, fontSize: 11.5, height: 1.35),
            ),
          ),
        ],
      );

  Future<void> _showBookingMessage({
    required String title,
    required String message,
    required bool success,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: success ? lightGreen : const Color(0xFFFFF0EF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                  color: success ? green : const Color(0xFFB93E36),
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: primaryBlue, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textGrey, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
  }

  String _bookingErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('already exists')) {
      return 'Vous avez déjà une réservation pour ce trajet.';
    }
    if (text.contains('Not enough seats')) {
      return 'Le nombre de places disponibles a changé. Actualisez le trajet puis réessayez.';
    }
    if (text.contains('own trip')) {
      return 'Vous ne pouvez pas réserver votre propre trajet.';
    }
    if (text.contains('not available') || text.contains('Trip not found')) {
      return 'Ce trajet n’est plus disponible.';
    }
    return 'La réservation n’a pas pu être enregistrée. Veuillez réessayer.';
  }

  String _formatBookingDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  String _formatNumber(double number) =>
      number == number.roundToDouble() ? number.toStringAsFixed(0) : number.toStringAsFixed(2);
}

class _BookingDialogResult {
  final String? error;

  const _BookingDialogResult._(this.error);

  static const confirmed = _BookingDialogResult._(null);

  factory _BookingDialogResult.failed(String error) =>
      _BookingDialogResult._(error);
}
