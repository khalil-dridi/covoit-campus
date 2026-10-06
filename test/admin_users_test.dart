import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:covoit_campus/database/database_helper.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/repositories/user_repository.dart';
import 'package:covoit_campus/screens/admin/admin_shell.dart';
import 'package:covoit_campus/screens/admin/users/admin_users_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('UserRepository Admin Operations', () {
    final repository = UserRepository();

    test('getAllUsers, getAdminUserStats, and self-protection check', () async {
      final db = await DatabaseHelper.instance.database;
      final unique = DateTime.now().microsecondsSinceEpoch;

      final testUser = User(
        fullName: 'Test Unit User $unique',
        email: 'test-unit-$unique@covoitcampus.tn',
        passwordHash: 'dummy',
        role: 'passenger',
        isVerified: false,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final insertedId = await db.insert('users', testUser.toMap());

      addTearDown(() async {
        await db.delete('users', where: 'id = ?', whereArgs: [insertedId]);
      });

      // 1. getAllUsers
      final users = await repository.getAllUsers();
      expect(users.any((u) => u.id == insertedId), isTrue);

      // 2. getAdminUserStats
      final stats = await repository.getAdminUserStats();
      expect(stats.totalUsers, greaterThan(0));
      expect(stats.passengerCount, greaterThan(0));

      // 3. Activity counts
      final counts = await repository.getUserActivityCounts(insertedId);
      expect(counts.containsKey('vehicles'), isTrue);
      expect(counts.containsKey('trips'), isTrue);
      expect(counts.containsKey('bookings'), isTrue);

      // 4. setUserActiveStatus to false
      await repository.setUserActiveStatus(insertedId, false);
      final listAfterDeactivation = await repository.getAllUsers();
      final deactivatedUser =
          listAfterDeactivation.firstWhere((u) => u.id == insertedId);
      expect(deactivatedUser.isActive, isFalse);

      // 5. setUserActiveStatus to true
      await repository.setUserActiveStatus(insertedId, true);
      final listAfterReactivation = await repository.getAllUsers();
      final reactivatedUser =
          listAfterReactivation.firstWhere((u) => u.id == insertedId);
      expect(reactivatedUser.isActive, isTrue);

      // 6. Admin self-protection: cannot deactivate self
      expect(
        () => repository.setUserActiveStatus(
          insertedId,
          false,
          adminId: insertedId,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AdminUsersScreen Widget Tests', () {
    testWidgets('renders AdminUsersScreen directly with real SQLite data',
        (tester) async {
      final db = await DatabaseHelper.instance.database;
      final adminRow = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: ['admin@covoitcampus.tn'],
        limit: 1,
      );
      final admin = User.fromMap(adminRow.first);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminUsersScreen(admin: admin),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 600));
      });
      await tester.pump();

      // Check header and widgets
      expect(find.byType(AdminUsersScreen), findsOneWidget);
      expect(find.text('Utilisateurs'), findsOneWidget);
      expect(find.text('Gestion des comptes et des rôles'), findsOneWidget);
      expect(find.text('Tous les rôles'), findsOneWidget);
      expect(find.text('Tous les statuts'), findsOneWidget);

      // Admin user card should have 'Vous' badge
      expect(find.text('Vous'), findsOneWidget);

      // Check stats cards are rendered
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Passagers'), findsWidgets);
      expect(find.text('Conducteurs'), findsWidgets);
      expect(find.text('Actifs'), findsWidgets);
      expect(find.text('En attente'), findsOneWidget);
    });

    testWidgets('AdminShell integrates AdminUsersScreen at tab 1',
        (tester) async {
      final db = await DatabaseHelper.instance.database;
      final adminRow = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: ['admin@covoitcampus.tn'],
        limit: 1,
      );
      final admin = User.fromMap(adminRow.first);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(user: admin),
        ),
      );

      await tester.pump();

      // AdminShell must contain AdminUsersScreen in IndexedStack
      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.byType(AdminUsersScreen), findsOneWidget);
    });
  });
}
