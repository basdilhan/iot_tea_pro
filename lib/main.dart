import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'theme_provider.dart';

// Define our "Tea Theme" colors with light/dark support
class AppTheme {
  static Color primaryGreen(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? Colors.green[300]! : Colors.green[800]!;
  }

  static Color lightGreen(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9);
  }

  static Color accentOrange(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? const Color(0xFFFF9800) : const Color(0xFFF57C00);
  }

  static Color cardColor(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? Colors.grey[800]! : Colors.white;
  }

  static Color textColor(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return isDark ? Colors.white : Colors.black;
  }
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
      primarySwatch: Colors.green,
      primaryColor: Colors.green[800],
      scaffoldBackgroundColor: const Color(0xFFE8F5E9),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green[800],
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
          backgroundColor: const Color(0xFFF57C00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green[800],
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
          borderSide: BorderSide(color: Colors.green[800]!, width: 2.0),
        ),
        labelStyle: TextStyle(color: Colors.green[800]),
        prefixIconColor: Colors.grey[600],
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: Colors.green[300],
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green[700],
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
        color: Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9800),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.green[300],
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
          borderSide: BorderSide(color: Colors.green[300]!, width: 2.0),
        ),
        labelStyle: TextStyle(color: Colors.green[300]),
        prefixIconColor: Colors.grey[400],
      ),
    );
  }
}
