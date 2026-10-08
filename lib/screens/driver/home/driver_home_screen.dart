import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/ride_request.dart';
import '../../../models/trip.dart';
import '../../../models/user.dart';
import '../../../models/user_profile_context.dart';
import '../../../repositories/ride_request_repository.dart';
import '../../../repositories/trip_repository.dart';
import '../../../widgets/driver/driver_header.dart';
import '../../../widgets/profile/user_profile_preview.dart';
import '../../../widgets/profile/user_profile_avatar.dart';
import '../../driver/trips/driver_trip_details_screen.dart';
import '../../passenger/requests/ride_request_details_screen.dart';

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
  DriverHomeScreenState createState() => DriverHomeScreenState();
}

class DriverHomeScreenState extends State<DriverHomeScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightGreen = Color(0xFFE8F8F1);

  final RideRequestRepository _rideRequestRepository = RideRequestRepository();
  final TripRepository _tripRepository = TripRepository();

  List<_DriverFeedPost> _posts = const [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> refresh() => _loadFeed();

  Future<void> _loadFeed() async {
    final driverId = widget.user.id;
    if (driverId == null) {
      if (!mounted) return;
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
      final data = await Future.wait<Object>([
        _rideRequestRepository.getActiveRequestsForCommunityFeed(limit: 30),
        _tripRepository.getTripsForCommunityFeed(limit: 30),
      ]);
      if (!mounted) return;

      final requests = data[0] as List<RideRequest>;
      final trips = data[1] as List<Trip>;
      final posts = <_DriverFeedPost>[
        for (final request in requests)
          if (DateTime.tryParse(request.createdAt) case final date?)
            _DriverFeedPost.request(request, date),
        for (final trip in trips)
          if (DateTime.tryParse(trip.createdAt) case final date?)
            _DriverFeedPost.trip(trip, date),
      ]..sort((a, b) {
          return b.publishedAt.compareTo(a.publishedAt);
        });

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Impossible de charger le fil pour le moment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: green,
          onRefresh: _loadFeed,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(19, 12, 19, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DriverHeader(user: widget.user),
                const SizedBox(height: 18),
                _buildPublishCta(),
                const SizedBox(height: 26),
                const Text(
                  'Fil d’accueil',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'L’activité récente de la communauté Covoit Campus',
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.86),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                _buildFeed(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublishCta() => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: widget.onPublishTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCEBE4)),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.055),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.add_road_rounded,
                    color: green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publier un trajet',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Proposez vos places à d’autres étudiants.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFeed() {
    if (_isLoading) {
      return const Column(
        children: [
          _FeedLoadingCard(),
          SizedBox(height: 10),
          _FeedLoadingCard(),
        ],
      );
    }
    if (_loadError != null) {
      return _FeedStateCard(
        icon: Icons.cloud_off_outlined,
        title: 'Impossible de charger le fil',
        message: _loadError!,
        actionLabel: 'Réessayer',
        onAction: _loadFeed,
      );
    }
    if (_posts.isEmpty) {
      return const _FeedStateCard(
        icon: Icons.dynamic_feed_rounded,
        title: 'Votre fil est encore calme',
        message: 'Les nouvelles activités de la communauté apparaîtront ici.',
      );
    }

    return Column(
      children: [
        for (final post in _posts) ...[
          _buildFeedPost(post),
          if (post != _posts.last) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildFeedPost(_DriverFeedPost post) {
    final request = post.request;
    final trip = post.trip;
    final isRequest = request != null;
    final requestName = request?.passengerName?.trim();
    final driverName = trip?.driverName.trim();
    final author = (requestName == null || requestName.isEmpty ? null : requestName) ??
        (driverName == null || driverName.isEmpty ? null : driverName) ??
        (isRequest ? 'Passager' : 'Conducteur');
    final userId = request?.passengerId ?? trip!.driverId;
    final image = request?.passengerImage ?? trip?.driverProfileImage;
    final departure = request?.departure ?? trip!.departure;
    final destination = request?.destination ?? trip!.destination;
    final activity = isRequest ? 'Recherche un trajet' : 'Propose un trajet';
    final icon = isRequest ? Icons.search_rounded : Icons.add_road_rounded;
    final accent = isRequest ? secondaryBlue : green;
    final details = isRequest
        ? '${_formatDate(request.requestDate)}'
            '${request.requestTime == null ? '' : ' · ${request.requestTime}'}'
            ' · ${request.seatsRequested} ${request.seatsRequested == 1 ? 'place' : 'places'}'
        : '${_formatDate(trip!.departureDate)} · ${trip.departureTime} · '
            '${trip.availableSeats} ${trip.availableSeats == 1 ? 'place' : 'places'} · '
            '${NumberFormat('0.##').format(trip.price)} DT';
    final description = request?.description?.trim();
    final meetingPoint = trip?.meetingPoint.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: () => _openPost(post),
        borderRadius: BorderRadius.circular(19),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE2EBE7)),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.035),
                blurRadius: 13,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: UserProfileTarget(
                      userId: userId,
                      currentUser: widget.user,
                      enabled: userId != widget.user.id,
                      profileContext: UserProfileContext(
                        type: isRequest
                            ? UserProfileContextType.rideRequest
                            : UserProfileContextType.trip,
                        rideRequestId: request?.id,
                        tripId: trip?.id,
                        departure: departure,
                        destination: destination,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          UserProfileAvatar(
                            name: author,
                            image: image,
                            size: 42,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: primaryBlue,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(icon, color: accent, size: 13),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '$activity · ${_formatPublishedAt(post.publishedAt)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: textGrey,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$departure  →  $destination',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (meetingPoint?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      color: textGrey,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        meetingPoint!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textGrey, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.92),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openPost(post),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                  label: Text(isRequest ? 'Voir la demande' : 'Voir le trajet'),
                  style: TextButton.styleFrom(
                    foregroundColor: secondaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPost(_DriverFeedPost post) {
    final request = post.request;
    final trip = post.trip;
    if (request != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RideRequestDetailsScreen(
            request: request,
            currentUser: widget.user,
          ),
        ),
      );
    } else if (trip?.id != null && widget.user.id != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => DriverTripDetailsScreen(
            tripId: trip!.id!,
            user: widget.user,
          ),
        ),
      );
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : DateFormat('dd/MM').format(date);
  }

  String _formatPublishedAt(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return 'Aujourd’hui · ${DateFormat('HH:mm').format(local)}';
    return DateFormat('dd/MM · HH:mm').format(local);
  }
}

class _DriverFeedPost {
  final DateTime publishedAt;
  final RideRequest? request;
  final Trip? trip;

  const _DriverFeedPost._({
    required this.publishedAt,
    this.request,
    this.trip,
  });

  factory _DriverFeedPost.request(
    RideRequest request,
    DateTime publishedAt,
  ) => _DriverFeedPost._(publishedAt: publishedAt, request: request);

  factory _DriverFeedPost.trip(Trip trip, DateTime publishedAt) =>
      _DriverFeedPost._(publishedAt: publishedAt, trip: trip);
}

class _FeedLoadingCard extends StatelessWidget {
  const _FeedLoadingCard();

  @override
  Widget build(BuildContext context) => Container(
        height: 132,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFE2EBE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F4F3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 145, height: 10, color: Color(0xFFF0F4F3)),
                      const SizedBox(height: 7),
                      Container(width: 110, height: 8, color: Color(0xFFF0F4F3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(width: 205, height: 12, color: Color(0xFFF0F4F3)),
            const SizedBox(height: 8),
            Container(width: 140, height: 8, color: Color(0xFFF0F4F3)),
          ],
        ),
      );
}

class _FeedStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _FeedStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2EBE7)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF1E5AA8), size: 25),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF123D68),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF547080),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 13),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E5AA8),
                  minimumSize: const Size(120, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      );
}
