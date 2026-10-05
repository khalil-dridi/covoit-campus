import '../database/database_helper.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';
import 'driver_profile_repository.dart';
import 'vehicle_repository.dart';

class DriverBookingRequest {
  final String passengerName;
  final String? passengerImage;
  final int seatsRequested;
  final String departure;
  final String destination;
  final String status;

  const DriverBookingRequest({
    required this.passengerName,
    required this.passengerImage,
    required this.seatsRequested,
    required this.departure,
    required this.destination,
    required this.status,
  });

  factory DriverBookingRequest.fromMap(Map<String, Object?> map) =>
      DriverBookingRequest(
        passengerName: map['passenger_name'] as String,
        passengerImage: map['passenger_image'] as String?,
        seatsRequested: map['seats_reserved'] as int,
        departure: map['departure'] as String,
        destination: map['destination'] as String,
        status: map['status'] as String,
      );
}

class DriverActivityItem {
  final String title;
  final String detail;
  final String createdAt;

  const DriverActivityItem({
    required this.title,
    required this.detail,
    required this.createdAt,
  });

  factory DriverActivityItem.fromMap(Map<String, Object?> map) =>
      DriverActivityItem(
        title: map['title'] as String,
        detail: map['detail'] as String,
        createdAt: map['created_at'] as String,
      );
}

class DriverHomeData {
  final int activeTrips;
  final int reservedSeats;
  final int pendingRequests;
  final DriverProfileStats stats;
  final Trip? nextTrip;
  final int? nextTripPendingBookings;
  final List<DriverBookingRequest> requests;
  final List<DriverActivityItem> recentActivity;
  final Vehicle? vehicle;

  const DriverHomeData({
    required this.activeTrips,
    required this.reservedSeats,
    required this.pendingRequests,
    required this.stats,
    required this.nextTrip,
    required this.nextTripPendingBookings,
    required this.requests,
    required this.recentActivity,
    required this.vehicle,
  });
}

class DriverHomeRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final DriverProfileRepository _profileRepository = DriverProfileRepository();
  final VehicleRepository _vehicleRepository = VehicleRepository();

  Future<DriverHomeData> getHomeData(int driverId) async {
    final db = await _databaseHelper.database;
    final today = DateTime.now();
    final todayString =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final results = await Future.wait<Object?>([
      db.rawQuery(
        "SELECT COUNT(*) AS count FROM trips "
        "WHERE driver_id = ? AND status = 'available' "
        'AND available_seats > 0 AND departure_date >= ?',
        [driverId, todayString],
      ),
      db.rawQuery(
        "SELECT COALESCE(SUM(total_seats - available_seats), 0) AS count "
        "FROM trips WHERE driver_id = ? AND status = 'available' "
        'AND departure_date >= ?',
        [driverId, todayString],
      ),
      db.rawQuery(
        "SELECT COUNT(*) AS count FROM bookings "
        "INNER JOIN trips ON trips.id = bookings.trip_id "
        "WHERE trips.driver_id = ? AND bookings.status = 'pending' "
        'AND trips.departure_date >= ?',
        [driverId, todayString],
      ),
      _getNextTrip(driverId, todayString),
      _getPendingRequests(driverId, todayString),
      _getRecentActivity(driverId),
      _profileRepository.getStats(driverId),
      _vehicleRepository.getVehicleForUser(driverId),
    ]);

    final upcomingRows = results[3] as List<Map<String, Object?>>;
    final upcomingTrip = upcomingRows.isEmpty ? null : _tripFromMap(upcomingRows.first);
    final pendingForNext = upcomingRows.isEmpty
        ? null
        : upcomingRows.first['pending_bookings'] as int? ?? 0;

    return DriverHomeData(
      activeTrips: results[0].asList.first['count'] as int? ?? 0,
      reservedSeats: results[1].asList.first['count'] as int? ?? 0,
      pendingRequests: results[2].asList.first['count'] as int? ?? 0,
      nextTrip: upcomingTrip,
      nextTripPendingBookings: pendingForNext,
      requests: (results[4] as List<Map<String, Object?>>)
          .map(DriverBookingRequest.fromMap)
          .toList(growable: false),
      recentActivity: (results[5] as List<Map<String, Object?>>)
          .map(DriverActivityItem.fromMap)
          .toList(growable: false),
      stats: results[6] as DriverProfileStats,
      vehicle: results[7] as Vehicle?,
    );
  }

  Future<List<Map<String, Object?>>> _getNextTrip(
    int driverId,
    String today,
  ) async {
    final db = await _databaseHelper.database;
    return db.rawQuery('''
      SELECT
        trips.id,
        trips.driver_id,
        trips.vehicle_id,
        trips.departure,
        trips.destination,
        trips.departure_date,
        trips.departure_time,
        trips.total_seats,
        trips.available_seats,
        trips.price,
        trips.meeting_point,
        trips.description,
        trips.status,
        trips.created_at,
        trips.updated_at,
        drivers.full_name AS driver_name,
        drivers.is_verified AS driver_is_verified,
        drivers.profile_image AS driver_profile_image,
        NULL AS driver_rating,
        (SELECT COUNT(*) FROM bookings
          WHERE bookings.trip_id = trips.id
          AND bookings.status = 'pending') AS pending_bookings
      FROM trips
      INNER JOIN users AS drivers ON drivers.id = trips.driver_id
      WHERE trips.driver_id = ?
        AND trips.departure_date >= ?
        AND trips.status = 'available'
      ORDER BY trips.departure_date ASC, trips.departure_time ASC
      LIMIT 1
    ''', [driverId, today]);
  }

  Future<List<Map<String, Object?>>> _getPendingRequests(
    int driverId,
    String today,
  ) async {
    final db = await _databaseHelper.database;
    return db.rawQuery('''
      SELECT
        passengers.full_name AS passenger_name,
        passengers.profile_image AS passenger_image,
        bookings.seats_reserved,
        trips.departure,
        trips.destination,
        bookings.status
      FROM bookings
      INNER JOIN trips ON trips.id = bookings.trip_id
      INNER JOIN users AS passengers ON passengers.id = bookings.passenger_id
      WHERE trips.driver_id = ?
        AND bookings.status = 'pending'
        AND trips.departure_date >= ?
      ORDER BY bookings.created_at DESC
      LIMIT 3
    ''', [driverId, today]);
  }

  Future<List<Map<String, Object?>>> _getRecentActivity(int driverId) async {
    final db = await _databaseHelper.database;
    return db.rawQuery('''
      SELECT title, detail, created_at FROM (
        SELECT
          'Trajet publié' AS title,
          departure || ' → ' || destination AS detail,
          created_at
        FROM trips
        WHERE driver_id = ?
        UNION ALL
        SELECT
          CASE bookings.status
            WHEN 'pending' THEN 'Nouvelle demande de réservation'
            ELSE 'Réservation mise à jour'
          END AS title,
          passengers.full_name || ' · ' || bookings.seats_reserved ||
            CASE WHEN bookings.seats_reserved = 1 THEN ' place' ELSE ' places' END AS detail,
          bookings.created_at
        FROM bookings
        INNER JOIN trips ON trips.id = bookings.trip_id
        INNER JOIN users AS passengers ON passengers.id = bookings.passenger_id
        WHERE trips.driver_id = ?
      )
      ORDER BY created_at DESC
      LIMIT 4
    ''', [driverId, driverId]);
  }

  Trip _tripFromMap(Map<String, Object?> map) => Trip.fromMap(map);
}

extension on Object? {
  List<Map<String, Object?>> get asList =>
      this! as List<Map<String, Object?>>;
}
