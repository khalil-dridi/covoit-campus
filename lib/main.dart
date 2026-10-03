import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const CovoitCampusApp());
}

class CovoitCampusApp extends StatelessWidget {
  const CovoitCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Covoit Campus',
      home: const SplashScreen(),
    );
  }
}