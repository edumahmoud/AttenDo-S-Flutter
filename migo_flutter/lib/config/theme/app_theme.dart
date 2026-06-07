import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Main theme configuration for the AttenDo student app.
///
/// Combines [AppColors] and [AppTypography] into full [ThemeData]
/// with Material 3, RTL defaults, and custom component themes.
class AppTheme {
  AppTheme._();

  /// Border radius used for cards, dialogs, etc.
  static const double borderRadius = 12.0;

  /// Default border radius as [Radius].
  static const Radius radius = Radius.circular(borderRadius);

  /// Default border radius as [BorderRadius].
  static const BorderRadius borderRadiusGeometry =
      BorderRadius.all(radius);

  // ──────────────────────────── Light ────────────────────────────

  static ThemeData light() {
    final colorScheme = AppColors.light();
    final textTheme = AppTypography.lightTextTheme;

    return _buildTheme(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackground: AppColors.lightScaffoldBackground,
      cardColor: AppColors.lightCard,
      borderColor: AppColors.lightBorder,
      inputColor: AppColors.lightInput,
      mutedColor: AppColors.lightMuted,
      mutedForeground: AppColors.lightMutedForeground,
      sidebarBg: AppColors.lightSidebarBackground,
      sidebarFg: AppColors.lightSidebarForeground,
      sidebarPrimary: AppColors.lightSidebarPrimary,
      sidebarPrimaryFg: AppColors.lightSidebarPrimaryForeground,
      sidebarAccent: AppColors.lightSidebarAccent,
      sidebarAccentFg: AppColors.lightSidebarAccentForeground,
      sidebarBorder: AppColors.lightSidebarBorder,
    );
  }

  // ──────────────────────────── Dark ────────────────────────────

  static ThemeData dark() {
    final colorScheme = AppColors.dark();
    final textTheme = AppTypography.darkTextTheme;

    return _buildTheme(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackground: AppColors.darkScaffoldBackground,
      cardColor: AppColors.darkCard,
      borderColor: AppColors.darkBorder,
      inputColor: AppColors.darkInput,
      mutedColor: AppColors.darkMuted,
      mutedForeground: AppColors.darkMutedForeground,
      sidebarBg: AppColors.darkSidebarBackground,
      sidebarFg: AppColors.darkSidebarForeground,
      sidebarPrimary: AppColors.darkSidebarPrimary,
      sidebarPrimaryFg: AppColors.darkSidebarPrimaryForeground,
      sidebarAccent: AppColors.darkSidebarAccent,
      sidebarAccentFg: AppColors.darkSidebarAccentForeground,
      sidebarBorder: AppColors.darkSidebarBorder,
    );
  }

  // ──────────────────────────── Builder ────────────────────────────

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color borderColor,
    required Color inputColor,
    required Color mutedColor,
    required Color mutedForeground,
    required Color sidebarBg,
    required Color sidebarFg,
    required Color sidebarPrimary,
    required Color sidebarPrimaryFg,
    required Color sidebarAccent,
    required Color sidebarAccentFg,
    required Color sidebarBorder,
  }) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBackground,

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ocean(brightness),
        foregroundColor: AppColors.oceanForeground(brightness),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.oceanForeground(brightness),
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(
          color: AppColors.oceanForeground(brightness),
        ),
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusGeometry,
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusGeometry,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusGeometry,
          ),
          side: BorderSide(color: colorScheme.primary),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusGeometry,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── Input Decoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputColor.withValues(alpha: 0.3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: borderRadiusGeometry,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusGeometry,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusGeometry,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusGeometry,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusGeometry,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: mutedForeground),
        labelStyle: textTheme.bodyMedium?.copyWith(color: mutedForeground),
        floatingLabelStyle:
            textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
      ),

      // ─── Bottom Sheet ───
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: mutedForeground.withValues(alpha: 0.4),
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusGeometry,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ─── Floating Action Button ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusGeometry,
        ),
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: mutedColor,
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusGeometry,
          side: BorderSide(color: borderColor),
        ),
      ),

      // ─── Divider ───
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // ─── Tab Bar ───
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: mutedForeground,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),

      // ─── Bottom Navigation Bar ───
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: mutedForeground,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        elevation: 8,
      ),

      // ─── Navigation Bar (M3) ───
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(color: mutedForeground);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(color: mutedForeground);
        }),
        height: 64,
        elevation: 8,
      ),

      // ─── Navigation Rail (sidebar) ───
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: sidebarBg,
        selectedIconTheme: IconThemeData(
          color: sidebarPrimary,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: sidebarFg.withValues(alpha: 0.6),
          size: 22,
        ),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: sidebarPrimary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: sidebarFg.withValues(alpha: 0.6),
        ),
        indicatorColor: sidebarAccent,
        minWidth: 68,
        minExtendedWidth: 264,
        groupAlignment: 0,
      ),

      // ─── Snack Bar ───
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusGeometry,
        ),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),

      // ─── Progress Indicator ───
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: mutedColor,
      ),

      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return mutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return mutedColor;
        }),
      ),

      // ─── Checkbox ───
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ─── Radio ───
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return mutedForeground;
        }),
      ),

      // ─── Slider ───
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: mutedColor,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      ),

      // ─── Popup Menu ───
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusGeometry,
          side: BorderSide(color: borderColor),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      // ─── List Tile ───
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ─── Tooltip ───
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: borderRadiusGeometry,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ─── Scrollbar ───
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          mutedForeground.withValues(alpha: 0.3),
        ),
        radius: radius,
        thickness: WidgetStateProperty.all(6),
      ),

      // ─── Page transitions ───
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// ──────────────────────────── Providers ────────────────────────────

/// Provider that holds the current [ThemeMode].
///
/// Defaults to light mode. The [AppHeader] theme toggle
/// writes to this provider.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
