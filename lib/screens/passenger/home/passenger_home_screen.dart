import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/ride_request.dart';
import '../../../models/trip.dart';
import '../../../models/user.dart';
import '../../../models/user_profile_context.dart';
import '../../../repositories/trip_repository.dart';
import '../../../repositories/ride_request_repository.dart';
import '../../../widgets/passenger/passenger_header.dart';
import '../../../widgets/profile/user_profile_preview.dart';
import '../trips/trip_details_screen.dart';
import '../requests/ride_request_form_screen.dart';
import '../requests/ride_request_details_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  final User user;
  final VoidCallback onSearchTap;
  final VoidCallback onNavigateToReservations;

  const PassengerHomeScreen({
    super.key,
    required this.user,
    required this.onSearchTap,
    required this.onNavigateToReservations,
  });

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();

  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);
  static const Color lightGreen = Color(0xFFE8F8F1);
  static const Color lightPink = Color(0xFFFFEFF0);
  static const Color lightYellow = Color(0xFFFFF5DE);
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  static const Color primaryBlue = PassengerHomeScreen.primaryBlue;
  static const Color secondaryBlue = PassengerHomeScreen.secondaryBlue;
  static const Color green = PassengerHomeScreen.green;
  static const Color background = PassengerHomeScreen.background;
  static const Color textGrey = PassengerHomeScreen.textGrey;
  static const Color lightBlue = PassengerHomeScreen.lightBlue;
  static const Color lightGreen = PassengerHomeScreen.lightGreen;
  static const Color lightPink = PassengerHomeScreen.lightPink;
  static const Color lightYellow = PassengerHomeScreen.lightYellow;

  final TripRepository _tripRepository = TripRepository();
  final RideRequestRepository _rideRequestRepository = RideRequestRepository();
  List<_CommunityPost> _feedPosts = const [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final passengerId = widget.user.id;
    if (passengerId == null) {
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
      final results = await Future.wait<Object>([
        _tripRepository.getTripsForCommunityFeed(),
        _rideRequestRepository.getActiveRequestsForCommunityFeed(),
      ]);
      if (!mounted) return;
      final trips = results[0] as List<Trip>;
      final requests = results[1] as List<RideRequest>;
      final posts = <_CommunityPost>[
        ...trips.map(_CommunityPost.trip),
        ...requests.map(_CommunityPost.request),
      ]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      setState(() {
        _feedPosts = posts;
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
          onRefresh: _loadHomeData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PassengerHeader(user: widget.user),
                const SizedBox(height: 18),
                _buildSearchCta(),
                const SizedBox(height: 22),
                _buildRideRequestCta(context),
                const SizedBox(height: 25),
                const _SectionTitle(title: 'Accès rapides'),
                const SizedBox(height: 12),
                _buildQuickActions(context),
                const SizedBox(height: 25),
                const _SectionTitle(title: 'Fil d’accueil'),
                const SizedBox(height: 4),
                Text(
                  'Les dernières publications de la communauté',
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 13),
                _buildCommunityFeed(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECE9)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.search_rounded, color: green, size: 24),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trouvez votre prochain trajet',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Parcourez les trajets proposés par la communauté.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: widget.onSearchTap,
              icon: const Icon(Icons.search_rounded, size: 19),
              label: const Text(
                'Rechercher un trajet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.search_rounded,
            title: 'Rechercher\nun trajet',
            foreground: secondaryBlue,
            surface: lightBlue,
            onTap: widget.onSearchTap,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.event_available_rounded,
            title: 'Mes\nréservations',
            foreground: green,
            surface: lightGreen,
            onTap: widget.onNavigateToReservations,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.favorite_rounded,
            title: 'Mes trajets\nfavoris',
            foreground: const Color(0xFFD85B72),
            surface: lightPink,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _quickAction(
            context,
            icon: Icons.history_rounded,
            title: 'Historique',
            foreground: const Color(0xFFB98522),
            surface: lightYellow,
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color foreground,
    required Color surface,
    VoidCallback? onTap,
  }) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            onTap ??
            () => _showInfoDialog(
              context,
              title: title.replaceAll('\n', ' '),
              message: 'Cette section sera disponible prochainement.',
            ),
        child: SizedBox(
          height: 106,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 23),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 9.5,
                    height: 1.25,
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE7)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: secondaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.82),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityFeed(BuildContext context) {
    if (_isLoading) return const _HomeFeedLoading();
    if (_loadError != null) {
      return _HomeMessageCard(message: _loadError!, onRetry: _loadHomeData);
    }
    if (_feedPosts.isEmpty) {
      return Column(
        children: [
          _buildEmptyState(
            icon: Icons.dynamic_feed_rounded,
            title: 'Le fil est encore calme',
            message:
                'Les nouvelles publications de la communauté apparaîtront ici.',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onSearchTap,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Rechercher un trajet'),
              style: TextButton.styleFrom(foregroundColor: secondaryBlue),
            ),
          ),
        ],
      );
    }
    return Column(
      children: _feedPosts
          .map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFeedPost(context, post),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildFeedPost(BuildContext context, _CommunityPost post) {
    final trip = post.trip;
    final request = post.request;
    final isTrip = trip != null;
    final profileUserId = trip?.driverId ?? request!.passengerId;
    final author = isTrip
        ? (trip.driverName.trim().isEmpty ? 'Conducteur' : trip.driverName)
        : (request?.passengerName?.trim().isNotEmpty == true
              ? request!.passengerName!
              : 'Passager');
    final avatar = isTrip ? trip.driverProfileImage : request?.passengerImage;
    final badgeColor = isTrip ? green : secondaryBlue;
    final route = isTrip
        ? '${trip.departure} → ${trip.destination}'
        : '${request!.departure} → ${request.destination}';
    final travelDate = isTrip
        ? _tripDateTime(trip.departureDate, trip.departureTime)
        : _requestDateTime(request!.requestDate, request.requestTime);
    final metadata = isTrip
        ? '${trip.availableSeats} ${trip.availableSeats == 1 ? 'place disponible' : 'places disponibles'}  ·  ${NumberFormat('0.##', 'fr_FR').format(trip.price)} TND'
        : '${request!.seatsRequested} ${request.seatsRequested == 1 ? 'place souhaitée' : 'places souhaitées'}';
    final description = isTrip ? trip.description : request?.description;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (trip?.id != null) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    TripDetailsScreen(tripId: trip!.id!, user: widget.user),
              ),
            );
          } else if (request != null) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RideRequestDetailsScreen(
                  request: request,
                  currentUser: widget.user,
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4ECE8)),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: .045),
                blurRadius: 14,
                offset: const Offset(0, 5),
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
                      userId: profileUserId,
                      currentUser: widget.user,
                      profileContext: UserProfileContext(
                        type: isTrip
                            ? UserProfileContextType.trip
                            : UserProfileContextType.rideRequest,
                        tripId: trip?.id,
                        rideRequestId: request?.id,
                        departure: isTrip ? trip.departure : request?.departure,
                        destination: isTrip
                            ? trip.destination
                            : request?.destination,
                      ),
                      child: Row(
                        children: [
                          _feedAvatar(author, avatar, isTrip),
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${isTrip ? 'Conducteur' : 'Recherche un trajet'} · ${_publicationLabel(post.publishedAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: textGrey,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      isTrip ? 'TRAJET' : 'DEMANDE',
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                route,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              _feedInfo(Icons.calendar_month_rounded, travelDate),
              const SizedBox(height: 7),
              _feedInfo(
                isTrip ? Icons.event_seat_outlined : Icons.groups_2_outlined,
                metadata,
              ),
              if (description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 11),
                Text(
                  description!.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isTrip ? 'Voir le trajet  ›' : 'Voir la demande  ›',
                  style: TextStyle(
                    color: isTrip ? green : secondaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedInfo(IconData icon, String label) => Row(
    children: [
      Icon(icon, size: 16, color: secondaryBlue),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: textGrey, fontSize: 11.5),
        ),
      ),
    ],
  );

  Widget _feedAvatar(String name, String? image, bool isTrip) {
    final source = image?.trim();
    final uri = source == null ? null : Uri.tryParse(source);
    final network =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final asset = source?.startsWith('assets/') == true;
    ImageProvider<Object>? provider;
    if (source != null && source.isNotEmpty && network) {
      provider = NetworkImage(source);
    } else if (source != null && source.isNotEmpty && asset) {
      provider = AssetImage(source);
    }
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((part) => part[0].toUpperCase()).join();
    return CircleAvatar(
      radius: 21,
      backgroundColor: isTrip ? lightGreen : lightBlue,
      foregroundImage: provider,
      onForegroundImageError: provider is NetworkImage ? (_, _) {} : null,
      child: Text(
        initials,
        style: TextStyle(
          color: isTrip ? green : secondaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _tripDateTime(String date, String time) {
    final parsed = DateTime.tryParse('$date $time');
    return parsed == null
        ? '$date · $time'
        : DateFormat('d MMM · HH:mm', 'fr_FR').format(parsed);
  }

  String _requestDateTime(String date, String? time) {
    final parsed = DateTime.tryParse(date);
    final dateLabel = parsed == null
        ? date
        : DateFormat('d MMM', 'fr_FR').format(parsed);
    return time?.trim().isNotEmpty == true
        ? '$dateLabel · ${time!.trim()}'
        : '$dateLabel · Heure à préciser';
  }

  String _publicationLabel(DateTime value) {
    final publishedAt = value.toLocal();
    final difference = DateTime.now().difference(publishedAt);
    if (difference.inSeconds < 60) return 'À l’instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24 && publishedAt.day == DateTime.now().day) {
      return 'Il y a ${difference.inHours} h';
    }
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (publishedAt.year == yesterday.year &&
        publishedAt.month == yesterday.month &&
        publishedAt.day == yesterday.day) {
      return 'Hier';
    }
    return DateFormat('d MMM', 'fr_FR').format(publishedAt);
  }

  Widget _buildRideRequestCta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: .13),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Besoin d’un trajet ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Publiez une demande de covoiturage.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Publier une demande',
            style: IconButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => RideRequestFormScreen(user: widget.user),
                ),
              );
              if (created == true && mounted) await _loadHomeData();
            },
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: secondaryBlue,
                  size: 29,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey.withValues(alpha: 0.82),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Compris',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PassengerHomeScreen.primaryBlue,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeMessageCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _HomeMessageCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: PassengerHomeScreen.textGrey,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: PassengerHomeScreen.textGrey,
              fontSize: 12,
            ),
          ),
        ),
        IconButton(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          color: PassengerHomeScreen.secondaryBlue,
        ),
      ],
    ),
  );
}

class _CommunityPost {
  final Trip? trip;
  final RideRequest? request;
  final DateTime publishedAt;

  const _CommunityPost._({this.trip, this.request, required this.publishedAt});

  factory _CommunityPost.trip(Trip trip) => _CommunityPost._(
    trip: trip,
    publishedAt:
        DateTime.tryParse(trip.createdAt) ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory _CommunityPost.request(RideRequest request) => _CommunityPost._(
    request: request,
    publishedAt:
        DateTime.tryParse(request.createdAt) ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class _HomeFeedLoading extends StatelessWidget {
  const _HomeFeedLoading();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE4ECE8)),
    ),
    child: const Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: PassengerHomeScreen.green,
          ),
        ),
        SizedBox(width: 13),
        Text(
          'Chargement du fil…',
          style: TextStyle(
            color: PassengerHomeScreen.textGrey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
