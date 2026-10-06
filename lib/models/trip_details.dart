class TripDetails {
  final int id;
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
  final String driverName;
  final bool driverIsVerified;
  final String? driverProfileImage;
  final double? driverRating;
  final int reviewCount;
  final int pendingRequests;
  final String vehicleBrand;
  final String vehicleModel;
  final String? vehicleColor;
  final int vehicleSeats;

  const TripDetails({
    required this.id,
    required this.departure,
    required this.destination,
    required this.departureDate,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.price,
    required this.meetingPoint,
    required this.description,
    required this.status,
    required this.driverName,
    required this.driverIsVerified,
    required this.driverProfileImage,
    required this.driverRating,
    required this.reviewCount,
    this.pendingRequests = 0,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehicleSeats,
  });

  factory TripDetails.fromMap(Map<String, Object?> map) {
    final rating = map['driver_rating'];
    return TripDetails(
      id: map['id'] as int,
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
      driverName: map['driver_name'] as String,
      driverIsVerified: map['driver_is_verified'] == 1,
      driverProfileImage: map['driver_profile_image'] as String?,
      driverRating: rating == null ? null : (rating as num).toDouble(),
      reviewCount: map['review_count'] as int? ?? 0,
      pendingRequests: map['pending_requests'] as int? ?? 0,
      vehicleBrand: map['vehicle_brand'] as String,
      vehicleModel: map['vehicle_model'] as String,
      vehicleColor: map['vehicle_color'] as String?,
      vehicleSeats: map['vehicle_seats'] as int,
    );
  }
}