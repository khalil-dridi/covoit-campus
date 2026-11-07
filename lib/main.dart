import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'database/database_helper.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (error, stackTrace) {
    // Firebase failures should not block the existing local login flow.
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  await initializeDateFormatting('fr_FR');

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
