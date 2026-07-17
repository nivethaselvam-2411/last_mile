// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants/app_constants.dart';
import 'firebase_options.dart';
import 'screens/driver_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set immersive status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoShare Driver',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const DriverHomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppConstants.primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.highlightColor,
        secondary: AppConstants.onlineColor,
        surface: AppConstants.surfaceColor,
        onPrimary: Colors.white,
        onSurface: AppConstants.textPrimary,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppConstants.textPrimary),
        bodyMedium: TextStyle(color: AppConstants.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.cardColor,
        contentTextStyle: const TextStyle(color: AppConstants.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
