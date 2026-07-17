// ─────────────────────────────────────────────────────────────────────────────
// main.dart
// App entry point — initializes Firebase and launches the passenger screen.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'passenger_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDslUwdBp0C57c84qvLOJe9_QdPo5sgx6E',
          appId: '1:829164680847:web:d3d91da64b69953da8a2fa',
          messagingSenderId: '829164680847',
          projectId: 'last-mile-81251',
          storageBucket: 'last-mile-81251.firebasestorage.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const PassengerApp());
}

class PassengerApp extends StatelessWidget {
  const PassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Ride — Passenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const PassengerHomeScreen(),
    );
  }
}
