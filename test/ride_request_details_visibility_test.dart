import 'package:covoit_campus/models/ride_request.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/screens/passenger/requests/ride_request_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  const request = RideRequest(
    id: 21,
    passengerId: 10,
    departure: 'Tunis',
    destination: 'Sousse',
    requestDate: '2026-10-10',
    requestTime: '09:00',
    seatsRequested: 2,
    status: 'active',
    createdAt: '2026-10-01T09:00:00.000',
    updatedAt: '2026-10-01T09:00:00.000',
  );

  User user({required int id, required String role, bool isActive = true}) =>
      User(
        id: id,
        fullName: 'Utilisateur test',
        email: 'test@example.com',
        passwordHash: '',
        role: role,
        isActive: isActive,
        createdAt: '2026-10-01T09:00:00.000',
        updatedAt: '2026-10-01T09:00:00.000',
      );

  Future<void> pumpDetails(WidgetTester tester, User currentUser) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RideRequestDetailsScreen(
          request: request,
          currentUser: currentUser,
        ),
      ),
    );
  }

  testWidgets('request owner sees context but no contact action', (
    tester,
  ) async {
    await pumpDetails(tester, user(id: request.passengerId, role: 'passenger'));

    expect(find.text('Votre demande'), findsOneWidget);
    expect(find.text('Contacter le passager'), findsNothing);
  });

  testWidgets('another passenger cannot contact the requester', (tester) async {
    await pumpDetails(tester, user(id: 11, role: 'passenger'));

    expect(find.text('Votre demande'), findsNothing);
    expect(find.text('Contacter le passager'), findsNothing);
  });

  testWidgets('active driver sees contact action', (tester) async {
    await pumpDetails(tester, user(id: 12, role: 'driver'));

    expect(find.text('Contacter le passager'), findsOneWidget);
    expect(find.text('Votre demande'), findsNothing);
  });

  testWidgets('inactive driver does not see contact action', (tester) async {
    await pumpDetails(tester, user(id: 12, role: 'driver', isActive: false));

    expect(find.text('Contacter le passager'), findsNothing);
  });
}
