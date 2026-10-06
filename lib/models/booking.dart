class Booking {
  final int? id;
  final int tripId;
  final int passengerId;
  final int seatsReserved;
  final String status;
  final String createdAt;
  final String updatedAt;

  const Booking({
    this.id,
    required this.tripId,
    required this.passengerId,
    required this.seatsReserved,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromMap(Map<String, Object?> map) => Booking(
        id: map['id'] as int?,
        tripId: map['trip_id'] as int,
        passengerId: map['passenger_id'] as int,
        seatsReserved: map['seats_reserved'] as int,
        status: map['status'] as String? ?? 'pending',
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'trip_id': tripId,
        'passenger_id': passengerId,
        'seats_reserved': seatsReserved,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
