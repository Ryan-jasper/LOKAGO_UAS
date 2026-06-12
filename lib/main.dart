import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/auth_gate.dart';
import 'services/database_seed_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const bool shouldSeedDatabase = false;

  if (shouldSeedDatabase) {
    try {
      await DatabaseSeedService.instance.seedAllDatabases();
      debugPrint('Firestore seed success.');
    } catch (e) {
      debugPrint('Firestore seed skipped: $e');
    }
  }

  runApp(const LokagoApp());
}

class LokagoApp extends StatelessWidget {
  const LokagoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LokaGo',
      theme: ThemeData(
        fontFamily: 'PlusJakartaSans',
        scaffoldBackgroundColor: const Color(0xFFFF7154),
      ),
      home: const AuthGate(),
    );
  }
}