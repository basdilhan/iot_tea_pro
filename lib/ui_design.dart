import 'package:flutter/material.dart';

/// Centralized UI design tokens and helpers for the Tea IoT app.
class UIDesign {
  // Core palette (Dark professional + cyan / purple accents)
  static const Color charcoal = Color(0xFF121417); // Deep background
  static const Color charcoalElevated = Color(0xFF1E2228); // Surfaces / cards
  static const Color outlineDark = Color(0xFF2A3036); // Border / dividers

  static const Color accentCyan = Color(0xFF00BCD4); // Primary accent
  static const Color accentCyanSoft = Color(0xFF35CEE3); // Lighter accent
  static const Color accentPurple = Color(0xFF9C27B0); // Secondary accent
  static const Color accentPurpleSoft = Color(0xFFB450C4);

  static const Color successGreen = Color(0xFF2ECC71);
  static const Color warningAmber = Color(0xFFFFB300);
  static const Color errorRed = Color(0xFFE53935);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B8C1);

  // Gradient helpers
  static LinearGradient heroGradient() => const LinearGradient(
    colors: [accentCyan, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient subtleSurfaceGradient() => LinearGradient(
    colors: [charcoalElevated, charcoalElevated.withOpacity(0.85)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxShadow softGlow(Color base) => BoxShadow(
    color: base.withOpacity(0.35),
    blurRadius: 28,
    spreadRadius: 2,
    offset: const Offset(0, 6),
  );

  static RoundedRectangleBorder cardShape([double radius = 16]) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  // Hero number style (weight, totals)
  static TextStyle heroNumber({double size = 56}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: textPrimary,
  );

  static TextStyle heroLabel() => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  static ThemeData buildDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentPurple,
        surface: charcoalElevated,
        error: errorRed,
      ),
      scaffoldBackgroundColor: charcoal,
      appBarTheme: const AppBarTheme(
        backgroundColor: charcoalElevated,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: accentCyan),
      ),
      cardTheme: CardThemeData(
        color: charcoalElevated,
        elevation: 4,
        shape: cardShape(),
        shadowColor: accentCyan.withOpacity(0.12),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: charcoalElevated,
        indicatorColor: accentCyan.withOpacity(0.20),
        elevation: 1,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? accentCyan : textSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: charcoalElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentCyan, width: 1.6),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        prefixIconColor: accentCyan,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: heroNumber(size: 64),
        headlineMedium: heroNumber(size: 48),
        headlineSmall: heroNumber(size: 40),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      dividerColor: outlineDark,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(accentCyan),
        trackColor: WidgetStateProperty.all(accentCyan.withOpacity(0.4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentCyan,
      ),
    );
  }
}
