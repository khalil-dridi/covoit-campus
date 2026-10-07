class Booking {
  final int? id;
  final int tripId;
  final int passengerId;
  final int seatsReserved;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? departure;
  final String? destination;
  final String? departureDate;
  final String? departureTime;
  final double? pricePerSeat;
  final int? tripAvailableSeats;
  final int? tripTotalSeats;
  final String? tripStatus;
  final String? meetingPoint;
  final String? description;
  final String? driverName;
  final int? driverId;
  final bool? driverIsVerified;
  final String? driverProfileImage;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;
  final int? vehicleSeats;
  final String? passengerName;
  final String? passengerEmail;
  final String? passengerImage;
  final String? passengerUniversity;

  const Booking({
    this.id,
    required this.tripId,
    required this.passengerId,
    required this.seatsReserved,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.departure,
    this.destination,
    this.departureDate,
    this.departureTime,
    this.pricePerSeat,
    this.tripAvailableSeats,
    this.tripTotalSeats,
    this.tripStatus,
    this.meetingPoint,
    this.description,
    this.driverName,
    this.driverId,
    this.driverIsVerified,
    this.driverProfileImage,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleSeats,
    this.passengerName,
    this.passengerEmail,
    this.passengerImage,
    this.passengerUniversity,
  });

  factory Booking.fromMap(Map<String, Object?> map) => Booking(
        id: map['id'] as int?,
        tripId: map['trip_id'] as int,
        passengerId: map['passenger_id'] as int,
        seatsReserved: map['seats_reserved'] as int,
        status: map['status'] as String? ?? 'pending',
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
        departure: map['departure'] as String?,
        destination: map['destination'] as String?,
        departureDate: map['departure_date'] as String?,
        departureTime: map['departure_time'] as String?,
        pricePerSeat: (map['price_per_seat'] as num?)?.toDouble(),
        tripAvailableSeats: map['trip_available_seats'] as int?,
        tripTotalSeats: map['trip_total_seats'] as int?,
        tripStatus: map['trip_status'] as String?,
        meetingPoint: map['meeting_point'] as String?,
        description: map['description'] as String?,
        driverName: map['driver_name'] as String?,
        driverId: map['driver_id'] as int?,
        driverIsVerified: map['driver_is_verified'] == null
            ? null
            : map['driver_is_verified'] == 1,
        driverProfileImage: map['driver_profile_image'] as String?,
        vehicleBrand: map['vehicle_brand'] as String?,
        vehicleModel: map['vehicle_model'] as String?,
        vehicleColor: map['vehicle_color'] as String?,
        vehicleSeats: map['vehicle_seats'] as int?,
        passengerName: map['passenger_name'] as String?,
        passengerEmail: map['passenger_email'] as String?,
        passengerImage: map['passenger_image'] as String?,
        passengerUniversity: map['passenger_university'] as String?,
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
