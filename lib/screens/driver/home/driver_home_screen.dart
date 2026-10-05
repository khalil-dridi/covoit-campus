import 'package:flutter/material.dart';

import '../../../models/trip.dart';
import '../../../models/user.dart';
import '../../../models/vehicle.dart';
import '../../../repositories/driver_home_repository.dart';
import '../../../widgets/driver/driver_header.dart';

class DriverHomeScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onPublishTap;
  final VoidCallback? onTripsTap;
  final VoidCallback? onProfileTap;

  const DriverHomeScreen({
    super.key,
    required this.user,
    this.onPublishTap,
    this.onTripsTap,
    this.onProfileTap,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);
  static const Color lightGreen = Color(0xFFE8F8F1);
  static const Color lightYellow = Color(0xFFFFF5DE);
  static const Color lightPink = Color(0xFFFFEFF0);

  final DriverHomeRepository _repository = DriverHomeRepository();
  final GlobalKey _requestsKey = GlobalKey();
  DriverHomeData? _data;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = widget.user.id;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'Impossible d’identifier votre compte.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await _repository.getHomeData(userId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Impossible de charger votre activité.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: green,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                const SizedBox(height: 17),
                _buildPublishCta(),
                const SizedBox(height: 23),
                _buildSectionTitle('Votre activité'),
                const SizedBox(height: 11),
                if (_isLoading)
                  const _LoadingPanel()
                else if (_loadError != null)
                  _buildErrorPanel()
                else
                  _buildActivitySummary(data!),
                const SizedBox(height: 18),
                _buildQuickAccess(),
                const SizedBox(height: 22),
                _buildSectionTitle(
                  'Votre prochain trajet',
                  action: 'Voir tout',
                  onTap: widget.onTripsTap,
                ),
                const SizedBox(height: 11),
                if (_isLoading)
                  const _LoadingPanel()
                else if (_loadError != null)
                  const SizedBox.shrink()
                else if (data!.nextTrip == null)
                  _buildNoUpcomingTrip()
                else
                  _buildTripCard(
                    data.nextTrip!,
                    pendingBookings: data.nextTripPendingBookings ?? 0,
                  ),
                const SizedBox(height: 22),
                _buildRequestsSection(data),
                const SizedBox(height: 22),
                _buildStatistics(data),
                const SizedBox(height: 22),
                _buildRecentActivity(data),
                const SizedBox(height: 22),
                _buildVehicleCard(data?.vehicle),
                const SizedBox(height: 18),
                _buildCommunityCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublishCta() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: widget.onPublishTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF238F70), green],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: green.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.add_road_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Publier un trajet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Proposez vos places à d’autres étudiants.',
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySummary(DriverHomeData data) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.route_rounded,
            label: 'Trajets actifs',
            value: '${data.activeTrips}',
            accent: secondaryBlue,
            surface: lightBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            icon: Icons.event_seat_rounded,
            label: 'Places réservées',
            value: '${data.reservedSeats}',
            accent: green,
            surface: lightGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            icon: Icons.mark_email_unread_outlined,
            label: 'Demandes en attente',
            value: '${data.pendingRequests}',
            accent: const Color(0xFFB98522),
            surface: lightYellow,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess() {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            icon: Icons.add_road_rounded,
            label: 'Publier',
            color: green,
            surface: lightGreen,
            onTap: widget.onPublishTap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickAction(
            icon: Icons.directions_car_outlined,
            label: 'Mes trajets',
            color: secondaryBlue,
            surface: lightBlue,
            onTap: widget.onTripsTap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickAction(
            icon: Icons.inbox_outlined,
            label: 'Demandes',
            color: const Color(0xFFB98522),
            surface: lightYellow,
            onTap: _openRequests,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickAction(
            icon: Icons.directions_car_filled_outlined,
            label: 'Véhicule',
            color: const Color(0xFFD85B72),
            surface: lightPink,
            onTap: widget.onProfileTap,
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required Color surface,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required Color surface,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 111),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 21),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 9,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUpcomingTrip() {
    return _emptyPanel(
      icon: Icons.route_outlined,
      title: 'Aucun trajet programmé',
      message:
          'Publiez votre prochain trajet pour commencer à proposer des places.',
      actionLabel: 'Publier un trajet',
      onAction: widget.onPublishTap,
    );
  }

  Widget _buildTripCard(Trip trip, {required int pendingBookings}) {
    final date = DateTime.tryParse(trip.departureDate);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        children: [
          Row(
            children: [
              _dateBlock(date),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.departure,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(width: 1, height: 13, color: green),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            trip.destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trip.departureTime,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip.price.toStringAsFixed(2)} DT',
                    style: const TextStyle(
                      color: green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE6ECE9)),
          ),
          Row(
            children: [
              const Icon(Icons.event_seat_outlined, color: secondaryBlue, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${trip.availableSeats} places disponibles',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: pendingBookings > 0 ? lightYellow : lightGreen,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$pendingBookings demande${pendingBookings == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: pendingBookings > 0 ? const Color(0xFF9B711D) : green,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right_rounded, color: textGrey, size: 19),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateBlock(DateTime? date) {
    const monthLabels = [
      'JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUI',
      'JUIL', 'AOÛ', 'SEP', 'OCT', 'NOV', 'DÉC',
    ];
    return Container(
      width: 49,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            date == null ? '—' : '${date.day}',
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            date == null ? '' : monthLabels[date.month - 1],
            style: const TextStyle(
              color: secondaryBlue,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection(DriverHomeData? data) {
    return Container(
      key: _requestsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Demandes de réservation',
            action: data != null && data.pendingRequests > 0 ? 'Voir tout' : null,
            onTap: widget.onTripsTap,
          ),
          const SizedBox(height: 11),
          if (_isLoading)
            const _LoadingPanel()
          else if (_loadError != null)
            const SizedBox.shrink()
          else if (data == null || data.pendingRequests == 0)
            _emptyPanel(
              icon: Icons.inbox_outlined,
              title: 'Aucune demande en attente',
              message: 'Les demandes de réservation apparaîtront ici.',
            )
          else
            _buildRequestsList(data.requests, data.pendingRequests),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<DriverBookingRequest> requests, int total) {
    return Container(
      decoration: _cardDecoration(radius: 19),
      child: Column(
        children: [
          for (var index = 0; index < requests.length; index++) ...[
            _bookingRequestRow(requests[index]),
            if (index < requests.length - 1)
              const Divider(height: 1, indent: 63, color: Color(0xFFE6ECE9)),
          ],
          if (total > requests.length)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '+ ${total - requests.length} autres demandes',
                  style: const TextStyle(
                    color: secondaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bookingRequestRow(DriverBookingRequest request) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _passengerAvatar(request.passengerImage),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.passengerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${request.departure} → ${request.destination}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textGrey, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '${request.seatsRequested} pl.',
            style: const TextStyle(
              color: secondaryBlue,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right_rounded, color: textGrey, size: 18),
        ],
      ),
    );
  }

  Widget _passengerAvatar(String? image) {
    final path = image?.trim();
    final uri = path == null ? null : Uri.tryParse(path);
    final remote = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final asset = path?.startsWith('assets/') == true;
    Widget content;
    if (path == null || path.isEmpty) {
      content = _avatarFallback();
    } else if (remote) {
      content = Image.network(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => _avatarFallback());
    } else if (asset) {
      content = Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => _avatarFallback());
    } else {
      content = _avatarFallback();
    }
    return ClipOval(child: SizedBox(width: 38, height: 38, child: content));
  }

  Widget _avatarFallback() => Container(
        color: lightBlue,
        alignment: Alignment.center,
        child: const Icon(Icons.person_rounded, color: secondaryBlue, size: 21),
      );

  Widget _buildStatistics(DriverHomeData? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Vos statistiques'),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.flag_outlined,
                label: 'Trajets réalisés',
                value: data?.stats.completedTrips.toString() ?? '—',
                color: secondaryBlue,
                surface: lightBlue,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _statCard(
                icon: Icons.event_seat_outlined,
                label: 'Places partagées',
                value: data?.reservedSeats.toString() ?? '—',
                color: green,
                surface: lightGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.star_rounded,
                label: 'Note moyenne',
                value: data?.stats.rating?.toStringAsFixed(1) ?? '—',
                color: const Color(0xFFE2A631),
                surface: lightYellow,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _statCard(
                icon: Icons.eco_rounded,
                label: 'CO₂ économisé',
                value: '—',
                color: green,
                surface: lightGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color surface,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 95),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 9.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(DriverHomeData? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Activité récente'),
        const SizedBox(height: 11),
        if (_isLoading)
          const _LoadingPanel()
        else if (_loadError != null)
          const SizedBox.shrink()
        else if (data == null || data.recentActivity.isEmpty)
          _emptyPanel(
            icon: Icons.history_rounded,
            title: 'Aucune activité récente',
            message: 'Votre activité apparaîtra ici.',
          )
        else
          Container(
            decoration: _cardDecoration(radius: 18),
            child: Column(
              children: [
                for (var index = 0; index < data.recentActivity.length; index++) ...[
                  _activityRow(data.recentActivity[index]),
                  if (index < data.recentActivity.length - 1)
                    const Divider(height: 1, indent: 59, color: Color(0xFFE6ECE9)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _activityRow(DriverActivityItem activity) {
    final isRequest = activity.title.contains('demande');
    final date = DateTime.tryParse(activity.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isRequest ? lightYellow : lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRequest ? Icons.event_seat_outlined : Icons.add_road_rounded,
              color: isRequest ? const Color(0xFFB98522) : secondaryBlue,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: textGrey, fontSize: 10),
                ),
              ],
            ),
          ),
          if (date != null)
            Text(
              '${date.day}/${date.month}',
              style: TextStyle(
                color: textGrey.withValues(alpha: 0.65),
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle? vehicle) {
    final vehicleDescription = _isLoading
      ? 'Chargement des informations…'
      : _loadError != null
        ? 'Informations indisponibles'
        : vehicle == null
          ? 'Aucun véhicule configuré'
          : '${vehicle.brand} ${vehicle.model} · ${vehicle.seats} places';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: widget.onProfileTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(radius: 19),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: secondaryBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre véhicule',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicleDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textGrey, fontSize: 10.5),
                    ),
                    if (!_isLoading && _loadError == null && vehicle == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Ajouter dans votre profil',
                          style: TextStyle(
                            color: secondaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: green.withValues(alpha: 0.13)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, color: green, size: 22),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merci de contribuer à un campus plus vert 🌱',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Chaque place partagée peut réduire le nombre de trajets '
                    'individuels.',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _emptyPanel({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      decoration: _cardDecoration(radius: 19),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: secondaryBlue, size: 23),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey.withValues(alpha: 0.82),
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_road_rounded, size: 17),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorPanel() => _emptyPanel(
        icon: Icons.cloud_off_outlined,
        title: 'Données indisponibles',
        message: _loadError ?? 'Réessayez de charger votre activité.',
        actionLabel: 'Réessayer',
        onAction: _loadData,
      );

  Widget _buildSectionTitle(
    String title, {
    String? action,
    VoidCallback? onTap,
  }) => _SectionHeading(title: title, action: action, onTap: onTap);

  BoxDecoration _cardDecoration({required double radius}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE1ECE8)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      );

  void _openRequests() {
    final targetContext = _requestsKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showInfoDialog({
    required String title,
    required String message,
    required IconData icon,
  }) {
    showDialog<void>(
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
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Compris',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _SectionHeading({
    required this.title,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DriverHomeScreenColors.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: DriverHomeScreenColors.secondaryBlue,
                padding: const EdgeInsets.only(left: 7),
                minimumSize: const Size(56, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '$action  ›',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      );
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE1ECE8)),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF20B978)),
          ),
        ),
      );
}

abstract final class DriverHomeScreenColors {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
}
