import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void hideKeyboard() => FocusScope.of(this).unfocus();
}

extension StringX on String {
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get titleCase {
    return split(' ').map((word) => word.capitalized).join(' ');
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  String countryCodeToFlag() {
    return toUpperCase().runes
        .map((r) => String.fromCharCode(r + 127397))
        .join('');
  }
}

extension DoubleX on double {
  String get distanceLabel {
    if (this < 1.0) return '${(this * 1000).toInt()} m';
    return '${toStringAsFixed(1)} km';
  }
}

extension DateTimeX on DateTime {
  bool get isExpired => isBefore(DateTime.now());

  bool get isExpiringSoon {
    final threshold = DateTime.now().add(const Duration(days: 30));
    return isAfter(DateTime.now()) && isBefore(threshold);
  }

  String get formattedShort {
    return '$day/$month/$year';
  }
}
