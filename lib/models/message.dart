class Message {
  final int? id;
  final int? tripId;
  final int? rideRequestId;
  final int senderId;
  final int receiverId;
  final String message;
  final bool isRead;
  final String createdAt;

  const Message({
    this.id,
    required this.tripId,
    this.rideRequestId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  }) : assert((tripId != null) != (rideRequestId != null));

  factory Message.fromMap(Map<String, Object?> map) => Message(
    id: map['id'] as int?,
    tripId: map['trip_id'] as int?,
    rideRequestId: map['ride_request_id'] as int?,
    senderId: map['sender_id'] as int,
    receiverId: map['receiver_id'] as int,
    message: map['message'] as String,
    isRead: map['is_read'] == 1,
    createdAt: map['created_at'] as String,
  );

  Map<String, Object?> toMap() => {
    'trip_id': tripId,
    'ride_request_id': rideRequestId,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'message': message,
    'is_read': isRead ? 1 : 0,
    'created_at': createdAt,
  };
}
