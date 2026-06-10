import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Supabase
  static const String supabaseUrl = 'https://anslzankezcrxvuoidxj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuc2x6YW5rZXpjcnh2dW9pZHhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0ODM4NDMsImV4cCI6MjA5NjA1OTg0M30.G2TbpW3dA7IRo1zf0ft7cR7AMKZL4TjNobnfNa9QJE0';

  static const String authCallbackUrl = 'unisafex://login-callback/';

  // App Info
  static const String appName = 'UniSafeX';
  static const String appVersion = '1.0.2-google-profilefix (build 6)';

  // Localization
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('fr'),
    Locale('de'),
    Locale('es'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('ar'),
    Locale('ru'),
  ];

  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Border Radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;
  static const double radiusFull = 100.0;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);

  // Categories
  static const List<String> placeCategories = [
    'Historical',
    'Nature',
    'Spiritual',
    'Adventure',
    'Photography',
    'Food',
    'Shopping',
    'Wildlife',
  ];

  // Visa Types
  static const List<String> visaTypes = [
    'Tourist Visa',
    'Business Visa',
    'Student Visa',
    'Transit Visa',
    'Medical Visa',
    'Employment Visa',
    'Conference Visa',
    'Research Visa',
    'E-Visa',
  ];

  // Gender Options
  static const List<String> genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  // Travel Purposes
  static const List<String> travelPurposes = [
    'Tourism & Sightseeing',
    'Business',
    'Education',
    'Medical',
    'Spiritual / Pilgrimage',
    'Adventure Sports',
    'Photography',
    'Cultural Exchange',
    'Research',
  ];

  // Map defaults
  static const double defaultLatitude = 20.5937;
  static const double defaultLongitude = 78.9629;
  static const double defaultZoom = 5.0;
  static const double placeZoom = 14.0;

  // Cache keys
  static const String cacheKeyTheme = 'app_theme_mode';
  static const String cacheKeyOnboarding = 'onboarding_complete';
  static const String cacheKeyLanguage = 'app_language';

  // Pagination
  static const int pageSize = 20;
}
