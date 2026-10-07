class RideRequest {
  final int? id;
  final int passengerId;
  final String departure;
  final String destination;
  final String requestDate;
  final String? requestTime;
  final int seatsRequested;
  final String? description;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? passengerName;
  final String? passengerImage;

  const RideRequest({
    this.id,
    required this.passengerId,
    required this.departure,
    required this.destination,
    required this.requestDate,
    this.requestTime,
    required this.seatsRequested,
    this.description,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.passengerName,
    this.passengerImage,
  });

  factory RideRequest.fromMap(Map<String, Object?> map) => RideRequest(
    id: map['id'] as int?,
    passengerId: map['passenger_id'] as int,
    departure: map['departure'] as String,
    destination: map['destination'] as String,
    requestDate: map['request_date'] as String,
    requestTime: map['request_time'] as String?,
    seatsRequested: map['seats_requested'] as int,
    description: map['description'] as String?,
    status: map['status'] as String? ?? 'active',
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
    passengerName: map['passenger_name'] as String?,
    passengerImage: map['passenger_image'] as String?,
  );

  Map<String, Object?> toMap() => {
    'passenger_id': passengerId,
    'departure': departure,
    'destination': destination,
    'request_date': requestDate,
    'request_time': requestTime,
    'seats_requested': seatsRequested,
    'description': description,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
