import 'package:amol_tracker_app/models/personal_amol_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonalAmolModel type/target', () {
    PersonalAmolModel amol({PersonalAmolType type = PersonalAmolType.count, int target = 5}) =>
        PersonalAmolModel(
          id: 'a1',
          name: 'Quran',
          icon: 'm:menu_book',
          frequency: PersonalAmolFrequency.daily,
          weekdays: const <int>[],
          reminderTime: null,
          isActive: true,
          createdAt: DateTime.utc(2026, 1, 1),
          type: type,
          target: target,
        );

    test('toFirestoreMap persists type and target', () {
      final map = amol().toFirestoreMap();
      expect(map['type'], 'count');
      expect(map['target'], 5);
      expect(map['icon'], 'm:menu_book');
    });

    test('toggle amols default target to 1', () {
      final map = amol(type: PersonalAmolType.toggle, target: 1).toFirestoreMap();
      expect(map['type'], 'toggle');
      expect(map['target'], 1);
    });

    test('copyWith preserves type/target unless overridden', () {
      final renamed = amol().copyWith(name: 'Dua');
      expect(renamed.type, PersonalAmolType.count);
      expect(renamed.target, 5);
      expect(renamed.name, 'Dua');

      final toggled = amol().copyWith(
        type: PersonalAmolType.toggle,
        target: 1,
      );
      expect(toggled.type, PersonalAmolType.toggle);
      expect(toggled.target, 1);
    });

    test('copyWith can set and clear reminderTime', () {
      final withReminder = amol().copyWith(
        reminderTime: (hour: 8, minute: 30),
      );
      expect(withReminder.reminderTime?.hour, 8);
      expect(withReminder.reminderTime?.minute, 30);

      final cleared = withReminder.copyWith(reminderTime: null);
      expect(cleared.reminderTime, isNull);

      final preserved = withReminder.copyWith(name: 'Kept');
      expect(preserved.reminderTime?.hour, 8);
      expect(preserved.name, 'Kept');
    });

    test('enum fromMap defaults unknown/missing values to toggle', () {
      expect(PersonalAmolType.fromMap('count'), PersonalAmolType.count);
      expect(PersonalAmolType.fromMap('toggle'), PersonalAmolType.toggle);
      expect(PersonalAmolType.fromMap(null), PersonalAmolType.toggle);
      expect(PersonalAmolType.fromMap('whatever'), PersonalAmolType.toggle);
    });
  });
}