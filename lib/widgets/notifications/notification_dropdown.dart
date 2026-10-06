import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_notification.dart';
import '../../models/user.dart';
import '../../repositories/notification_repository.dart';
import '../../screens/driver/bookings/driver_trip_bookings_screen.dart';
import '../../screens/passenger/trips/passenger_booking_details_screen.dart';

class NotificationDropdown extends StatefulWidget {
  final User user;
  final LayerLink layerLink;
  final VoidCallback onClose;
  final VoidCallback onViewAll;

  const NotificationDropdown({
    super.key,
    required this.user,
    required this.layerLink,
    required this.onClose,
    required this.onViewAll,
  });

  @override
  State<NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<NotificationDropdown> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color textGrey = Color(0xFF547080);
  static const Color softBlue = Color(0xFFEAF3FC);

  final NotificationRepository _repository = NotificationRepository();
  List<AppNotification> _notifications = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    NotificationRepository.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    NotificationRepository.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final userId = widget.user.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible d’identifier votre compte.';
      });
      return;
    }

    try {
      final notifications = await _repository.getNotificationsForUser(userId);
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les notifications.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screen.width;
        final width = (availableWidth - 24).clamp(12.0, 340.0);

        return CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width,
              maxHeight: screen.height * 0.7,
            ),
            child: Material(
              color: Colors.white,
              elevation: 12,
              shadowColor: primaryBlue.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2EBE7)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header(),
                    Flexible(child: _body()),
                    _footer(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Notifications',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Fermer les notifications',
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, color: textGrey, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  Widget _body() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: green),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: textGrey, fontSize: 12.5),
          ),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucune notification pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textGrey, fontSize: 12.5),
          ),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) => _notificationItem(_notifications[index]),
      ),
    );
  }

  Widget _notificationItem(AppNotification notification) {
    final unread = !notification.isRead;
    return Material(
      color: unread ? const Color(0xFFF0F7FD) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _open(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unread
                  ? secondaryBlue.withValues(alpha: 0.2)
                  : const Color(0xFFE7F0EE),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: softBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: secondaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: green,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 11.3,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _dateLabel(notification.createdAt),
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(AppNotification notification) async {
    final userId = widget.user.id;
    if (userId == null) return;
    if (!notification.isRead) {
      await _repository.markAsRead(
        notificationId: notification.id,
        userId: userId,
      );
    }
    if (!mounted) return;
    widget.onClose();

    final references = _parseReferences(notification.type);
    if (references == null) return;

    if (widget.user.role == 'driver') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => DriverTripBookingsScreen(
            tripId: references.tripId,
            user: widget.user,
            focusBookingId: references.bookingId,
          ),
        ),
      );
      return;
    }

    if (widget.user.role == 'passenger') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PassengerBookingDetailsScreen(
            bookingId: references.bookingId,
            user: widget.user,
          ),
        ),
      );
    }
  }

  Widget _footer() => InkWell(
        onTap: () {
          widget.onClose();
          widget.onViewAll();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE2EBE7))),
          ),
          child: const Text(
            'Voir toutes les notifications →',
            style: TextStyle(
              color: secondaryBlue,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

  _NotificationReference? _parseReferences(String? type) {
    if (type == null) return null;
    final bookingMatch = RegExp(r'booking:(\d+)').firstMatch(type);
    final tripMatch = RegExp(r'trip:(\d+)').firstMatch(type);
    final bookingId = int.tryParse(bookingMatch?.group(1) ?? '');
    final tripId = int.tryParse(tripMatch?.group(1) ?? '');
    if (bookingId == null || tripId == null) return null;
    return _NotificationReference(bookingId, tripId);
  }

  String _dateLabel(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? value
        : DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(parsed);
  }
}

class _NotificationReference {
  final int bookingId;
  final int tripId;

  const _NotificationReference(this.bookingId, this.tripId);
}
