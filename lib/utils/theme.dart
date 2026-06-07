import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryGreen = Color(0xFF1B6B3A);
  static const _secondaryGold = Color(0xFFC9A84C);
  static const _backgroundDark = Color(0xFF0D1B2A);
  static const _surfaceDark = Color(0xFF1A2E3D);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryGreen,
          secondary: _secondaryGold,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryGreen,
          secondary: _secondaryGold,
          brightness: Brightness.dark,
          surface: _surfaceDark,
          background: _backgroundDark,
        ),
        scaffoldBackgroundColor: _backgroundDark,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: _backgroundDark,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: _surfaceDark,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}

class AppColors {
  static const green = Color(0xFF1B6B3A);
  static const gold = Color(0xFFC9A84C);
  static const darkBg = Color(0xFF0D1B2A);
  static const darkSurface = Color(0xFF1A2E3D);
  static const prayerPast = Color(0xFF6B7280);
  static const prayerNext = Color(0xFFC9A84C);
  static const prayerUpcoming = Color(0xFF1B6B3A);
}
