import 'package:amol_tracker_app/core/constants/app_constants.dart';
import 'package:amol_tracker_app/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('logging reminder visibility', () {
    test('fresh user should see the reminder card', () {
      final user = UserModel.fromMap(<String, dynamic>{}, 'uid-1');

      expect(user.dismissedLoggingReminderVersion, 0);
      expect(user.shouldShowLoggingReminder, isTrue);
    });

    test('legacy hasDismissedLoggingReminder true maps to version 1 and still shows card', () {
      final user = UserModel.fromMap(
        <String, dynamic>{'hasDismissedLoggingReminder': true},
        'uid-2',
      );

      expect(user.dismissedLoggingReminderVersion, 1);
      expect(user.shouldShowLoggingReminder, isTrue);
    });

    test('user who dismissed current version should not see the card', () {
      final user = UserModel.fromMap(
        <String, dynamic>{
          'hasDismissedLoggingReminder': true,
          'dismissedLoggingReminderVersion': AppConstants.loggingReminderVersion,
        },
        'uid-3',
      );

      expect(user.shouldShowLoggingReminder, isFalse);
    });

    test('explicit version field takes precedence over legacy bool', () {
      final user = UserModel.fromMap(
        <String, dynamic>{
          'hasDismissedLoggingReminder': true,
          'dismissedLoggingReminderVersion': AppConstants.loggingReminderVersion,
        },
        'uid-4',
      );

      expect(user.dismissedLoggingReminderVersion, AppConstants.loggingReminderVersion);
      expect(user.shouldShowLoggingReminder, isFalse);
    });
  });
}
