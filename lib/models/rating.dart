class Rating {
  final int? id;
  final int tripId;
  final int reviewerId;
  final int reviewedId;
  final int score;
  final String? comment;
  final String createdAt;

  const Rating({
    this.id,
    required this.tripId,
    required this.reviewerId,
    required this.reviewedId,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  factory Rating.fromMap(Map<String, Object?> map) => Rating(
    id: map['id'] as int?,
    tripId: map['trip_id'] as int,
    reviewerId: map['reviewer_id'] as int,
    reviewedId: map['reviewed_id'] as int,
    score: map['score'] as int,
    comment: map['comment'] as String?,
    createdAt: map['created_at'] as String,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'trip_id': tripId,
    'reviewer_id': reviewerId,
    'reviewed_id': reviewedId,
    'score': score,
    'comment': comment,
    'created_at': createdAt,
  };
}
