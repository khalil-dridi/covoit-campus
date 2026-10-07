import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/message.dart';
import 'notification_repository.dart';

// ---------------------------------------------------------------------------
// ConversationSummary
// ---------------------------------------------------------------------------
// Lightweight view object returned by getConversationsForUser().
// Contains everything the conversation-list screen needs.
// ---------------------------------------------------------------------------

class ConversationSummary {
  final int? tripId;
  final int? rideRequestId;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final String tripDeparture;
  final String tripDestination;
  final String lastMessage;
  final String lastMessageAt;
  final int unreadCount;
  final String? requestDate;
  final String? requestTime;
  final int? requestedSeats;

  bool get isRideRequest => rideRequestId != null;

  const ConversationSummary({
    required this.tripId,
    required this.rideRequestId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    required this.tripDeparture,
    required this.tripDestination,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.requestDate,
    this.requestTime,
    this.requestedSeats,
  });

  factory ConversationSummary.fromMap(Map<String, Object?> map) =>
      ConversationSummary(
        tripId: map['trip_id'] as int?,
        rideRequestId: map['ride_request_id'] as int?,
        otherUserId: map['other_user_id'] as int,
        otherUserName: map['other_user_name'] as String,
        otherUserImage: map['other_user_image'] as String?,
        tripDeparture: map['trip_departure'] as String? ?? '',
        tripDestination: map['trip_destination'] as String? ?? '',
        lastMessage: map['last_message'] as String,
        lastMessageAt: map['last_message_at'] as String,
        unreadCount: map['unread_count'] as int? ?? 0,
        requestDate: map['request_date'] as String?,
        requestTime: map['request_time'] as String?,
        requestedSeats: map['requested_seats'] as int?,
      );
}

// ---------------------------------------------------------------------------
// MessageRepository
// ---------------------------------------------------------------------------

class MessageRepository {
  static const int _maxMessageLength = 1000;

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Reactive change signal — increment after any mutation so that badges
  // and conversation lists know to reload. Mirrors the pattern used by
  // NotificationRepository.changes.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void _notifyChanged() => changes.value++;

  /// Whether the authenticated participants may open a trip conversation.
  /// This is an advisory UI check; sendMessage repeats the checks inside its
  /// write transaction before persisting anything.
  Future<bool> canStartTripConversation({
    required int tripId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    if (currentUserId == otherUserId) return false;
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT trips.driver_id, trips.status, current.role AS current_role,
             other.role AS other_role
      FROM trips
      INNER JOIN users AS current ON current.id = ? AND current.is_active = 1
      INNER JOIN users AS other ON other.id = ? AND other.is_active = 1
      WHERE trips.id = ? AND trips.status != 'cancelled'
      LIMIT 1
    ''',
      [currentUserId, otherUserId, tripId],
    );
    if (rows.isEmpty) return false;
    final row = rows.first;
    final driverId = row['driver_id'] as int;
    final currentRole = row['current_role'];
    final otherRole = row['other_role'];
    if (currentUserId == driverId &&
        currentRole == 'driver' &&
        otherRole == 'passenger') {
      final booking = await db.query(
        'bookings',
        columns: ['id'],
        where: 'trip_id = ? AND passenger_id = ? AND status IN (?, ?)',
        whereArgs: [tripId, otherUserId, 'pending', 'accepted'],
        limit: 1,
      );
      return booking.isNotEmpty;
    }
    if (otherUserId == driverId &&
        otherRole == 'driver' &&
        currentRole == 'passenger') {
      final booking = await db.query(
        'bookings',
        columns: ['id'],
        where: 'trip_id = ? AND passenger_id = ? AND status IN (?, ?)',
        whereArgs: [tripId, currentUserId, 'pending', 'accepted'],
        limit: 1,
      );
      return booking.isNotEmpty;
    }
    return false;
  }

  Future<bool> canStartRideRequestConversation({
    required int rideRequestId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    try {
      final db = await _databaseHelper.database;
      await _validateRideRequestConversation(
        executor: db,
        rideRequestId: rideRequestId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      // The owner can only open an existing thread. For a driver, the request
      // validator allows the owner-directed thread, which is the intended
      // contact entry point.
      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // 1. sendMessage
  //
  // Inserts a new message after validating content and access control,
  // then creates a single notification for the receiver — all in one
  // SQLite transaction so a failure rolls back both writes atomically.
  //
  // Returns the SQLite row-id of the inserted message.
  // =========================================================================

  Future<int> sendMessage({
    required int tripId,
    required int senderId,
    required int receiverId,
    required String message,
  }) async {
    // ----- Input validation ------------------------------------------------

    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Le message ne peut pas être vide.');
    }
    if (trimmed.length > _maxMessageLength) {
      throw ArgumentError(
        'Le message dépasse la limite de $_maxMessageLength caractères.',
      );
    }
    if (senderId == receiverId) {
      throw ArgumentError(
        'L\'expéditeur et le destinataire doivent être différents.',
      );
    }

    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    final insertedId = await db.transaction<int>((txn) async {
      // 1. Trip must exist and not be cancelled.
      final tripRows = await txn.query(
        'trips',
        columns: ['id', 'driver_id', 'status'],
        where: 'id = ?',
        whereArgs: [tripId],
        limit: 1,
      );
      if (tripRows.isEmpty) {
        throw StateError('Le trajet est introuvable.');
      }
      final trip = tripRows.first;
      final driverId = trip['driver_id'] as int;
      final tripStatus = trip['status'] as String;
      if (tripStatus == 'cancelled') {
        throw StateError(
          'Impossible d\'envoyer un message pour un trajet annulé.',
        );
      }

      // 2. Sender must exist and be active.
      final senderRows = await txn.query(
        'users',
        columns: ['id', 'full_name', 'role', 'is_active'],
        where: 'id = ? AND is_active = 1',
        whereArgs: [senderId],
        limit: 1,
      );
      if (senderRows.isEmpty) {
        throw StateError('Le compte expéditeur est invalide ou désactivé.');
      }
      final senderName = senderRows.first['full_name'] as String;
      final senderRole = senderRows.first['role'] as String;

      // 3. Receiver must exist and be active.
      final receiverRows = await txn.query(
        'users',
        columns: ['id', 'role', 'is_active'],
        where: 'id = ? AND is_active = 1',
        whereArgs: [receiverId],
        limit: 1,
      );
      if (receiverRows.isEmpty) {
        throw StateError('Le compte destinataire est invalide ou désactivé.');
      }

      // 4. Access control ---------------------------------------------------
      //
      // Rule A — sender is the trip's driver:
      //   receiver must have a pending/accepted booking on this trip.
      //
      // Rule B — sender is a passenger:
      //   sender must have a pending/accepted booking on this trip, and
      //   receiver must be the actual trip driver.

      if (senderId == driverId) {
        if (senderRole != 'driver' ||
            receiverRows.first['role'] != 'passenger') {
          throw StateError('Cette conversation n’est pas autorisée.');
        }
        final bookingRows = await txn.query(
          'bookings',
          columns: ['id'],
          where: 'trip_id = ? AND passenger_id = ? AND status IN (?, ?)',
          whereArgs: [tripId, receiverId, 'pending', 'accepted'],
          limit: 1,
        );
        if (bookingRows.isEmpty) {
          throw StateError(
            'Vous ne pouvez contacter que les passagers ayant réservé ce trajet.',
          );
        }
      } else {
        if (senderRole != 'passenger' ||
            receiverRows.first['role'] != 'driver') {
          throw StateError('Cette conversation n’est pas autorisée.');
        }
        final bookingRows = await txn.query(
          'bookings',
          columns: ['id'],
          where: 'trip_id = ? AND passenger_id = ? AND status IN (?, ?)',
          whereArgs: [tripId, senderId, 'pending', 'accepted'],
          limit: 1,
        );
        if (bookingRows.isEmpty) {
          throw StateError(
            'Vous devez avoir une réservation valide pour contacter le conducteur.',
          );
        }
        if (receiverId != driverId) {
          throw StateError(
            'Vous ne pouvez contacter que le conducteur de ce trajet.',
          );
        }
      }

      // 5. Insert the message.
      final messageId = await txn.insert('messages', {
        'trip_id': tripId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': trimmed,
        'is_read': 0,
        'created_at': now,
      });
      if (messageId <= 0) {
        throw StateError('L\'insertion du message a échoué.');
      }

      // 6. Create a notification for the receiver — same transaction so that
      //    a rollback removes both the message and the notification.
      await NotificationRepository.insertInTransaction(
        transaction: txn,
        userId: receiverId,
        title: 'Nouveau message',
        body: '$senderName vous a envoyé un message.',
        type: 'message:$messageId;trip:$tripId',
        createdAt: now,
      );

      return messageId;
    });

    // Notify both message-badge listeners and notification-bell listeners.
    _notifyChanged();
    NotificationRepository.notifyChanged();

    return insertedId;
  }

  Future<int> sendRideRequestMessage({
    required int rideRequestId,
    required int senderId,
    required int otherUserId,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Le message ne peut pas être vide.');
    }
    if (trimmed.length > _maxMessageLength) {
      throw ArgumentError(
        'Le message dépasse la limite de $_maxMessageLength caractères.',
      );
    }

    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final insertedId = await db.transaction<int>((txn) async {
      final requestRows = await txn.query(
        'ride_requests',
        columns: ['passenger_id', 'status'],
        where: 'id = ?',
        whereArgs: [rideRequestId],
        limit: 1,
      );
      if (requestRows.isEmpty || requestRows.first['status'] != 'active') {
        throw StateError('Cette demande n’est plus disponible.');
      }
      final passengerId = requestRows.first['passenger_id'] as int;
      if (passengerId == senderId && otherUserId == senderId) {
        throw StateError('Vous ne pouvez pas vous envoyer un message.');
      }

      final senderRows = await txn.query(
        'users',
        columns: ['full_name', 'role'],
        where: 'id = ? AND is_active = 1',
        whereArgs: [senderId],
        limit: 1,
      );
      if (senderRows.isEmpty) {
        throw StateError('Le compte expéditeur est invalide ou désactivé.');
      }
      final passengerRows = await txn.query(
        'users',
        columns: ['id', 'role', 'is_active'],
        where: "id = ? AND role = 'passenger' AND is_active = 1",
        whereArgs: [passengerId],
        limit: 1,
      );
      if (passengerRows.isEmpty) {
        throw StateError('Le passager n’est plus disponible.');
      }

      late final int receiverId;
      if (senderId == passengerId) {
        if (senderRows.first['role'] != 'passenger') {
          throw StateError('Ce compte ne peut pas répondre à cette demande.');
        }
        final driverRows = await txn.query(
          'users',
          columns: ['id'],
          where: "id = ? AND role = 'driver' AND is_active = 1",
          whereArgs: [otherUserId],
          limit: 1,
        );
        if (driverRows.isEmpty) {
          throw StateError('Le conducteur de cette conversation est invalide.');
        }
        final priorMessages = await txn.query(
          'messages',
          columns: ['id'],
          where: '''ride_request_id = ? AND
            ((sender_id = ? AND receiver_id = ?) OR
             (sender_id = ? AND receiver_id = ?))''',
          whereArgs: [
            rideRequestId,
            passengerId,
            otherUserId,
            otherUserId,
            passengerId,
          ],
          limit: 1,
        );
        if (priorMessages.isEmpty) {
          throw StateError(
            'Vous ne pouvez répondre qu’à un conducteur qui vous a contacté.',
          );
        }
        receiverId = otherUserId;
      } else {
        if (senderRows.first['role'] != 'driver' ||
            otherUserId != passengerId) {
          throw StateError(
            'Seul un conducteur peut contacter le propriétaire de cette demande.',
          );
        }
        receiverId = passengerId;
      }

      final messageId = await txn.insert('messages', {
        'trip_id': null,
        'ride_request_id': rideRequestId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': trimmed,
        'is_read': 0,
        'created_at': now,
      });
      if (messageId <= 0) throw StateError('L’insertion du message a échoué.');

      await NotificationRepository.insertInTransaction(
        transaction: txn,
        userId: receiverId,
        title: 'Nouveau message',
        body: '${senderRows.first['full_name']} vous a envoyé un message.',
        type: 'message:$messageId;request:$rideRequestId',
        createdAt: now,
      );
      return messageId;
    });

    _notifyChanged();
    NotificationRepository.notifyChanged();
    return insertedId;
  }

  Future<void> _validateRideRequestConversation({
    required DatabaseExecutor executor,
    required int rideRequestId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    if (currentUserId == otherUserId) {
      throw StateError('Une conversation doit avoir deux participants.');
    }
    final requests = await executor.query(
      'ride_requests',
      columns: ['passenger_id', 'status'],
      where: 'id = ?',
      whereArgs: [rideRequestId],
      limit: 1,
    );
    if (requests.isEmpty || requests.first['status'] != 'active') {
      throw StateError('Cette demande n’est plus disponible.');
    }
    final ownerId = requests.first['passenger_id'] as int;
    final users = await executor.query(
      'users',
      columns: ['id', 'role'],
      where: 'id IN (?, ?) AND is_active = 1',
      whereArgs: [currentUserId, otherUserId],
    );
    if (users.length != 2) {
      throw StateError('Un participant n’est plus actif.');
    }
    final roles = {
      for (final row in users) row['id'] as int: row['role'] as String,
    };
    if (roles[ownerId] != 'passenger') {
      throw StateError('Le propriétaire de la demande n’est plus disponible.');
    }

    if (currentUserId == ownerId) {
      if (roles[otherUserId] != 'driver') {
        throw StateError('Cette conversation n’est pas autorisée.');
      }
      final existing = await executor.query(
        'messages',
        columns: ['id'],
        where: '''ride_request_id = ? AND
          ((sender_id = ? AND receiver_id = ?) OR
           (sender_id = ? AND receiver_id = ?))''',
        whereArgs: [
          rideRequestId,
          currentUserId,
          otherUserId,
          otherUserId,
          currentUserId,
        ],
        limit: 1,
      );
      if (existing.isEmpty) {
        throw StateError('Cette conversation n’existe pas encore.');
      }
    } else if (roles[currentUserId] != 'driver' || otherUserId != ownerId) {
      throw StateError('Vous ne pouvez pas accéder à cette conversation.');
    }
  }

  Future<List<Message>> getRideRequestConversation({
    required int rideRequestId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    final db = await _databaseHelper.database;
    return db.transaction<List<Message>>((txn) async {
      await _validateRideRequestConversation(
        executor: txn,
        rideRequestId: rideRequestId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      final rows = await txn.query(
        'messages',
        where: '''ride_request_id = ? AND
          ((sender_id = ? AND receiver_id = ?) OR
           (sender_id = ? AND receiver_id = ?))''',
        whereArgs: [
          rideRequestId,
          currentUserId,
          otherUserId,
          otherUserId,
          currentUserId,
        ],
        orderBy: 'created_at ASC, id ASC',
      );
      return rows.map(Message.fromMap).toList(growable: false);
    });
  }

  Future<void> markRideRequestConversationAsRead({
    required int rideRequestId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    final db = await _databaseHelper.database;
    final updated = await db.transaction<int>((txn) async {
      await _validateRideRequestConversation(
        executor: txn,
        rideRequestId: rideRequestId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      return txn.update(
        'messages',
        {'is_read': 1},
        where: 'ride_request_id = ? AND receiver_id = ? AND sender_id = ? AND is_read = 0',
        whereArgs: [rideRequestId, currentUserId, otherUserId],
      );
    });
    if (updated > 0) _notifyChanged();
  }

  Future<int> getUnreadCountForRideRequestConversation({
    required int rideRequestId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    final db = await _databaseHelper.database;
    await _validateRideRequestConversation(
      executor: db,
      rideRequestId: rideRequestId,
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
    final rows = await db.rawQuery(
      '''SELECT COUNT(*) AS unread_count FROM messages
         WHERE ride_request_id = ? AND receiver_id = ?
           AND sender_id = ? AND is_read = 0''',
      [rideRequestId, currentUserId, otherUserId],
    );
    return rows.first['unread_count'] as int? ?? 0;
  }

  // =========================================================================
  // 2. getConversation
  //
  // Returns messages exchanged between currentUserId and otherUserId for the
  // given trip, ordered chronologically (oldest first).
  // =========================================================================

  Future<List<Message>> getConversation({
    required int tripId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    final db = await _databaseHelper.database;
    return db.transaction<List<Message>>((txn) async {
      await _validateTripConversation(
        executor: txn,
        tripId: tripId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      final rows = await txn.rawQuery(
        '''
      SELECT id, trip_id, sender_id, receiver_id, message, is_read, created_at
      FROM messages
      WHERE trip_id = ?
        AND (
              (sender_id = ? AND receiver_id = ?)
           OR (sender_id = ? AND receiver_id = ?)
            )
      ORDER BY created_at ASC, id ASC
      ''',
        [tripId, currentUserId, otherUserId, otherUserId, currentUserId],
      );
      return rows.map(Message.fromMap).toList(growable: false);
    });
  }

  Future<void> _validateTripConversation({
    required DatabaseExecutor executor,
    required int tripId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    if (currentUserId == otherUserId) {
      throw StateError('Une conversation doit avoir deux participants.');
    }
    final trips = await executor.query(
      'trips',
      columns: ['driver_id', 'status'],
      where: 'id = ?',
      whereArgs: [tripId],
      limit: 1,
    );
    if (trips.isEmpty || trips.first['status'] == 'cancelled') {
      throw StateError('Ce trajet ne permet plus cette conversation.');
    }
    final users = await executor.query(
      'users',
      columns: ['id', 'role'],
      where: 'id IN (?, ?) AND is_active = 1',
      whereArgs: [currentUserId, otherUserId],
    );
    if (users.length != 2) throw StateError('Un participant n’est plus actif.');
    final roles = {
      for (final row in users) row['id'] as int: row['role'] as String,
    };
    final driverId = trips.first['driver_id'] as int;
    if (currentUserId == driverId &&
        roles[currentUserId] == 'driver' &&
        roles[otherUserId] == 'passenger') {
      final booking = await executor.query(
        'bookings',
        columns: ['id'],
        where: 'trip_id = ? AND passenger_id = ? AND status IN (?, ?)',
        whereArgs: [tripId, otherUserId, 'pending', 'accepted'],
        limit: 1,
      );
      if (booking.isEmpty) {
        throw StateError(
          'Vous ne pouvez contacter que les passagers ayant réservé ce trajet.',
        );
      }
      return;
    }
    if (otherUserId == driverId &&
        roles[otherUserId] == 'driver' &&
        roles[currentUserId] == 'passenger') {
      final booking = await executor.query(
        'bookings',
        columns: ['id'],
        where: 'trip_id = ? AND passenger_id = ? AND status IN (?, ?)',
        whereArgs: [tripId, currentUserId, 'pending', 'accepted'],
        limit: 1,
      );
      if (booking.isEmpty) {
        throw StateError(
          'Vous devez avoir une réservation valide pour contacter le conducteur.',
        );
      }
      return;
    }
    throw StateError('Cette conversation n’est pas autorisée.');
  }

  // =========================================================================
  // 3. getConversationsForUser
  //
  // Returns one ConversationSummary per distinct (trip_id, other_user_id)
  // pair, enriched with trip route, last message, and unread count.
  // Sorted newest-first.
  // =========================================================================

  Future<List<ConversationSummary>> getConversationsForUser(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        conv.trip_id,
        conv.ride_request_id,
        conv.other_user_id,
        other_users.full_name     AS other_user_name,
        other_users.profile_image AS other_user_image,
        COALESCE(trips.departure, requests.departure) AS trip_departure,
        COALESCE(trips.destination, requests.destination) AS trip_destination,
        requests.request_date AS request_date,
        requests.request_time AS request_time,
        requests.seats_requested AS requested_seats,
        latest.message            AS last_message,
        latest.created_at         AS last_message_at,
        COALESCE(
          (
            SELECT COUNT(*)
            FROM messages AS unread_msgs
            WHERE unread_msgs.trip_id IS conv.trip_id
              AND unread_msgs.ride_request_id IS conv.ride_request_id
              AND unread_msgs.receiver_id = ?
              AND unread_msgs.sender_id   = conv.other_user_id
              AND unread_msgs.is_read     = 0
          ), 0
        ) AS unread_count
      FROM (
        SELECT DISTINCT
          trip_id,
          ride_request_id,
          CASE
            WHEN sender_id   = ? THEN receiver_id
            WHEN receiver_id = ? THEN sender_id
          END AS other_user_id
        FROM messages
        WHERE sender_id = ? OR receiver_id = ?
      ) AS conv
      INNER JOIN users AS other_users
        ON other_users.id = conv.other_user_id
      LEFT JOIN trips
        ON trips.id = conv.trip_id
      LEFT JOIN ride_requests AS requests
        ON requests.id = conv.ride_request_id
        AND requests.status = 'active'
      INNER JOIN messages AS latest
        ON latest.id = (
          SELECT candidate.id
          FROM messages AS candidate
          WHERE candidate.trip_id IS conv.trip_id
            AND candidate.ride_request_id IS conv.ride_request_id
            AND (
                  (candidate.sender_id = ? AND candidate.receiver_id = conv.other_user_id)
               OR (candidate.sender_id = conv.other_user_id AND candidate.receiver_id = ?)
                )
          ORDER BY candidate.created_at DESC, candidate.id DESC
          LIMIT 1
        )
      WHERE (conv.trip_id IS NOT NULL AND trips.id IS NOT NULL)
         OR (conv.ride_request_id IS NOT NULL AND requests.id IS NOT NULL)
      ORDER BY latest.created_at DESC, latest.id DESC
      ''',
      [userId, userId, userId, userId, userId, userId, userId],
    );
    return rows.map(ConversationSummary.fromMap).toList(growable: false);
  }

  // =========================================================================
  // 4. markConversationAsRead
  //
  // Marks as read only the messages received by currentUserId from
  // otherUserId for the given trip. Sent messages are never touched.
  // =========================================================================

  Future<void> markConversationAsRead({
    required int tripId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    final db = await _databaseHelper.database;
    final updated = await db.transaction<int>((txn) async {
      await _validateTripConversation(
        executor: txn,
        tripId: tripId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      return txn.update(
        'messages',
        {'is_read': 1},
        where:
            'trip_id = ? AND receiver_id = ? AND sender_id = ? AND is_read = 0',
        whereArgs: [tripId, currentUserId, otherUserId],
      );
    });
    if (updated > 0) _notifyChanged();
  }

  // =========================================================================
  // 5. getUnreadMessageCount
  //
  // Total unread messages received by userId across all conversations.
  // =========================================================================

  Future<int> getUnreadMessageCount(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS unread_count '
      'FROM messages '
      'WHERE receiver_id = ? AND is_read = 0',
      [userId],
    );
    return rows.first['unread_count'] as int? ?? 0;
  }

  // =========================================================================
  // 6. getUnreadCountForConversation
  //
  // Unread messages received by currentUserId from otherUserId for one trip.
  // =========================================================================

  Future<int> getUnreadCountForConversation({
    required int tripId,
    required int currentUserId,
    required int otherUserId,
  }) async {
    final db = await _databaseHelper.database;
    await _validateTripConversation(
      executor: db,
      tripId: tripId,
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS unread_count '
      'FROM messages '
      'WHERE trip_id   = ? '
      '  AND receiver_id = ? '
      '  AND sender_id   = ? '
      '  AND is_read     = 0',
      [tripId, currentUserId, otherUserId],
    );
    return rows.first['unread_count'] as int? ?? 0;
  }

  // =========================================================================
  // 7. getMessageById
  //
  // Loads a single message by its ID.
  // Used by notification navigation to resolve conversation participants.
  // =========================================================================

  Future<Message?> getMessageById(int messageId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    return rows.isEmpty ? null : Message.fromMap(rows.first);
  }
}
