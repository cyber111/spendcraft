import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_skin.dart';

class AppTheme {
  static TextTheme _textTheme(Color color, Color muted) {
    final base = GoogleFonts.interTextTheme();
    return base.apply(bodyColor: color, displayColor: color);
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      surface: AppColors.cardLight,
      error: AppColors.expense,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.scaffoldLight,
      cardColor: AppColors.cardLight,
      textTheme: _textTheme(AppColors.textLight, AppColors.textLightMuted),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerColor: const Color(0xFFE2E8F0),
      inputDecorationTheme: _inputTheme(const Color(0xFFF1F5F9)),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLightMuted,
      ),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      surface: AppColors.cardDark,
      error: AppColors.expense,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      cardColor: AppColors.cardDark,
      textTheme: _textTheme(AppColors.textDark, AppColors.textDarkMuted),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffoldDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerColor: const Color(0xFF24303F),
      inputDecorationTheme: _inputTheme(const Color(0xFF1E293B)),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDarkMuted,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(Color fill) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  /// Big amount display font for the active design system.
  static TextStyle amountStyle(
    BuildContext context, {
    double size = 40,
    Color? color,
    FontWeight? weight,
  }) =>
      context.skin.amount(size: size, color: color, weight: weight);
}
