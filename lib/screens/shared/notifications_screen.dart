import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_helper.dart';
import '../../models/app_notification.dart';
import '../../models/user.dart';
import '../../repositories/message_repository.dart';
import '../../repositories/notification_repository.dart';
import '../driver/bookings/driver_trip_bookings_screen.dart';
import '../passenger/trips/passenger_booking_details_screen.dart';
import 'messages/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final User user;

  const NotificationsScreen({super.key, required this.user});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = await _repository.getNotificationsForUser(userId);
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: primaryBlue),
                    ),
                    const SizedBox(width: 6),
                    const Text('Notifications', style: TextStyle(color: primaryBlue, fontSize: 19, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: green))
                    : _error != null
                        ? _empty(_error!, 'Réessayez dans quelques instants.', action: 'Réessayer', onAction: _load)
                        : _notifications.isEmpty
                            ? _empty('Aucune notification', 'Vos notifications apparaîtront ici.')
                            : RefreshIndicator(
                                color: primaryBlue,
                                onRefresh: _load,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                                  itemCount: _notifications.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                                  itemBuilder: (context, index) => _notificationCard(_notifications[index]),
                                ),
                              ),
              ),
            ],
          ),
        ),
      );

  Widget _notificationCard(AppNotification notification) => Material(
        color: notification.isRead ? Colors.white : const Color(0xFFF0F7FD),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _open(notification),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: notification.isRead ? const Color(0xFFE2EBE7) : secondaryBlue.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: lightBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_none_rounded, color: secondaryBlue, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(notification.title, style: const TextStyle(color: primaryBlue, fontSize: 12.5, fontWeight: FontWeight.w800))),
                          if (!notification.isRead)
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: green, shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(notification.body, style: const TextStyle(color: textGrey, fontSize: 11.5, height: 1.4)),
                      const SizedBox(height: 6),
                      Text(_dateLabel(notification.createdAt), style: const TextStyle(color: textGrey, fontSize: 9.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _open(AppNotification notification) async {
    final userId = widget.user.id;
    if (userId == null) return;
    if (!notification.isRead) {
      try {
        await _repository.markAsRead(notificationId: notification.id, userId: userId);
      } catch (_) {
        if (!mounted) return;
        return;
      }
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((item) => item.id == notification.id
                ? AppNotification(
                    id: item.id,
                    userId: item.userId,
                    title: item.title,
                    body: item.body,
                    type: item.type,
                    isRead: true,
                    createdAt: item.createdAt,
                  )
                : item)
            .toList(growable: false);
      });
    }

    final type = notification.type ?? '';

    // ---- Message notification: message:N;trip:N ----
    if (type.startsWith('message:')) {
      final msgMatch = RegExp(r'message:(\d+)').firstMatch(type);
      final tripMatch = RegExp(r'trip:(\d+)').firstMatch(type);
      final messageId = int.tryParse(msgMatch?.group(1) ?? '');
      final tripId = int.tryParse(tripMatch?.group(1) ?? '');
      if (messageId == null || tripId == null) return;

      final msgRepo = MessageRepository();
      final message = await msgRepo.getMessageById(messageId);
      if (!mounted || message == null) return;

      final otherUserId =
          message.senderId == userId ? message.receiverId : message.senderId;

      final db = await DatabaseHelper.instance.database;
      if (!mounted) return;

      final userRows = await db.query(
        'users',
        columns: ['full_name'],
        where: 'id = ?',
        whereArgs: [otherUserId],
        limit: 1,
      );
      if (!mounted) return;
      final otherName = userRows.isEmpty
          ? 'Utilisateur'
          : userRows.first['full_name'] as String;

      final tripRows = await db.query(
        'trips',
        columns: ['departure', 'destination'],
        where: 'id = ?',
        whereArgs: [tripId],
        limit: 1,
      );
      if (!mounted) return;
      final departure =
          tripRows.isEmpty ? null : tripRows.first['departure'] as String?;
      final destination =
          tripRows.isEmpty ? null : tripRows.first['destination'] as String?;

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            tripId: tripId,
            currentUser: widget.user,
            otherUserId: otherUserId,
            otherUserName: otherName,
            tripDeparture: departure,
            tripDestination: destination,
          ),
        ),
      );
      if (!mounted) return;
      await _load();
      return;
    }

    // ---- Booking notification: booking:N;trip:N ----
    final references = _parseReferences(type);
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
    } else if (widget.user.role == 'passenger') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PassengerBookingDetailsScreen(
            bookingId: references.bookingId,
            user: widget.user,
          ),
        ),
      );
    }
    if (!mounted) return;
    await _load();
    if (!mounted) return;
  }

  _NotificationReference? _parseReferences(String? type) {
    if (type == null) return null;
    final bookingMatch = RegExp(r'booking:(\d+)').firstMatch(type);
    final tripMatch = RegExp(r'trip:(\d+)').firstMatch(type);
    final bookingId = int.tryParse(bookingMatch?.group(1) ?? '');
    final tripId = int.tryParse(tripMatch?.group(1) ?? '');
    if (bookingId == null || tripId == null) return null;
    return _NotificationReference(bookingId, tripId);
  }

  Widget _empty(String title, String message, {String? action, VoidCallback? onAction}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none_rounded, color: secondaryBlue, size: 40),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: primaryBlue, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: textGrey, fontSize: 11.5)),
              if (action != null) TextButton(onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
      );

  String _dateLabel(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(parsed);
  }
}

class _NotificationReference {
  final int bookingId;
  final int tripId;

  const _NotificationReference(this.bookingId, this.tripId);
}
