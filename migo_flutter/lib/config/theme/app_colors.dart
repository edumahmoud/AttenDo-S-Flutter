import 'package:flutter/material.dart';

/// Comprehensive color system for the AttenDo student app.
///
/// Matches the original Next.js project's design tokens with
/// ocean-blue primary palette, teal accent, and warm backgrounds.
class AppColors {
  AppColors._();

  // ─── Shared (light & dark use same semantic structure) ───

  // ─── Light Mode ───
  static const Color lightOcean = Color(0xFF0369A1); // sky-700
  static const Color lightOceanForeground = Color(0xFFFFFFFF);
  static const Color lightTealAccent = Color(0xFF0D9488); // teal-600
  static const Color lightTealAccentForeground = Color(0xFFFFFFFF);
  static const Color lightAmberAccent = Color(0xFFD97706); // amber-600
  static const Color lightAmberAccentForeground = Color(0xFF451A03);
  static const Color lightBackground = Color(0xFFFAFAF9); // warm white
  static const Color lightForeground = Color(0xFF1E293B);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardForeground = Color(0xFF1E293B);
  static const Color lightPrimary = Color(0xFF0369A1);
  static const Color lightPrimaryForeground = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFFE0F2FE); // sky-100
  static const Color lightSecondaryForeground = Color(0xFF0C4A6E);
  static const Color lightMuted = Color(0xFFF1F5F9); // slate-100
  static const Color lightMutedForeground = Color(0xFF64748B);
  static const Color lightAccent = Color(0xFF0D9488);
  static const Color lightAccentForeground = Color(0xFFFFFFFF);
  static const Color lightDestructive = Color(0xFFDC2626);
  static const Color lightDestructiveForeground = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightInput = Color(0xFFE2E8F0);
  static const Color lightRing = Color(0xFF0369A1);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAF9);
  static const Color lightOnSurface = Color(0xFF1E293B);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);
  static const Color lightOutline = Color(0xFFE2E8F0);
  static const Color lightOutlineVariant = Color(0xFFF1F5F9);
  static const Color lightInverseSurface = Color(0xFF1E293B);
  static const Color lightOnInverseSurface = Color(0xFFF1F5F9);
  static const Color lightShadow = Color(0xFF000000);
  static const Color lightScrim = Color(0xFF000000);
  static const Color lightScaffoldBackground = Color(0xFFFAFAF9);

  // Sidebar specific
  static const Color lightSidebarBackground = Color(0xFFF8FAFC);
  static const Color lightSidebarForeground = Color(0xFF0C4A6E);
  static const Color lightSidebarPrimary = Color(0xFF0369A1);
  static const Color lightSidebarPrimaryForeground = Color(0xFFFFFFFF);
  static const Color lightSidebarAccent = Color(0xFFE0F2FE);
  static const Color lightSidebarAccentForeground = Color(0xFF0C4A6E);
  static const Color lightSidebarBorder = Color(0xFFE2E8F0);

  // ─── Dark Mode ───
  static const Color darkOcean = Color(0xFF3B82F6); // brighter blue for dark
  static const Color darkOceanForeground = Color(0xFFF0F9FF);
  static const Color darkTealAccent = Color(0xFF2DD4BF); // teal-400
  static const Color darkTealAccentForeground = Color(0xFFF0F9FF);
  static const Color darkAmberAccent = Color(0xFFFBBF24); // amber-400
  static const Color darkAmberAccentForeground = Color(0xFF451A03);
  static const Color darkBackground = Color(0xFF1A1B2E); // warm charcoal
  static const Color darkForeground = Color(0xFFE2E8F0);
  static const Color darkCard = Color(0xFF232438);
  static const Color darkCardForeground = Color(0xFFE2E8F0);
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkPrimaryForeground = Color(0xFFF0F9FF);
  static const Color darkSecondary = Color(0xFF2A2D45);
  static const Color darkSecondaryForeground = Color(0xFFCBD5E1);
  static const Color darkMuted = Color(0xFF1E293B);
  static const Color darkMutedForeground = Color(0xFF7C8DB0);
  static const Color darkAccent = Color(0xFF2DD4BF);
  static const Color darkAccentForeground = Color(0xFFF0F9FF);
  static const Color darkDestructive = Color(0xFFEF4444);
  static const Color darkDestructiveForeground = Color(0xFFF0F9FF);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkInput = Color(0xFF334155);
  static const Color darkRing = Color(0xFF3B82F6);
  static const Color darkError = Color(0xFFEF4444);
  static const Color darkOnError = Color(0xFFF0F9FF);
  static const Color darkSurface = Color(0xFF1A1B2E);
  static const Color darkOnSurface = Color(0xFFE2E8F0);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkOnSurfaceVariant = Color(0xFF7C8DB0);
  static const Color darkOutline = Color(0xFF334155);
  static const Color darkOutlineVariant = Color(0xFF1E293B);
  static const Color darkInverseSurface = Color(0xFFE2E8F0);
  static const Color darkOnInverseSurface = Color(0xFF1E293B);
  static const Color darkShadow = Color(0xFF000000);
  static const Color darkScrim = Color(0xFF000000);
  static const Color darkScaffoldBackground = Color(0xFF1A1B2E);

  // Sidebar specific
  static const Color darkSidebarBackground = Color(0xFF151626);
  static const Color darkSidebarForeground = Color(0xFFE2E8F0);
  static const Color darkSidebarPrimary = Color(0xFF3B82F6);
  static const Color darkSidebarPrimaryForeground = Color(0xFFF0F9FF);
  static const Color darkSidebarAccent = Color(0xFF232438);
  static const Color darkSidebarAccentForeground = Color(0xFFE2E8F0);
  static const Color darkSidebarBorder = Color(0xFF334155);

  /// Builds the light [ColorScheme].
  static ColorScheme light() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: lightPrimaryForeground,
      primaryContainer: lightSecondary,
      onPrimaryContainer: lightSecondaryForeground,
      secondary: lightSecondary,
      onSecondary: lightSecondaryForeground,
      secondaryContainer: Color(0xFFBAE6FD), // sky-200
      onSecondaryContainer: lightSecondaryForeground,
      tertiary: lightTealAccent,
      onTertiary: lightTealAccentForeground,
      tertiaryContainer: Color(0xFFCCFBF1), // teal-100
      onTertiaryContainer: Color(0xFF134E4A), // teal-900
      error: lightError,
      onError: lightOnError,
      errorContainer: Color(0xFFFEE2E2), // red-100
      onErrorContainer: Color(0xFF991B1B), // red-800
      surface: lightSurface,
      onSurface: lightOnSurface,
      surfaceContainerHighest: lightSurfaceVariant,
      onSurfaceVariant: lightOnSurfaceVariant,
      outline: lightOutline,
      outlineVariant: lightOutlineVariant,
      inverseSurface: lightInverseSurface,
      onInverseSurface: lightOnInverseSurface,
      shadow: lightShadow,
      scrim: lightScrim,
    );
  }

  /// Builds the dark [ColorScheme].
  static ColorScheme dark() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkPrimaryForeground,
      primaryContainer: darkSecondary,
      onPrimaryContainer: darkSecondaryForeground,
      secondary: darkSecondary,
      onSecondary: darkSecondaryForeground,
      secondaryContainer: Color(0xFF1E293B),
      onSecondaryContainer: darkSecondaryForeground,
      tertiary: darkTealAccent,
      onTertiary: darkTealAccentForeground,
      tertiaryContainer: Color(0xFF134E4A),
      onTertiaryContainer: Color(0xFFCCFBF1),
      error: darkError,
      onError: darkOnError,
      errorContainer: Color(0xFF991B1B),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: darkSurface,
      onSurface: darkOnSurface,
      surfaceContainerHighest: darkSurfaceVariant,
      onSurfaceVariant: darkOnSurfaceVariant,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      inverseSurface: darkInverseSurface,
      onInverseSurface: darkOnInverseSurface,
      shadow: darkShadow,
      scrim: darkScrim,
    );
  }

  /// Returns the ocean color for the given [brightness].
  static Color ocean(Brightness brightness) {
    return brightness == Brightness.light ? lightOcean : darkOcean;
  }

  /// Returns the ocean-foreground color for the given [brightness].
  static Color oceanForeground(Brightness brightness) {
    return brightness == Brightness.light
        ? lightOceanForeground
        : darkOceanForeground;
  }

  /// Returns the teal accent color for the given [brightness].
  static Color tealAccent(Brightness brightness) {
    return brightness == Brightness.light ? lightTealAccent : darkTealAccent;
  }

  /// Returns the amber accent color for the given [brightness].
  static Color amberAccent(Brightness brightness) {
    return brightness == Brightness.light ? lightAmberAccent : darkAmberAccent;
  }

  /// Returns the sidebar background for the given [brightness].
  static Color sidebarBackground(Brightness brightness) {
    return brightness == Brightness.light
        ? lightSidebarBackground
        : darkSidebarBackground;
  }

  /// Returns the sidebar foreground for the given [brightness].
  static Color sidebarForeground(Brightness brightness) {
    return brightness == Brightness.light
        ? lightSidebarForeground
        : darkSidebarForeground;
  }
}
