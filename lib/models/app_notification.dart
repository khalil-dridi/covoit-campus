class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, Object?> map) => AppNotification(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        title: map['title'] as String,
        body: map['body'] as String,
        type: map['type'] as String?,
        isRead: map['is_read'] == 1,
        createdAt: map['created_at'] as String,
      );
}
