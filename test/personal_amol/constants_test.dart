import 'package:amol_tracker_app/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Personal amol constants', () {
    test('free tier is capped and personal points are flat', () {
      expect(AppConstants.kMaxFreePersonalAmol, 10);
      expect(AppConstants.kPersonalAmolPointValue, 10);
    });

    test('cap and point value are positive', () {
      expect(AppConstants.kMaxFreePersonalAmol, greaterThan(0));
      expect(AppConstants.kPersonalAmolPointValue, greaterThan(0));
    });
  });
}