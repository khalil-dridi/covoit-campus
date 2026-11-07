import 'package:flutter/material.dart';

import '../models/user.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/driver/driver_shell.dart';
import '../screens/passenger/passenger_shell.dart';

Widget? roleShellFor(User user) {
  switch (user.role) {
    case 'passenger':
      return PassengerShell(user: user);
    case 'driver':
      return DriverShell(user: user);
    case 'admin':
      return AdminShell(user: user);
    default:
      return null;
  }
}

bool navigateToRoleShell(BuildContext context, User user) {
  final destination = roleShellFor(user);
  if (destination == null) return false;
  Navigator.of(context).pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(builder: (_) => destination),
    (route) => false,
  );
  return true;
}
