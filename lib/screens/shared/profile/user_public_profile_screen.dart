import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../models/user_profile_context.dart';
import '../../../models/vehicle.dart';
import '../../../repositories/driver_profile_repository.dart';
import '../../../repositories/message_repository.dart';
import '../../../repositories/rating_repository.dart';
import '../../../repositories/report_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/vehicle_repository.dart';
import '../messages/chat_screen.dart';
import '../reporting/report_form_screen.dart';
import '../../../widgets/profile/user_profile_avatar.dart';
import 'user_rating_screen.dart';

class UserPublicProfileScreen extends StatefulWidget {
  final int userId;
  final User currentUser;
  final UserProfileContext contextInfo;

  const UserPublicProfileScreen({
    super.key,
    required this.userId,
    required this.currentUser,
    this.contextInfo = const UserProfileContext(),
  });

  @override
  State<UserPublicProfileScreen> createState() =>
      _UserPublicProfileScreenState();
}

class _UserPublicProfileScreenState extends State<UserPublicProfileScreen> {
  static const _blue = Color(0xFF123D68);
  static const _secondaryBlue = Color(0xFF1E5AA8);
  static const _green = Color(0xFF20B978);
  static const _background = Color(0xFFF4FFFB);
  static const _muted = Color(0xFF547080);

  User? _user;
  Vehicle? _vehicle;
  DriverProfileStats? _driverStats;
  double? _ratingAverage;
  int _ratingCount = 0;
  RatingEligibility? _ratingEligibility;
  bool _canContact = false;
  bool _canReport = false;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await UserRepository().getActiveUserById(widget.userId);
      if (!mounted) return;
      if (user == null || user.role == 'admin') {
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }

      Vehicle? vehicle;
      DriverProfileStats? driverStats;
      double? ratingAverage;
      var ratingCount = 0;
      if (user.role == 'driver' && user.id != null) {
        try {
          vehicle = await VehicleRepository().getVehicleForUser(user.id!);
        } catch (_) {}
        try {
          driverStats = await DriverProfileRepository().getStats(user.id!);
        } catch (_) {}
      }
      if (user.id != null) {
        try {
          final stats = await RatingRepository().getPublicStats(user.id!);
          ratingAverage = stats.average;
          ratingCount = stats.count;
        } catch (_) {}
      }
      final viewerId = widget.currentUser.id;
      var canContact = false;
      var canReport = false;
      RatingEligibility? ratingEligibility;
      if (viewerId != null &&
          user.id != null &&
          viewerId != user.id &&
          widget.currentUser.isActive) {
        final contextInfo = widget.contextInfo;
        final messages = MessageRepository();
        if (contextInfo.type == UserProfileContextType.trip ||
            contextInfo.type == UserProfileContextType.booking) {
          if (contextInfo.tripId != null) {
            canContact = await messages.canStartTripConversation(
              tripId: contextInfo.tripId!,
              currentUserId: viewerId,
              otherUserId: user.id!,
            );
          }
          canReport = await ReportRepository().canCreateProfileReport(
            reporterId: viewerId,
            targetId: user.id!,
            tripId: contextInfo.tripId,
            bookingId: contextInfo.bookingId,
          );
          if (contextInfo.tripId != null && widget.currentUser.role == 'passenger') {
            ratingEligibility = await RatingRepository().getEligibility(
              tripId: contextInfo.tripId!,
              reviewerId: viewerId,
              reviewedId: user.id!,
            );
          }
        } else if (contextInfo.type == UserProfileContextType.rideRequest &&
            contextInfo.rideRequestId != null &&
            widget.currentUser.role == 'driver') {
          canContact = await messages.canStartRideRequestConversation(
            rideRequestId: contextInfo.rideRequestId!,
            currentUserId: viewerId,
            otherUserId: user.id!,
          );
          canReport = await ReportRepository().canCreateProfileReport(
            reporterId: viewerId,
            targetId: user.id!,
            rideRequestId: contextInfo.rideRequestId,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _user = user;
        _vehicle = vehicle;
        _driverStats = driverStats;
        _ratingAverage = ratingAverage;
        _ratingCount = ratingCount;
        _canContact = canContact;
        _canReport = canReport;
        _ratingEligibility = ratingEligibility;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _blue,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : _failed || user == null
            ? _buildUnavailable()
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  _buildIdentity(user),
                  if (_ratingCount == 0) ...[
                    const SizedBox(height: 14),
                    _section(
                      title: 'Évaluation',
                      icon: Icons.star_outline_rounded,
                      child: _detailRow(
                        Icons.star_border_rounded,
                        'Aucune évaluation',
                        iconColor: const Color(0xFFE2A631),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    _section(
                      title: 'Évaluation',
                      icon: Icons.star_outline_rounded,
                      child: _detailRow(
                        Icons.star_rounded,
                        '${_ratingAverage?.toStringAsFixed(1) ?? '—'} · $_ratingCount avis',
                        iconColor: const Color(0xFFE2A631),
                      ),
                    ),
                  ],
                  if (_canContact ||
                      _canReport ||
                      _ratingEligibility == RatingEligibility.eligible ||
                      _ratingEligibility == RatingEligibility.alreadyRated) ...[
                    const SizedBox(height: 14),
                    _buildActions(user),
                  ],
                  if (user.university?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    _section(
                      title: 'Informations',
                      icon: Icons.info_outline_rounded,
                      child: _detailRow(
                        Icons.school_outlined,
                        user.university!.trim(),
                      ),
                    ),
                  ],
                  if ((_driverStats?.completedTrips ?? 0) > 0) ...[
                    const SizedBox(height: 14),
                    _section(
                      title: 'Activité',
                      icon: Icons.route_outlined,
                      child: _detailRow(
                        Icons.check_circle_outline_rounded,
                        '${_driverStats!.completedTrips} trajets réalisés',
                      ),
                    ),
                  ],
                  if (user.role == 'driver' && _vehicle != null) ...[
                    const SizedBox(height: 14),
                    _buildVehicle(_vehicle!),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildActions(User user) => _section(
    title: 'Actions',
    icon: Icons.more_horiz_rounded,
    child: Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        if (_canContact)
          _actionButton(
            Icons.chat_bubble_outline_rounded,
            'Contacter',
            _openChat,
          ),
        if (_canReport)
          _actionButton(
            Icons.flag_outlined,
            'Signaler',
            () => _openReport(user),
          ),
        if (_ratingEligibility == RatingEligibility.eligible)
          _actionButton(
            Icons.star_outline_rounded,
            'Évaluer',
            () => _openRating(user),
          ),
        if (_ratingEligibility == RatingEligibility.alreadyRated)
          const Chip(
            avatar: Icon(Icons.check_circle_outline, size: 17),
            label: Text('Déjà évalué'),
          ),
      ],
    ),
  );

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _secondaryBlue,
          side: const BorderSide(color: Color(0xFFD9E8E2)),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      );

  Future<void> _openChat() async {
    final user = _user;
    final currentUserId = widget.currentUser.id;
    if (user == null ||
        user.id == null ||
        currentUserId == null ||
        !_canContact) {
      return;
    }
    final info = widget.contextInfo;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          tripId: info.rideRequestId == null ? info.tripId : null,
          rideRequestId: info.rideRequestId,
          currentUser: widget.currentUser,
          otherUserId: user.id!,
          otherUserName: user.fullName,
          tripDeparture: info.rideRequestId == null ? info.departure : null,
          tripDestination: info.rideRequestId == null ? info.destination : null,
          requestDeparture: info.rideRequestId != null ? info.departure : null,
          requestDestination: info.rideRequestId != null
              ? info.destination
              : null,
        ),
      ),
    );
  }

  Future<void> _openReport(User user) async {
    if (!_canReport || user.id == null || widget.currentUser.id == null) return;
    final info = widget.contextInfo;
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReportFormScreen(
          reporter: widget.currentUser,
          targetUserId: user.id,
          profileContext: info,
          flow: widget.currentUser.role == 'driver'
              ? ReportFlow.driverReportsPassenger
              : ReportFlow.passengerReportsDriver,
          targetName: user.fullName,
          routeLabel: info.routeLabel,
        ),
      ),
    );
    if (!mounted || submitted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Votre signalement a été envoyé.')),
    );
    await _loadProfile();
  }

  Future<void> _openRating(User user) async {
    final tripId = widget.contextInfo.tripId;
    if (_ratingEligibility != RatingEligibility.eligible ||
        tripId == null ||
        user.id == null) {
      return;
    }
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => UserRatingScreen(
          reviewer: widget.currentUser,
          reviewed: user,
          tripId: tripId,
        ),
      ),
    );
    if (!mounted || submitted != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Évaluation publiée.')));
    await _loadProfile();
  }

  Widget _buildIdentity(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3ECE8)),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: .05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          UserProfileAvatar(
            name: user.fullName,
            image: user.profileImage,
            size: 88,
          ),
          const SizedBox(height: 13),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _blue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _roleLabel(user.role),
              style: const TextStyle(
                color: _secondaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (user.university?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 9),
            Text(
              user.university!.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicle(Vehicle vehicle) => _section(
    title: 'Véhicule',
    icon: Icons.directions_car_outlined,
    child: Column(
      children: [
        if (vehicle.brand.trim().isNotEmpty || vehicle.model.trim().isNotEmpty)
          _detailRow(
            Icons.directions_car_rounded,
            [
              if (vehicle.brand.trim().isNotEmpty) vehicle.brand.trim(),
              if (vehicle.model.trim().isNotEmpty) vehicle.model.trim(),
            ].join(' '),
          ),
        if (vehicle.color?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 11),
          _detailRow(Icons.palette_outlined, vehicle.color!.trim()),
        ],
        if (vehicle.seats > 0) ...[
          const SizedBox(height: 11),
          _detailRow(Icons.event_seat_outlined, '${vehicle.seats} places'),
        ],
      ],
    ),
  );

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFFE3ECE8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _secondaryBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: _blue,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );

  Widget _detailRow(IconData icon, String value, {Color iconColor = _green}) =>
      Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      );

  Widget _buildUnavailable() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_off_outlined,
            color: _secondaryBlue,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Profil indisponible',
            style: TextStyle(
              color: _blue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ce profil ne peut pas être affiché pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );

  String _roleLabel(String role) => switch (role) {
    'driver' => 'Conducteur',
    'passenger' => 'Passager',
    _ => 'Membre',
  };
}
