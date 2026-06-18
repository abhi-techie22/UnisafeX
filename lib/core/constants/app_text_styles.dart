import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Legacy hotel-module text aliases. New screens should prefer AppTheme.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
      );

  static TextStyle get headlineLarge => GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get headlineMedium => GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get headlineSmall => GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get titleLarge => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
      );

  static TextStyle get titleMedium => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  static TextStyle get labelMedium => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      );

  static TextStyle get overline => GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      );

  static TextStyle get buttonText => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      );
}
