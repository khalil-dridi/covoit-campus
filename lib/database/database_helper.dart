import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(
      databasePath,
      'covoit_campus.db',
    );

    return await openDatabase(
      path,
      version: 3,

      onConfigure: (db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },

      onCreate: _onCreate,

      onUpgrade: _onUpgrade,
    );
  }

  // ==========================================================
  // CREATE DATABASE
  // ==========================================================

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    // =========================
    // USERS
    // =========================

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        phone TEXT,
        profile_image TEXT,
        university TEXT,
        role TEXT NOT NULL DEFAULT 'passenger',
        is_verified INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // =========================
    // VEHICLES
    // =========================

    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        color TEXT,
        license_plate TEXT NOT NULL,
        seats INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // PREFERENCES
    // =========================

    await db.execute('''
      CREATE TABLE preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        smoking_allowed INTEGER NOT NULL DEFAULT 0,
        pets_allowed INTEGER NOT NULL DEFAULT 0,
        music_allowed INTEGER NOT NULL DEFAULT 1,
        conversation_allowed INTEGER NOT NULL DEFAULT 1,
        preferred_gender TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // TRIPS
    // =========================

    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driver_id INTEGER NOT NULL,
        vehicle_id INTEGER NOT NULL,
        departure TEXT NOT NULL,
        destination TEXT NOT NULL,
        departure_date TEXT NOT NULL,
        departure_time TEXT NOT NULL,
        total_seats INTEGER NOT NULL,
        available_seats INTEGER NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        meeting_point TEXT NOT NULL DEFAULT '',
        description TEXT,
        status TEXT NOT NULL DEFAULT 'available',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (driver_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (vehicle_id)
          REFERENCES vehicles(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // BOOKINGS
    // =========================

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        passenger_id INTEGER NOT NULL,
        seats_reserved INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (trip_id)
          REFERENCES trips(id)
          ON DELETE CASCADE,
        FOREIGN KEY (passenger_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // MESSAGES
    // =========================

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        receiver_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id)
          REFERENCES trips(id)
          ON DELETE CASCADE,
        FOREIGN KEY (sender_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (receiver_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // NOTIFICATIONS
    // =========================

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // RATINGS
    // =========================

    await db.execute('''
      CREATE TABLE ratings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        reviewer_id INTEGER NOT NULL,
        reviewed_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id)
          REFERENCES trips(id)
          ON DELETE CASCADE,
        FOREIGN KEY (reviewer_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (reviewed_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // REPORTS
    // =========================

    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reporter_id INTEGER NOT NULL,
        reported_user_id INTEGER,
        trip_id INTEGER,
        reason TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (reporter_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (reported_user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (trip_id)
          REFERENCES trips(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // EMERGENCY CONTACTS
    // =========================

    await db.execute('''
      CREATE TABLE emergency_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        relationship TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // TRIP SHARES
    // =========================

    await db.execute('''
      CREATE TABLE trip_shares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        contact_id INTEGER NOT NULL,
        shared_at TEXT NOT NULL,
        FOREIGN KEY (trip_id)
          REFERENCES trips(id)
          ON DELETE CASCADE,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (contact_id)
          REFERENCES emergency_contacts(id)
          ON DELETE CASCADE
      )
    ''');

    // =========================
    // DEFAULT ADMIN
    // =========================

    await _createDefaultAdmin(db);
  }

  // ==========================================================
  // DATABASE UPGRADE
  // ==========================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createDefaultAdmin(db);
    }

    if (oldVersion < 3) {
      final columns = await db.rawQuery('PRAGMA table_info(trips)');
      final hasMeetingPoint = columns.any(
        (column) => column['name'] == 'meeting_point',
      );
      if (!hasMeetingPoint) {
        await db.execute(
          "ALTER TABLE trips ADD COLUMN meeting_point TEXT NOT NULL DEFAULT ''",
        );
      }
    }
  }

  // ==========================================================
  // CREATE DEFAULT ADMIN
  // ==========================================================

  Future<void> _createDefaultAdmin(
    Database db,
  ) async {
    final existingAdmin = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [
        'admin@covoitcampus.tn',
      ],
      limit: 1,
    );

    // Admin already exists
    if (existingAdmin.isNotEmpty) {
      return;
    }

    final now = DateTime.now().toIso8601String();

    // SHA-256 of:
    // CovoitAdmin#2026!
    const adminPasswordHash =
        '4678a5d7a919ca64607484fa99faa368699da50437b343e3fcf198e157a682aa';

    await db.insert(
      'users',
      {
        'full_name': 'Administrateur',
        'email': 'admin@covoitcampus.tn',
        'password_hash': adminPasswordHash,
        'phone': null,
        'profile_image': null,
        'university': null,
        'role': 'admin',
        'is_verified': 1,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
    );
  }
}   