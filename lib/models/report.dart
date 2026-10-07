class Report {
  final int id;
  final int reporterId;
  final int? reportedUserId;
  final int? tripId;
  final String reason;
  final String? description;
  final String status;
  final String createdAt;
  final String? reporterName;
  final String? reporterEmail;
  final String? reportedUserName;
  final String? reportedUserEmail;
  final String? tripDeparture;
  final String? tripDestination;
  final String? tripDate;
  final String? tripTime;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.tripId,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    this.reporterName,
    this.reporterEmail,
    this.reportedUserName,
    this.reportedUserEmail,
    this.tripDeparture,
    this.tripDestination,
    this.tripDate,
    this.tripTime,
  });

  factory Report.fromMap(Map<String, Object?> map) => Report(
    id: map['id'] as int,
    reporterId: map['reporter_id'] as int,
    reportedUserId: map['reported_user_id'] as int?,
    tripId: map['trip_id'] as int?,
    reason: map['reason'] as String? ?? '',
    description: map['description'] as String?,
    status: map['status'] as String? ?? 'pending',
    createdAt: map['created_at'] as String? ?? '',
    reporterName: map['reporter_name'] as String?,
    reporterEmail: map['reporter_email'] as String?,
    reportedUserName: map['reported_user_name'] as String?,
    reportedUserEmail: map['reported_user_email'] as String?,
    tripDeparture: map['trip_departure'] as String?,
    tripDestination: map['trip_destination'] as String?,
    tripDate: map['trip_date'] as String?,
    tripTime: map['trip_time'] as String?,
  );
}

class ReportCounts {
  final int total;
  final int pending;
  final int reviewed;
  final int resolved;

  const ReportCounts({
    required this.total,
    required this.pending,
    required this.reviewed,
    required this.resolved,
  });
}
