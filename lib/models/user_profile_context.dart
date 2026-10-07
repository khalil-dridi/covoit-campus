enum UserProfileContextType {
  generic,
  trip,
  booking,
  rideRequest,
  conversationTrip,
  conversationRequest,
}

class UserProfileContext {
  final UserProfileContextType type;
  final int? tripId;
  final int? bookingId;
  final int? rideRequestId;
  final String? departure;
  final String? destination;

  const UserProfileContext({
    this.type = UserProfileContextType.generic,
    this.tripId,
    this.bookingId,
    this.rideRequestId,
    this.departure,
    this.destination,
  });

  String get routeLabel => [
    departure,
    destination,
  ].where((part) => part?.trim().isNotEmpty == true).join(' → ');
}
