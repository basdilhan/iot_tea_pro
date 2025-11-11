import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'theme_provider.dart';

// Define our "Tea Theme" colors with light/dark support - Navy Blue, Brown, Grey theme
class AppTheme {
  static Color primaryNavy(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? const Color(0xFF4A90E2) : const Color(0xFF1A365D);
  }

  static Color secondaryBrown(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? const Color(0xFF8B4513) : const Color(0xFF8B4513);
  }

  static Color accentGrey(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? const Color(0xFF6B7280) : const Color(0xFF4B5563);
  }

  static Color lightNavy(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? const Color(0xFF2B77E6) : const Color(0xFF2D3748);
  }

  static Color lightBrown(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? const Color(0xFFCD853F) : const Color(0xFFD2691E);
  }

  static Color cardColor(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? const Color(0xFF374151) : Colors.white;
  }

  static Color textColor(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? Colors.white : Colors.black;
  }

  // Legacy support for backward compatibility
  static Color primaryGreen(BuildContext context) => primaryNavy(context);
  static Color lightGreen(BuildContext context) => lightNavy(context);
  static Color accentOrange(BuildContext context) => secondaryBrown(context);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const TeaWeigherApp(),
    ),
  );
}

class TeaWeigherApp extends StatelessWidget {
  const TeaWeigherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Tea Weigher',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const AuthWrapper(),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF1A365D),
      scaffoldBackgroundColor: const Color(0xFFF7FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A365D),
        elevation: 4,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A365D),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFF1A365D), width: 2.0),
        ),
        labelStyle: const TextStyle(color: Color(0xFF1A365D)),
        prefixIconColor: Colors.grey[600],
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF4A90E2),
      scaffoldBackgroundColor: const Color(0xFF1A202C),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2D3748),
        elevation: 4,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF374151),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2D3748),
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2.0),
        ),
        labelStyle: const TextStyle(color: Color(0xFF4A90E2)),
        prefixIconColor: Colors.grey[400],
      ),
    );
  }
}
