import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise SQLite au démarrage de l'application.
  // Cela permet d'exécuter automatiquement les migrations
  // et de créer le compte Admin par défaut.
  await DatabaseHelper.instance.database;

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