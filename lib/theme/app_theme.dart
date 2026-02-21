import 'package:flutter/material.dart';

/// Theme using only local Inter font for complete offline capability
class AppTheme {
  AppTheme._();

  // ───────────────────────────────────────────────
  // Light color palette
  // ───────────────────────────────────────────────
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryContainerLight = Color(0xFF1B5E20);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);

  static const Color secondaryLight = Color(0xFF8D6E63);
  static const Color secondaryContainerLight = Color(0xFF6D4C41);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);

  static const Color tertiaryLight = Color(0xFFFF6F00); // accent
  static const Color onTertiaryLight = Color(0xFFFFFFFF);

  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF212121);
  static const Color onSurfaceVariantLight = Color(0xFF757575);

  static const Color errorLight = Color(0xFFD32F2F);
  static const Color onErrorLight = Color(0xFFFFFFFF);

  static const Color successLight = Color(0xFF388E3C);
  static const Color warningLight = Color(0xFFF57C00);

  static const Color shadowLight = Color(0x1F000000);
  static const Color dividerLight = Color(0xFFE0E0E0);

  // ───────────────────────────────────────────────
  // Dark color palette
  // ───────────────────────────────────────────────
  static const Color primaryDark = Color(0xFF66BB6A);
  static const Color primaryContainerDark = Color(0xFF388E3C);
  static const Color onPrimaryDark = Color(0xFF000000);

  static const Color secondaryDark = Color(0xFFA1887F);
  static const Color secondaryContainerDark = Color(0xFF8D6E63);
  static const Color onSecondaryDark = Color(0xFF000000);

  static const Color tertiaryDark = Color(0xFFFFAB40); // accent
  static const Color onTertiaryDark = Color(0xFF000000);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFE0E0E0);
  static const Color onSurfaceVariantDark = Color(0xB3FFFFFF);

  static const Color errorDark = Color(0xFFEF5350);
  static const Color onErrorDark = Color(0xFF000000);

  static const Color shadowDark = Color(0x33000000);
  static const Color dividerDark = Color(0xFF424242);

  // ───────────────────────────────────────────────
  // Light Theme
  // ───────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Inter',
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      primaryContainer: primaryContainerLight,
      onPrimaryContainer: onPrimaryLight,
      secondary: secondaryLight,
      onSecondary: onSecondaryLight,
      secondaryContainer: secondaryContainerLight,
      onSecondaryContainer: onSecondaryLight,
      tertiary: tertiaryLight,
      onTertiary: onTertiaryLight,
      error: errorLight,
      onError: onErrorLight,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      onSurfaceVariant: onSurfaceVariantLight,
      outline: dividerLight,
      shadow: shadowLight,
      background: backgroundLight,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: surfaceLight,
    dividerColor: dividerLight,

    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceLight,
      foregroundColor: onSurfaceLight,
      elevation: 0,
      scrolledUnderElevation: 3,
      shadowColor: shadowLight,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
    ),

    cardTheme: const CardThemeData(
      color: surfaceLight,
      elevation: 2,
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: tertiaryLight,
      foregroundColor: onTertiaryLight,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: onPrimaryLight,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        minimumSize: const Size(88, 48),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        side: const BorderSide(color: primaryLight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        minimumSize: const Size(88, 48),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    ),

    textTheme: _buildTextTheme(Brightness.light),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dividerLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dividerLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorLight, width: 2),
      ),
      labelStyle: TextStyle(color: onSurfaceVariantLight),
      hintStyle: TextStyle(color: onSurfaceVariantLight.withOpacity(0.6)),
      errorStyle: const TextStyle(color: errorLight),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: primaryLight,
      unselectedLabelColor: onSurfaceVariantLight,
      indicatorColor: primaryLight,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        letterSpacing: 0.1,
      ),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF323232),
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: tertiaryLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      elevation: 6,
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: surfaceLight,
      selectedTileColor: primaryLight.withOpacity(0.12),
      iconColor: onSurfaceVariantLight,
      textColor: onSurfaceLight,
    ),

    dividerTheme: const DividerThemeData(
      color: dividerLight,
      thickness: 1,
      space: 1,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: dividerLight,
      selectedColor: primaryLight.withOpacity(0.18),
      deleteIconColor: onSurfaceVariantLight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: onSurfaceLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
    ),
  );

  // ───────────────────────────────────────────────
  // Dark Theme
  // ───────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: primaryContainerDark,
      onPrimaryContainer: onPrimaryDark,
      secondary: secondaryDark,
      onSecondary: onSecondaryDark,
      secondaryContainer: secondaryContainerDark,
      onSecondaryContainer: onSecondaryDark,
      tertiary: tertiaryDark,
      onTertiary: onTertiaryDark,
      error: errorDark,
      onError: onErrorDark,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      onSurfaceVariant: onSurfaceVariantDark,
      outline: dividerDark,
      shadow: shadowDark,
      background: backgroundDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: surfaceDark,
    dividerColor: dividerDark,

    // Most other properties follow similar pattern to light theme but with dark colors
    // (omitted for brevity – copy & adapt from lightTheme as needed)

    dialogTheme: const DialogThemeData(
      backgroundColor: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
    ),
  );

  // ───────────────────────────────────────────────
  // Shared text theme builder
  // ───────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final high = isLight ? onSurfaceLight : onSurfaceDark;
    final medium = isLight ? onSurfaceVariantLight : onSurfaceVariantDark;

    return TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w700, color: high, letterSpacing: -0.25),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w700, color: high),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: high),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: high),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: high),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: high),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: high),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: high, letterSpacing: 0.15),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: high, letterSpacing: 0.1),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: high, letterSpacing: 0.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: high, letterSpacing: 0.25),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: medium, letterSpacing: 0.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: high, letterSpacing: 0.1),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: medium, letterSpacing: 0.5),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: medium, letterSpacing: 0.5),
    );
  }

  // ───────────────────────────────────────────────
  // Helper getters
  // ───────────────────────────────────────────────
  static Color successColor(Brightness brightness) => successLight;
  static Color warningColor(Brightness brightness) => warningLight;
  static Color accentColor(Brightness brightness) =>
      brightness == Brightness.light ? tertiaryLight : tertiaryDark;
}