import 'package:flutter_test/flutter_test.dart';
import 'package:unisafex/core/constants/app_constants.dart';

void main() {
  test('UniSafeX exposes expected app metadata', () {
    expect(AppConstants.appName, 'UniSafeX');
    expect(AppConstants.supportedLocales, isNotEmpty);
    expect(AppConstants.placeCategories, contains('Historical'));
  });
}
