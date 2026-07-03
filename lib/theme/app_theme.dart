import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text style helpers for the three-font system: Zilla Slab for headers,
/// Inter for body/UI copy, IBM Plex Mono for times/doses/data labels.
class AppFonts {
  AppFonts._();

  static TextStyle header({
    double size = 22,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w600,
  }) =>
      GoogleFonts.zillaSlab(fontSize: size, color: color, fontWeight: weight);

  static TextStyle body({
    double size = 14,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight);

  static TextStyle mono({
    double size = 12,
    Color color = AppColors.textSecondary,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.ibmPlexMono(fontSize: size, color: color, fontWeight: weight);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.pharma,
        secondary: AppColors.herbalSupplement,
        surface: AppColors.surface,
        error: AppColors.warning,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: AppColors.railLine,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.pharma),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.pharma,
        unselectedItemColor: AppColors.textFaint,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
