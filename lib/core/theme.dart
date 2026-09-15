import 'package:flutter/material.dart';
class AppColors {
  static const bg = Color(0xFF0A0D14);
  static const surface = Color(0xFF141821);
  static const surfaceAlt = Color(0xFF1B2130);
  static const border = Color(0xFF252B3A);
  static const primary = Color(0xFF6C5CE7);
  static const primaryGlow = Color(0xFF8B7BFF);
  static const success = Color(0xFF35C98A);
  static const warning = Color(0xFFF4B942);
  static const danger = Color(0xFFFF5C6C);
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFF8B95A8);
  static const textTertiary = Color(0xFF5D6678);
}
class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F8FB),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: Color(0xFFFFFFFF),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E6EF)),
      ),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Color(0xFFF0F2F7), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none)),
  );
  static final dark = ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: AppColors.bg, colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface), cardTheme: CardThemeData(color: AppColors.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)), side: BorderSide(color: AppColors.border))));
}
