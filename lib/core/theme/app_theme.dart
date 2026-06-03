import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1A6B4A);
  static const Color primaryDark = Color(0xFF0F4A33);
  static const Color primaryLight = Color(0xFF2D8A62);
  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFFC847);

  // Neutral
  static const Color black = Color(0xFF0A0A0A);
  static const Color grey900 = Color(0xFF1A1A1A);
  static const Color grey800 = Color(0xFF2D2D2D);
  static const Color grey700 = Color(0xFF3D3D3D);
  static const Color grey600 = Color(0xFF5A5A5A);
  static const Color grey500 = Color(0xFF808080);
  static const Color grey400 = Color(0xFFABABAB);
  static const Color grey300 = Color(0xFFD1D1D1);
  static const Color grey200 = Color(0xFFE8E8E8);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Surface (Light)
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEEEEEE);

  // Surface (Dark)
  static const Color surfaceDark = Color(0xFF0F0F0F);
  static const Color cardDark = Color(0xFF1C1C1C);
  static const Color borderDark = Color(0xFF2A2A2A);

  // Category Colors
  static const Color historical = Color(0xFFB45309);
  static const Color nature = Color(0xFF16A34A);
  static const Color spiritual = Color(0xFF7C3AED);
  static const Color adventure = Color(0xFFDC2626);
  static const Color photography = Color(0xFFDB2777);
  static const Color food = Color(0xFFEA580C);
  static const Color shopping = Color(0xFF0284C7);
  static const Color wildlife = Color(0xFF065F46);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge(BuildContext context) =>
      Theme.of(context).textTheme.displayLarge!;
  static TextStyle displayMedium(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium!;
  static TextStyle headlineLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge!;
  static TextStyle headlineMedium(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!;
  static TextStyle headlineSmall(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!;
  static TextStyle titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!;
  static TextStyle titleMedium(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!;
  static TextStyle bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!;
  static TextStyle bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!;
  static TextStyle bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;
  static TextStyle labelLarge(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!;
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.black,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.grey900,
        error: AppColors.error,
        outline: AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.surfaceLight,
      textTheme: _buildTextTheme(isLight: true),
      appBarTheme: _buildAppBarTheme(isLight: true),
      cardTheme: _buildCardTheme(isLight: true),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(isLight: true),
      inputDecorationTheme: _buildInputDecorationTheme(isLight: true),
      chipTheme: _buildChipTheme(isLight: true),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
      bottomNavigationBarTheme: _buildBottomNavTheme(isLight: true),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.black,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.white,
        error: AppColors.error,
        outline: AppColors.borderDark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      textTheme: _buildTextTheme(isLight: false),
      appBarTheme: _buildAppBarTheme(isLight: false),
      cardTheme: _buildCardTheme(isLight: false),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(isLight: false),
      inputDecorationTheme: _buildInputDecorationTheme(isLight: false),
      chipTheme: _buildChipTheme(isLight: false),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
      bottomNavigationBarTheme: _buildBottomNavTheme(isLight: false),
    );
  }

  static TextTheme _buildTextTheme({required bool isLight}) {
    final textColor = isLight ? AppColors.grey900 : AppColors.white;
    final subtleColor = isLight ? AppColors.grey600 : AppColors.grey400;

    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.15,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.25,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.35,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: subtleColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: subtleColor,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: subtleColor,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: subtleColor,
        letterSpacing: 0.8,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme({required bool isLight}) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
      foregroundColor: isLight ? AppColors.grey900 : AppColors.white,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isLight ? AppColors.grey900 : AppColors.white,
      ),
    );
  }

  // ✅ Fixed: CardTheme -> CardThemeData (Flutter 3.x requirement)
  static CardThemeData _buildCardTheme({required bool isLight}) {
    return CardThemeData(
      elevation: 0,
      color: isLight ? AppColors.cardLight : AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLight ? AppColors.borderLight : AppColors.borderDark,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
      {required bool isLight}) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isLight ? AppColors.grey900 : AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: BorderSide(
          color: isLight ? AppColors.borderLight : AppColors.borderDark,
          width: 1.5,
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
      {required bool isLight}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isLight ? AppColors.grey100 : AppColors.grey800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isLight ? AppColors.borderLight : AppColors.borderDark,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.dmSans(
        fontSize: 14,
        color: isLight ? AppColors.grey400 : AppColors.grey600,
      ),
    );
  }

  static ChipThemeData _buildChipTheme({required bool isLight}) {
    return ChipThemeData(
      backgroundColor: isLight ? AppColors.grey100 : AppColors.grey800,
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isLight ? AppColors.grey700 : AppColors.grey300,
      ),
      secondaryLabelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: BorderSide.none,
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(
      {required bool isLight}) {
    return BottomNavigationBarThemeData(
      backgroundColor: isLight ? AppColors.cardLight : AppColors.cardDark,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: isLight ? AppColors.grey400 : AppColors.grey600,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}