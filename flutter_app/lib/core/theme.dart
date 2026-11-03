import 'package:flutter/material.dart';

abstract final class AppColors {
  static const gold = Color(0xFFB8860B);
  static const maroon = Color(0xFF7B1E1E);
  static const cream = Color(0xFFFFF8E7);
  static const saffron = Color(0xFFF4A300);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    primary: const Color(0xFF9A6A00),
    secondary: AppColors.maroon,
    surface: AppColors.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    navigationBarTheme:
        const NavigationBarThemeData(backgroundColor: Colors.white),
  );
}
