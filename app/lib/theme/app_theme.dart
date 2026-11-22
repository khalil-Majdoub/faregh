import 'package:flutter/material.dart';

class AppColors {
  // Warm, calm editorial canvas inspired by the prototype
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF2F4F7);
  static const Color navyDark = Color(0xFF0E1F33);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textMuted = Color(0xFF98A2B3);
  static const Color borderLight = Color(0xFFEAECF0);
  static const Color inactiveSegment = Color(0xFFE5E8EE);
  static const Color accentBlue = Color(0xFF0A84FF);
  static const Color locationGreen = Color(0xFF169A5B);

  // Crowded (Red: >= 40 min)
  static const Color crowdedMain = Color(0xFFDC3B3B);
  static const Color crowdedText = Color(0xFFB42323);
  static const Color crowdedBg = Color(0xFFFDEEEE);

  // Moderate (Yellow: 20 - 39 min)
  static const Color moderateMain = Color(0xFFE69B19);
  static const Color moderateText = Color(0xFF9A6300);
  static const Color moderateBg = Color(0xFFFEF6E4);

  // Not Crowded (Green: < 20 min)
  static const Color notCrowdedMain = Color(0xFF169A5B);
  static const Color notCrowdedText = Color(0xFF0F6E40);
  static const Color notCrowdedBg = Color(0xFFEAF8F1);
}

class AppTheme {
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x090E1F33),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color(0x050E1F33),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x070E1F33),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navyDark,
        primary: AppColors.navyDark,
        secondary: AppColors.accentBlue,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.navyDark,
            width: 1.4,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
