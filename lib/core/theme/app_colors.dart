import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0D9488); // Teal
  static const primaryLight = Color(0xFFCCFBF1);
  static const primaryDark = Color(0xFF0F766E);

  static const income = Color(0xFF16A34A); // Green
  static const incomeLight = Color(0xFFDCFCE7);
  static const expense = Color(0xFFEF4444); // Red
  static const expenseLight = Color(0xFFFEE2E2);

  static const accent = Color(0xFFF59E0B); // Amber (budget warnings)

  // Light theme
  static const scaffoldLight = Color(0xFFF8FAFA);
  static const cardLight = Color(0xFFFFFFFF);
  static const textLight = Color(0xFF0F1720);
  static const textLightMuted = Color(0xFF64748B);

  // Dark theme
  static const scaffoldDark = Color(0xFF0B1120);
  static const cardDark = Color(0xFF161E2E);
  static const textDark = Color(0xFFE2E8F0);
  static const textDarkMuted = Color(0xFF94A3B8);

  // Category colors (indexed)
  static const catColors = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF6366F1),
    Color(0xFFF97316),
    Color(0xFF84CC16),
  ];

  static Color cat(int index) => catColors[index % catColors.length];
}
