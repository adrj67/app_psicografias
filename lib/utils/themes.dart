import 'package:flutter/material.dart';
import 'constants.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppConstants.lightPrimary,
    scaffoldBackgroundColor: AppConstants.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: AppConstants.lightPrimary,
      secondary: AppConstants.lightSecondary,
      surface: AppConstants.lightSurface,
      background: AppConstants.lightBackground,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      color: AppConstants.lightSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.lightPrimary,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.lightSurface,
      hintStyle: TextStyle(color: AppConstants.lightText.withValues(alpha: 0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.lightPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppConstants.lightPrimary.withValues(alpha: 0.1),
      selectedColor: AppConstants.lightPrimary,
      labelStyle: TextStyle(color: AppConstants.lightPrimary),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.lightText),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppConstants.lightText),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: AppConstants.lightText),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: AppConstants.lightText),
      bodySmall: TextStyle(fontSize: 12, color: AppConstants.lightText),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppConstants.darkPrimary,
    scaffoldBackgroundColor: AppConstants.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppConstants.darkPrimary,
      secondary: AppConstants.darkSecondary,
      surface: AppConstants.darkSurface,
      background: AppConstants.darkBackground,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      color: AppConstants.darkSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.darkPrimary,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.darkSurface,
      hintStyle: TextStyle(color: AppConstants.darkText.withValues(alpha: 0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.darkPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppConstants.darkPrimary.withValues(alpha: 0.2),
      selectedColor: AppConstants.darkPrimary,
      labelStyle: TextStyle(color: AppConstants.darkText),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.darkText),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppConstants.darkText),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: AppConstants.darkText),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: AppConstants.darkText),
      bodySmall: TextStyle(fontSize: 12, color: AppConstants.darkText),
    ),
  );
}