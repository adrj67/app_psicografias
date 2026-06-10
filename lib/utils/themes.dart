import 'package:flutter/material.dart';
import 'constants.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppConstants.primaryLight,
    colorScheme: const ColorScheme.light(
      primary: AppConstants.primaryLight,
      secondary: AppConstants.accentLight,
      surface: AppConstants.surfaceLight,
    ),
    scaffoldBackgroundColor: AppConstants.backgroundLight,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      color: AppConstants.surfaceLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.primaryLight,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.surfaceLight,
      hintStyle: TextStyle(color: AppConstants.textHintLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppConstants.primaryLight.withValues(alpha: 0.1),
      selectedColor: AppConstants.primaryLight,
      labelStyle: TextStyle(color: AppConstants.primaryLight),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppConstants.primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: AppConstants.primaryDark,
      secondary: AppConstants.accentDark,
      surface: AppConstants.surfaceDark,
    ),
    scaffoldBackgroundColor: AppConstants.backgroundDark,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      color: AppConstants.surfaceDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.primaryDark,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.surfaceDark,
      hintStyle: TextStyle(color: AppConstants.textHintDark),  // ← Hint visible en oscuro
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppConstants.primaryDark.withValues(alpha: 0.2),
      selectedColor: AppConstants.primaryDark,
      labelStyle: TextStyle(color: AppConstants.textDark),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: Colors.white70),
    ),
  );
}