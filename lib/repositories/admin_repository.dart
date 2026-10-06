import '../database/database_helper.dart';

// =============================================================================
// AdminStats
//
// A single value-object that holds all dashboard counts.
// Loaded in one batched call to minimise DB round-trips.
// =============================================================================

class AdminStats {
  final int totalUsers;
  final int passengerCount;
  final int driverCount;
  final int totalTrips;
  final int availableTrips;
  final int cancelledTrips;
  final int completedTrips;
  final int totalBookings;
  final int pendingBookings;
  final int acceptedBookings;
  final int totalReports;
  final int pendingReports;

  const AdminStats({
    required this.totalUsers,
    required this.passengerCount,
    required this.driverCount,
    required this.totalTrips,
    required this.availableTrips,
    required this.cancelledTrips,
    required this.completedTrips,
    required this.totalBookings,
    required this.pendingBookings,
    required this.acceptedBookings,
    required this.totalReports,
    required this.pendingReports,
  });
}

// =============================================================================
// AdminRepository
// =============================================================================

class AdminRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // loadStats
  //
  // Runs all aggregate COUNT queries in parallel via Future.wait.
  // Each query is a simple COUNT over a filtered column — no full table scans.
  // ---------------------------------------------------------------------------

  Future<AdminStats> loadStats() async {
    final db = await _databaseHelper.database;

    final results = await Future.wait<int>([
      // 0 — total active users (exclude soft-deleted)
      _count(db, 'SELECT COUNT(*) FROM users WHERE is_active = 1'),

      // 1 — passengers
      _count(
        db,
        "SELECT COUNT(*) FROM users WHERE role = 'passenger' AND is_active = 1",
      ),

      // 2 — drivers
      _count(
        db,
        "SELECT COUNT(*) FROM users WHERE role = 'driver' AND is_active = 1",
      ),

      // 3 — total trips
      _count(db, 'SELECT COUNT(*) FROM trips'),

      // 4 — available trips
      _count(db, "SELECT COUNT(*) FROM trips WHERE status = 'available'"),

      // 5 — cancelled trips
      _count(db, "SELECT COUNT(*) FROM trips WHERE status = 'cancelled'"),

      // 6 — completed trips
      _count(db, "SELECT COUNT(*) FROM trips WHERE status = 'completed'"),

      // 7 — total bookings
      _count(db, 'SELECT COUNT(*) FROM bookings'),

      // 8 — pending bookings
      _count(db, "SELECT COUNT(*) FROM bookings WHERE status = 'pending'"),

      // 9 — accepted bookings
      _count(db, "SELECT COUNT(*) FROM bookings WHERE status = 'accepted'"),

      // 10 — total reports
      _count(db, 'SELECT COUNT(*) FROM reports'),

      // 11 — pending reports
      _count(db, "SELECT COUNT(*) FROM reports WHERE status = 'pending'"),
    ]);

    return AdminStats(
      totalUsers: results[0],
      passengerCount: results[1],
      driverCount: results[2],
      totalTrips: results[3],
      availableTrips: results[4],
      cancelledTrips: results[5],
      completedTrips: results[6],
      totalBookings: results[7],
      pendingBookings: results[8],
      acceptedBookings: results[9],
      totalReports: results[10],
      pendingReports: results[11],
    );
  }

  // ---------------------------------------------------------------------------
  // _count — runs a single COUNT(*) query and returns the integer result.
  // ---------------------------------------------------------------------------

  Future<int> _count(dynamic db, String sql) async {
    final rows = await db.rawQuery(sql);
    final value = rows.first.values.first;
    return value == null ? 0 : (value as int);
  }
}
