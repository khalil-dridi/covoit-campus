import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/widgets/notifications/notification_dropdown.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('dropdown shows the authenticated user\'s newest notifications',
      (WidgetTester tester) async {
    final database = await DatabaseHelper.instance.database;
    final uniqueId = DateTime.now().microsecondsSinceEpoch;
    final user = User(
      id: 900000 + uniqueId,
      fullName: 'Test User',
      email: 'notification-dropdown-$uniqueId@test.tn',
      passwordHash: 'test-password',
      role: 'passenger',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    await database.insert('users', user.toMap());
    await database.insert('notifications', {
      'user_id': user.id,
      'title': 'Ancienne notification',
      'body': 'Cette notification doit apparaître après la plus récente.',
      'type': null,
      'is_read': 1,
      'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    });
    await database.insert('notifications', {
      'user_id': user.id,
      'title': 'Nouvelle demande de réservation',
      'body': 'Un passager a demandé 1 place.',
      'type': 'booking:12;trip:34',
      'is_read': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    addTearDown(() async {
      await database.delete(
        'notifications',
        where: 'user_id = ?',
        whereArgs: [user.id],
      );
      await database.delete('users', where: 'id = ?', whereArgs: [user.id]);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationDropdown(
            user: user,
            layerLink: LayerLink(),
            onClose: () {},
            onViewAll: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Nouvelle demande de réservation'), findsOneWidget);
    expect(find.text('Voir toutes les notifications →'), findsOneWidget);
    expect(find.byType(Scrollbar), findsOneWidget);

    final itemOrders = tester.widgetList<Text>(find.text('Nouvelle demande de réservation'));
    expect(itemOrders, isNotEmpty);
    expect(find.text('Ancienne notification'), findsOneWidget);
  });
}
