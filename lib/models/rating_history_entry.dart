import 'rating.dart';

class RatingHistoryEntry {
  final Rating rating;
  final String? otherUserName;
  final String? otherUserProfileImage;
  final String? departure;
  final String? destination;
  final String? departureDate;

  const RatingHistoryEntry({
    required this.rating,
    this.otherUserName,
    this.otherUserProfileImage,
    this.departure,
    this.destination,
    this.departureDate,
  });

  factory RatingHistoryEntry.fromMap(Map<String, Object?> map) =>
      RatingHistoryEntry(
        rating: Rating.fromMap(map),
        otherUserName: map['other_user_name'] as String?,
        otherUserProfileImage: map['other_user_profile_image'] as String?,
        departure: map['departure'] as String?,
        destination: map['destination'] as String?,
        departureDate: map['departure_date'] as String?,
      );
}
