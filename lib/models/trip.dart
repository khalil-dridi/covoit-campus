class Trip {
  final int? id;
  final int driverId;
  final int vehicleId;
  final String departure;
  final String destination;
  final String departureDate;
  final String departureTime;
  final int totalSeats;
  final int availableSeats;
  final double price;
  final String meetingPoint;
  final String? description;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String driverName;
  final bool driverIsVerified;
  final String? driverProfileImage;
  final double? driverRating;

  const Trip({
    this.id,
    required this.driverId,
    required this.vehicleId,
    required this.departure,
    required this.destination,
    required this.departureDate,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.price,
    this.meetingPoint = '',
    this.description,
    this.status = 'available',
    required this.createdAt,
    required this.updatedAt,
    this.driverName = '',
    this.driverIsVerified = false,
    this.driverProfileImage,
    this.driverRating,
  });

  factory Trip.fromMap(Map<String, Object?> map) {
    final rating = map['driver_rating'];

    return Trip(
      id: map['id'] as int?,
      driverId: map['driver_id'] as int,
      vehicleId: map['vehicle_id'] as int,
      departure: map['departure'] as String,
      destination: map['destination'] as String,
      departureDate: map['departure_date'] as String,
      departureTime: map['departure_time'] as String,
      totalSeats: map['total_seats'] as int,
      availableSeats: map['available_seats'] as int,
      price: (map['price'] as num).toDouble(),
      meetingPoint: map['meeting_point'] as String? ?? '',
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'available',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
      driverName: map['driver_name'] as String? ?? '',
      driverIsVerified: map['driver_is_verified'] == 1,
      driverProfileImage: map['driver_profile_image'] as String?,
      driverRating: rating == null ? null : (rating as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() => {
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'departure': departure,
        'destination': destination,
        'departure_date': departureDate,
        'departure_time': departureTime,
        'total_seats': totalSeats,
        'available_seats': availableSeats,
        'price': price,
        'meeting_point': meetingPoint,
        'description': description,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}