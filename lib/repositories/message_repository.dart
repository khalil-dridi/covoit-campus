import 'package:flutter/foundation.dart';

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
  final int tripId;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final String tripDeparture;
  final String tripDestination;
  final String lastMessage;
  final String lastMessageAt;
  final int unreadCount;

  const ConversationSummary({
    required this.tripId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    required this.tripDeparture,
    required this.tripDestination,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationSummary.fromMap(Map<String, Object?> map) =>
      ConversationSummary(
        tripId: map['trip_id'] as int,
        otherUserId: map['other_user_id'] as int,
        otherUserName: map['other_user_name'] as String,
        otherUserImage: map['other_user_image'] as String?,
        tripDeparture: map['trip_departure'] as String,
        tripDestination: map['trip_destination'] as String,
        lastMessage: map['last_message'] as String,
        lastMessageAt: map['last_message_at'] as String,
        unreadCount: map['unread_count'] as int? ?? 0,
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
          'L\'expéditeur et le destinataire doivent être différents.');
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
            'Impossible d\'envoyer un message pour un trajet annulé.');
      }

      // 2. Sender must exist and be active.
      final senderRows = await txn.query(
        'users',
        columns: ['id', 'full_name', 'is_active'],
        where: 'id = ? AND is_active = 1',
        whereArgs: [senderId],
        limit: 1,
      );
      if (senderRows.isEmpty) {
        throw StateError('Le compte expéditeur est invalide ou désactivé.');
      }
      final senderName = senderRows.first['full_name'] as String;

      // 3. Receiver must exist and be active.
      final receiverRows = await txn.query(
        'users',
        columns: ['id', 'is_active'],
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
    final rows = await db.rawQuery(
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
  }

  // =========================================================================
  // 3. getConversationsForUser
  //
  // Returns one ConversationSummary per distinct (trip_id, other_user_id)
  // pair, enriched with trip route, last message, and unread count.
  // Sorted newest-first.
  // =========================================================================

  Future<List<ConversationSummary>> getConversationsForUser(
    int userId,
  ) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        conv.trip_id,
        conv.other_user_id,
        other_users.full_name     AS other_user_name,
        other_users.profile_image AS other_user_image,
        trips.departure           AS trip_departure,
        trips.destination         AS trip_destination,
        latest.message            AS last_message,
        latest.created_at         AS last_message_at,
        COALESCE(
          (
            SELECT COUNT(*)
            FROM messages AS unread_msgs
            WHERE unread_msgs.trip_id     = conv.trip_id
              AND unread_msgs.receiver_id = ?
              AND unread_msgs.sender_id   = conv.other_user_id
              AND unread_msgs.is_read     = 0
          ), 0
        ) AS unread_count
      FROM (
        SELECT DISTINCT
          trip_id,
          CASE
            WHEN sender_id   = ? THEN receiver_id
            WHEN receiver_id = ? THEN sender_id
          END AS other_user_id
        FROM messages
        WHERE sender_id = ? OR receiver_id = ?
      ) AS conv
      INNER JOIN trips
        ON trips.id = conv.trip_id
      INNER JOIN users AS other_users
        ON other_users.id = conv.other_user_id
      INNER JOIN messages AS latest
        ON latest.id = (
          SELECT id
          FROM messages
          WHERE trip_id = conv.trip_id
            AND (
                  (sender_id = ? AND receiver_id = conv.other_user_id)
               OR (sender_id = conv.other_user_id AND receiver_id = ?)
                )
          ORDER BY created_at DESC, id DESC
          LIMIT 1
        )
      ORDER BY latest.created_at DESC, latest.id DESC
      ''',
      [
        userId, userId, userId, userId, userId, userId, userId,
      ],
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
    final updated = await db.update(
      'messages',
      {'is_read': 1},
      where:
          'trip_id = ? AND receiver_id = ? AND sender_id = ? AND is_read = 0',
      whereArgs: [tripId, currentUserId, otherUserId],
    );
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
