import 'package:flutter/material.dart';

import 'models/user.dart';
import 'screens/driver/driver_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DriverShell(
        user: User(
          id: 1,
          fullName: 'Conducteur Démo',
          email: 'preview@example.invalid',
          passwordHash: '',
          role: 'driver',
          isVerified: true,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ),
    ),
  );
}
