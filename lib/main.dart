import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';

// Define our "Tea Theme" colors
class AppTheme {
  static final Color primaryGreen = Colors.green[800]!; // Dark, rich green
  static const Color lightGreen = Color(0xFFE8F5E9); // Very light green
  static const Color accentOrange = Color(0xFFF57C00); // A "tea" color
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TeaWeigherApp());
}

class TeaWeigherApp extends StatelessWidget {
  const TeaWeigherApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tea Weigher',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: AppTheme.primaryGreen,
        scaffoldBackgroundColor: AppTheme.lightGreen, // Light green background
        // App Bar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.primaryGreen,
          elevation: 4,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),

        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange, // Use accent color
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),

        // Bottom Nav Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed, // Important for 4+ items
        ),

        // Input Field Theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2.0),
          ),
          labelStyle: TextStyle(color: AppTheme.primaryGreen),
          prefixIconColor: Colors.grey[600],
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
