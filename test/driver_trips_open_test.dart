import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/screens/driver/driver_shell.dart';

void main() {
  testWidgets('Driver > Mes trajets opens without a framework assertion',
      (tester) async {
    final user = User(
      id: 1,
      fullName: 'Conducteur Test',
      email: 'driver@test.tn',
      passwordHash: 'x',
      role: 'driver',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DriverShell(user: user),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Mes trajets'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Gérez vos trajets et suivez vos réservations.'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.textContaining('_elements.contains'), findsNothing);
  });
}
