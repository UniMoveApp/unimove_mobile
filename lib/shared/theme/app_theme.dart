import 'package:flutter/material.dart';

class AppColors {
  // University Color
  static const universityGreen = Color(0xFF86BC56);
  static const universityGreenDark = Color(0xFF6A9E41);

  // Dark Theme Palette
  static const deepBlack = Color(0xFF000000);
  static const charcoal = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const cardDark = Color(0xFF252525);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textMuted = Colors.white38;

  // Gradients
  static const blackGradient = LinearGradient(
    colors: [charcoal, deepBlack],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [universityGreen, universityGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.universityGreen,
      brightness: Brightness.dark,
      primary: AppColors.universityGreen,
      onPrimary: Colors.white,
      secondary: AppColors.universityGreen,
      onSecondary: Colors.white,
      surface: AppColors.deepBlack, // Use deepBlack as background surface
      onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.deepBlack,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.deepBlack,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.universityGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.universityGreen;
        }
        return null;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.universityGreen, width: 2),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.charcoal,
      selectedItemColor: AppColors.universityGreen,
      unselectedItemColor: AppColors.textMuted,
    ),
  );

  // Force dark theme even for light mode if requested
  static final light = dark;
}
