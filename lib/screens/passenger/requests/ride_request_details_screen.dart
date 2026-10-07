import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/ride_request.dart';
import '../../../models/user.dart';
import '../../../widgets/profile/user_profile_preview.dart';
import '../../shared/messages/chat_screen.dart';

class RideRequestDetailsScreen extends StatelessWidget {
  final RideRequest request;
  final User currentUser;

  const RideRequestDetailsScreen({
    super.key,
    required this.request,
    required this.currentUser,
  });

  static const _blue = Color(0xFF123D68);
  static const _secondaryBlue = Color(0xFF1E5AA8);
  static const _background = Color(0xFFF4FFFB);
  static const _muted = Color(0xFF547080);

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(request.requestDate);
    final dateLabel = date == null
        ? request.requestDate
        : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    final author = request.passengerName?.trim().isNotEmpty == true
        ? request.passengerName!
        : 'Passager';
    final role = currentUser.role.trim().toLowerCase();
    final status = request.status.trim().toLowerCase();
    final isOwner =
        role == 'passenger' && currentUser.id == request.passengerId;
    final canContact =
        role == 'driver' &&
        currentUser.isActive &&
        currentUser.id != null &&
        currentUser.id != request.passengerId &&
        request.id != null &&
        status == 'active';
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _blue,
        elevation: 0,
        title: const Text(
          'Détails de la demande',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE3ECE8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        Expanded(
                          child: UserProfileTarget(
                            userId: request.passengerId,
                            enabled: currentUser.role == 'passenger',
                            borderRadius: BorderRadius.circular(14),
                            child: Row(
                              children: [
                                _passengerAvatar(author, request.passengerImage),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        author,
                                        style: const TextStyle(
                                          color: _blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Recherche un trajet',
                                        style: TextStyle(color: _muted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _statusBadge(request.status),
                      ],
                    ),
                  const SizedBox(height: 22),
                  Text(
                    '${request.departure} → ${request.destination}',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 19),
                  _detailRow(Icons.calendar_month_rounded, dateLabel),
                  if (request.requestTime?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 13),
                    _detailRow(Icons.schedule_rounded, request.requestTime!),
                  ],
                  const SizedBox(height: 13),
                  _detailRow(
                    Icons.event_seat_outlined,
                    '${request.seatsRequested} ${request.seatsRequested == 1 ? 'place souhaitée' : 'places souhaitées'}',
                  ),
                  if (request.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Précisions',
                      style: TextStyle(
                        color: _blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      request.description!.trim(),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isOwner) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FC),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Text(
                  'Votre demande',
                  style: TextStyle(
                    color: _secondaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ] else if (canContact) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(
                        tripId: null,
                        rideRequestId: request.id!,
                        currentUser: currentUser,
                        otherUserId: request.passengerId,
                        otherUserName: author,
                        requestDeparture: request.departure,
                        requestDestination: request.destination,
                        requestDate: request.requestDate,
                        requestTime: request.requestTime,
                        requestSeats: request.seatsRequested,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Contacter le passager'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String value) => Row(
    children: [
      Icon(icon, color: _secondaryBlue, size: 19),
      const SizedBox(width: 10),
      Expanded(
        child: Text(value, style: const TextStyle(color: _muted, fontSize: 13)),
      ),
    ],
  );

  Widget _passengerAvatar(String name, String? image) {
    final source = image?.trim();
    final uri = source == null ? null : Uri.tryParse(source);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final isAsset = source?.startsWith('assets/') == true;
    final ImageProvider<Object>? provider = isNetwork
        ? NetworkImage(source!)
        : isAsset
        ? AssetImage(source!)
        : null;
    return CircleAvatar(
      backgroundColor: const Color(0xFFEAF3FC),
      foregroundImage: provider,
      onForegroundImageError: provider is NetworkImage ? (_, _) {} : null,
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: _secondaryBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F8F1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status == 'active' ? 'ACTIVE' : status.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF16875A),
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
