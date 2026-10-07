import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/repositories/message_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('ride request messages use the request context with participant checks', () async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final unique = now.microsecondsSinceEpoch;
    final driverId = await _insertUser(db, 'driver', unique, 'driver');
    final passengerId = await _insertUser(db, 'passenger', unique, 'passenger');
    final otherDriverId = await _insertUser(
      db,
      'other-driver',
      unique,
      'driver',
    );
    final outsiderPassengerId = await _insertUser(
      db,
      'outsider-passenger',
      unique,
      'passenger',
    );
    final requestDate =
        '${now.add(const Duration(days: 2)).year.toString().padLeft(4, '0')}-'
        '${now.add(const Duration(days: 2)).month.toString().padLeft(2, '0')}-'
        '${now.add(const Duration(days: 2)).day.toString().padLeft(2, '0')}';
    final requestId = await db.insert('ride_requests', {
      'passenger_id': passengerId,
      'departure': 'Tunis',
      'destination': 'Sousse',
      'request_date': requestDate,
      'request_time': '09:00',
      'seats_requested': 1,
      'description': null,
      'status': 'active',
      'created_at': nowIso,
      'updated_at': nowIso,
    });
    final vehicleId = await db.insert('vehicles', {
      'user_id': driverId,
      'brand': 'Test brand',
      'model': 'Test model',
      'color': 'Blue',
      'license_plate': 'TEST-$unique',
      'seats': 4,
      'created_at': nowIso,
    });
    final tripId = await db.insert('trips', {
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'departure': 'Tunis',
      'destination': 'Sousse',
      'departure_date': requestDate,
      'departure_time': '09:00',
      'total_seats': 4,
      'available_seats': 3,
      'price': 5.0,
      'meeting_point': 'Campus',
      'description': null,
      'status': 'available',
      'created_at': nowIso,
      'updated_at': nowIso,
    });
    await db.insert('bookings', {
      'trip_id': tripId,
      'passenger_id': passengerId,
      'seats_reserved': 1,
      'status': 'accepted',
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    addTearDown(() async {
      await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
      await db.delete('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
      await db.delete('ride_requests', where: 'id = ?', whereArgs: [requestId]);
      await db.delete(
        'users',
        where: 'id IN (?, ?, ?, ?)',
        whereArgs: [driverId, passengerId, otherDriverId, outsiderPassengerId],
      );
    });

    final repository = MessageRepository();
    final emptyDriverConversation = await repository.getRideRequestConversation(
      rideRequestId: requestId,
      currentUserId: driverId,
      otherUserId: passengerId,
    );
    expect(emptyDriverConversation, isEmpty);

    await repository.sendMessage(
      tripId: tripId,
      senderId: passengerId,
      receiverId: driverId,
      message: 'Bonjour, je confirme la réservation.',
    );
    final tripConversation = await repository.getConversation(
      tripId: tripId,
      currentUserId: driverId,
      otherUserId: passengerId,
    );
    expect(tripConversation, hasLength(1));
    expect(tripConversation.single.tripId, tripId);
    expect(tripConversation.single.rideRequestId, isNull);

    final driverMessageId = await repository.sendRideRequestMessage(
      rideRequestId: requestId,
      senderId: driverId,
      otherUserId: passengerId,
      message: 'Bonjour, je peux vous conduire.',
    );
    final driverConversation = await repository.getRideRequestConversation(
      rideRequestId: requestId,
      currentUserId: driverId,
      otherUserId: passengerId,
    );
    expect(driverConversation, hasLength(1));
    expect(driverConversation.single.tripId, isNull);
    expect(driverConversation.single.rideRequestId, requestId);

    final passengerConversation = await repository.getRideRequestConversation(
      rideRequestId: requestId,
      currentUserId: passengerId,
      otherUserId: driverId,
    );
    expect(passengerConversation.single.id, driverMessageId);

    await repository.sendRideRequestMessage(
      rideRequestId: requestId,
      senderId: passengerId,
      otherUserId: driverId,
      message: 'Merci, à quelle heure partez-vous ?',
    );
    final passengerUnread = await repository.getUnreadMessageCount(driverId);
    expect(passengerUnread, 2);
    expect(
      await repository.getUnreadCountForRideRequestConversation(
        rideRequestId: requestId,
        currentUserId: driverId,
        otherUserId: passengerId,
      ),
      1,
    );
    await repository.markRideRequestConversationAsRead(
      rideRequestId: requestId,
      currentUserId: driverId,
      otherUserId: passengerId,
    );
    expect(
      await repository.getUnreadCountForRideRequestConversation(
        rideRequestId: requestId,
        currentUserId: driverId,
        otherUserId: passengerId,
      ),
      0,
    );
    final summaries = await repository.getConversationsForUser(driverId);
    expect(summaries, hasLength(2));
    final requestSummary = summaries.singleWhere((item) => item.isRideRequest);
    final tripSummary = summaries.singleWhere((item) => !item.isRideRequest);
    expect(requestSummary.rideRequestId, requestId);
    expect(requestSummary.tripId, isNull);
    expect(requestSummary.tripDeparture, 'Tunis');
    expect(requestSummary.lastMessage, 'Merci, à quelle heure partez-vous ?');
    expect(tripSummary.tripId, tripId);
    expect(tripSummary.rideRequestId, isNull);
    expect(tripSummary.lastMessage, 'Bonjour, je confirme la réservation.');

    final notifications = await db.query(
      'notifications',
      where: 'user_id IN (?, ?) AND type LIKE ?',
      whereArgs: [driverId, passengerId, '%request:$requestId'],
    );
    expect(notifications, hasLength(2));

    expect(
      await repository.getRideRequestConversation(
        rideRequestId: requestId,
        currentUserId: otherDriverId,
        otherUserId: passengerId,
      ),
      isEmpty,
    );
    await expectLater(
      repository.getRideRequestConversation(
        rideRequestId: requestId,
        currentUserId: outsiderPassengerId,
        otherUserId: driverId,
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.sendRideRequestMessage(
        rideRequestId: requestId,
        senderId: driverId,
        otherUserId: otherDriverId,
        message: 'Unauthorized receiver',
      ),
      throwsA(isA<StateError>()),
    );

    await db.update(
      'ride_requests',
      {'status': 'cancelled'},
      where: 'id = ?',
      whereArgs: [requestId],
    );
    await expectLater(
      repository.sendRideRequestMessage(
        rideRequestId: requestId,
        senderId: driverId,
        otherUserId: passengerId,
        message: 'This should fail',
      ),
      throwsA(isA<StateError>()),
    );

    final messageColumns = await db.rawQuery('PRAGMA table_info(messages)');
    final columns = messageColumns.map((row) => row['name']).toSet();
    expect(columns, containsAll(['trip_id', 'ride_request_id']));
    expect(
      messageColumns.singleWhere((row) => row['name'] == 'trip_id')['notnull'],
      0,
    );
    final foreignKeys = await db.rawQuery('PRAGMA foreign_key_list(messages)');
    expect(foreignKeys.any((row) => row['table'] == 'ride_requests'), isTrue);
  });
}

Future<int> _insertUser(
  DatabaseExecutor db,
  String prefix,
  int unique,
  String role,
) => db.insert('users', {
  'full_name': '$prefix $unique',
  'email': '$prefix-$unique@request-messaging.test',
  'password_hash': 'test-hash',
  'role': role,
  'is_verified': 1,
  'is_active': 1,
  'created_at': DateTime.now().toIso8601String(),
  'updated_at': DateTime.now().toIso8601String(),
});
