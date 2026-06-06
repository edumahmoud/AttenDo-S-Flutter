import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography system for the AttenDo student app.
///
/// Uses **Cairo** for Arabic text and **GeistSans** as the
/// system sans-serif for English / Latin text, matching the
/// font families declared in pubspec.yaml.
class AppTypography {
  AppTypography._();

  /// Font family for Arabic text.
  static const String arabicFont = 'Cairo';

  /// Font family for English / Latin text.
  static const String latinFont = 'GeistSans';

  // ─── Light Text Theme ───

  static TextTheme lightTextTheme = TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 1.12,
      letterSpacing: -0.25,
      color: AppColors.lightForeground,
    ),
    displayMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
      letterSpacing: 0,
      color: AppColors.lightForeground,
    ),
    displaySmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
      letterSpacing: 0,
      color: AppColors.lightForeground,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
      color: AppColors.lightForeground,
    ),
    headlineMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
      letterSpacing: 0,
      color: AppColors.lightForeground,
    ),
    headlineSmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0,
      color: AppColors.lightForeground,
    ),

    // Title
    titleLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
      letterSpacing: 0,
      color: AppColors.lightForeground,
    ),
    titleMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.15,
      color: AppColors.lightForeground,
    ),
    titleSmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: AppColors.lightForeground,
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.5,
      color: AppColors.lightForeground,
    ),
    bodyMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
      color: AppColors.lightForeground,
    ),
    bodySmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
      color: AppColors.lightMutedForeground,
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: AppColors.lightForeground,
    ),
    labelMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0.5,
      color: AppColors.lightMutedForeground,
    ),
    labelSmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.45,
      letterSpacing: 0.5,
      color: AppColors.lightMutedForeground,
    ),
  );

  // ─── Dark Text Theme ───

  static TextTheme darkTextTheme = TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 1.12,
      letterSpacing: -0.25,
      color: AppColors.darkForeground,
    ),
    displayMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 1.16,
      letterSpacing: 0,
      color: AppColors.darkForeground,
    ),
    displaySmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 1.22,
      letterSpacing: 0,
      color: AppColors.darkForeground,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
      color: AppColors.darkForeground,
    ),
    headlineMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
      letterSpacing: 0,
      color: AppColors.darkForeground,
    ),
    headlineSmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0,
      color: AppColors.darkForeground,
    ),

    // Title
    titleLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
      letterSpacing: 0,
      color: AppColors.darkForeground,
    ),
    titleMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.15,
      color: AppColors.darkForeground,
    ),
    titleSmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: AppColors.darkForeground,
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.5,
      color: AppColors.darkForeground,
    ),
    bodyMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
      color: AppColors.darkForeground,
    ),
    bodySmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
      color: AppColors.darkMutedForeground,
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: arabicFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: AppColors.darkForeground,
    ),
    labelMedium: TextStyle(
      fontFamily: arabicFont,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0.5,
      color: AppColors.darkMutedForeground,
    ),
    labelSmall: TextStyle(
      fontFamily: arabicFont,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.45,
      letterSpacing: 0.5,
      color: AppColors.darkMutedForeground,
    ),
  );

  /// Returns the [TextTheme] appropriate for the given [brightness].
  static TextTheme forBrightness(Brightness brightness) {
    return brightness == Brightness.light ? lightTextTheme : darkTextTheme;
  }
}
