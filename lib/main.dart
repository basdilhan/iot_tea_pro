import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Auth_wrapper.dart'; // We will create this file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TeaWeigherApp());
}

class TeaWeigherApp extends StatelessWidget {
  const TeaWeigherApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a light cyan + light green color mix for a fresh, airy UI.
    final Color seed = Colors.cyan;
    return MaterialApp(
      title: 'Tea Weigher',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          primary: Colors.cyan.shade600,
          secondary: Colors.green.shade300,
          brightness: Brightness.light,
        ),
      ).copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.cyan.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green.shade400,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.cyan.shade700,
          unselectedItemColor: Colors.grey[600],
          showUnselectedLabels: true,
        ),
        // Keep cards default but use rounded corners by using a lighter elevation
        // (leave CardTheme to system defaults for compatibility)
      ),
      home: const AuthWrapper(), // This is the new home
    );
  }
}
