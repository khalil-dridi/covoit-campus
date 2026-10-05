class Trip {
  final int id;
  final String departure;
  final String destination;
  final String departureDate;
  final String departureTime;
  final int availableSeats;
  final double price;
  final String driverName;
  final bool driverIsVerified;
  final String? driverProfileImage;
  final double? driverRating;

  const Trip({
    required this.id,
    required this.departure,
    required this.destination,
    required this.departureDate,
    required this.departureTime,
    required this.availableSeats,
    required this.price,
    required this.driverName,
    required this.driverIsVerified,
    this.driverProfileImage,
    this.driverRating,
  });

  factory Trip.fromMap(Map<String, Object?> map) {
    final rating = map['driver_rating'];

    return Trip(
      id: map['id'] as int,
      departure: map['departure'] as String,
      destination: map['destination'] as String,
      departureDate: map['departure_date'] as String,
      departureTime: map['departure_time'] as String,
      availableSeats: map['available_seats'] as int,
      price: (map['price'] as num).toDouble(),
      driverName: map['driver_name'] as String,
      driverIsVerified: map['driver_is_verified'] == 1,
      driverProfileImage: map['driver_profile_image'] as String?,
      driverRating: rating == null ? null : (rating as num).toDouble(),
    );
  }
}