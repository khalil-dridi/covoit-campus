import 'package:flutter_test/flutter_test.dart';

import 'package:covoit_campus/auth/auth_navigation.dart';
import 'package:covoit_campus/models/user.dart';
import 'package:covoit_campus/screens/admin/admin_shell.dart';
import 'package:covoit_campus/screens/driver/driver_shell.dart';
import 'package:covoit_campus/screens/passenger/passenger_shell.dart';

void main() {
  User makeUser({
    required String role,
    bool verified = false,
    bool active = true,
  }) => User(
    id: 1,
    fullName: 'Test user',
    email: 'test@example.tn',
    passwordHash: '',
    role: role,
    isVerified: verified,
    isActive: active,
    createdAt: '2026-01-01T00:00:00.000',
    updatedAt: '2026-01-01T00:00:00.000',
  );

  test(
    'active admin reaches AdminShell without Firebase email verification',
    () {
      expect(roleShellFor(makeUser(role: 'admin')), isA<AdminShell>());
    },
  );

  test('inactive admin is denied access to AdminShell', () {
    expect(roleShellFor(makeUser(role: 'admin', active: false)), isNull);
  });

  test('driver and passenger shells still require verified accounts', () {
    expect(roleShellFor(makeUser(role: 'driver')), isNull);
    expect(roleShellFor(makeUser(role: 'passenger')), isNull);
    expect(
      roleShellFor(makeUser(role: 'driver', verified: true)),
      isA<DriverShell>(),
    );
    expect(
      roleShellFor(makeUser(role: 'passenger', verified: true)),
      isA<PassengerShell>(),
    );
  });
}
