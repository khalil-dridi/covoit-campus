import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  static void notifyChanged() => changes.value++;

  Future<List<AppNotification>> getNotificationsForUser(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(AppNotification.fromMap).toList(growable: false);
  }

  Future<int> getUnreadCount(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS unread_count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return rows.first['unread_count'] as int? ?? 0;
  }

  Future<void> markAsRead({
    required int notificationId,
    required int userId,
  }) async {
    final db = await _databaseHelper.database;
    final updated = await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ? AND user_id = ?',
      whereArgs: [notificationId, userId],
    );
    if (updated > 0) notifyChanged();
  }

  static Future<void> insertInTransaction({
    required Transaction transaction,
    required int userId,
    required String title,
    required String body,
    required String type,
    required String createdAt,
  }) async {
    await transaction.insert('notifications', {
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': 0,
      'created_at': createdAt,
    });
  }
}
