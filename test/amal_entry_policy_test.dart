import 'package:amol_tracker_app/core/constants/amal_fields.dart';
import 'package:amol_tracker_app/core/constants/default_amal_fields.dart';
import 'package:amol_tracker_app/core/utils/amal_entry_policy.dart';
import 'package:amol_tracker_app/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fields = kDefaultAmalFields;

  group('AmalEntryPolicy.from', () {
    test('unset profile shows all fields as main', () {
      final policy = AmalEntryPolicy.from(UserAmalProfile.unset, fields);
      expect(policy.mainFields.length, fields.length);
      expect(policy.optionalFields, isEmpty);
      expect(policy.inactiveSpecialTimeFields, isEmpty);
      expect(policy.activeFields.length, fields.length);
      expect(policy.isSpecialTimeActive, isFalse);
    });

    test('male profile shows all fields as main regardless of specialTime', () {
      final off = AmalEntryPolicy.from(
        UserAmalProfile.male,
        fields,
        specialTimeActive: false,
      );
      final on = AmalEntryPolicy.from(
        UserAmalProfile.male,
        fields,
        specialTimeActive: true,
      );
      expect(off.mainFields.length, fields.length);
      expect(off.optionalFields, isEmpty);
      expect(off.inactiveSpecialTimeFields, isEmpty);
      expect(off.isSpecialTimeActive, isFalse);
      expect(on.mainFields.length, fields.length);
      expect(on.optionalFields, isEmpty);
      expect(on.inactiveSpecialTimeFields, isEmpty);
      expect(on.isSpecialTimeActive, isFalse);
    });

    test('female + specialTime off puts deprioritized fields in optional', () {
      final policy = AmalEntryPolicy.from(
        UserAmalProfile.female,
        fields,
        specialTimeActive: false,
      );
      expect(policy.isSpecialTimeActive, isFalse);
      expect(policy.inactiveSpecialTimeFields, isEmpty);
      expect(
        policy.optionalFields.map((f) => f.id).toSet(),
        {'fard', 'takbir'},
      );
      expect(policy.mainFields.first.id, 'fard_salah');
      expect(
        policy.mainFields.every((f) => !f.femaleDeprioritized),
        isTrue,
      );
      expect(
        policy.activeFields.length,
        policy.mainFields.length + policy.optionalFields.length,
      );
    });

    test('female + specialTime on disables special-time fields', () {
      final policy = AmalEntryPolicy.from(
        UserAmalProfile.female,
        fields,
        specialTimeActive: true,
      );
      expect(policy.isSpecialTimeActive, isTrue);
      expect(policy.optionalFields, isEmpty);
      expect(
        policy.inactiveSpecialTimeFields.every((f) => f.disableDuringSpecialTime),
        isTrue,
      );
      expect(
        policy.activeFields.map((f) => f.id).toSet(),
        {'morning_azkar', 'evening_azkar', 'miswak'},
      );
      expect(policy.activeFields, policy.mainFields);
    });

    test('genderVisibility filters maleOnly / femaleOnly fields', () {
      final maleOnly = AmalField(
        id: 'male_only_field',
        label: const {'en': 'Male', 'bn': 'Male'},
        sublabel: const {'en': '', 'bn': ''},
        points: 5,
        genderVisibility: GenderVisibility.maleOnly,
      );
      final femaleOnly = AmalField(
        id: 'female_only_field',
        label: const {'en': 'Female', 'bn': 'Female'},
        sublabel: const {'en': '', 'bn': ''},
        points: 5,
        genderVisibility: GenderVisibility.femaleOnly,
      );
      final shared = AmalField(
        id: 'shared',
        label: const {'en': 'Shared', 'bn': 'Shared'},
        sublabel: const {'en': '', 'bn': ''},
        points: 5,
      );
      final mixed = <AmalField>[maleOnly, femaleOnly, shared];

      final male = AmalEntryPolicy.from(UserAmalProfile.male, mixed);
      expect(male.activeFieldIds.toSet(), {'male_only_field', 'shared'});

      final female = AmalEntryPolicy.from(UserAmalProfile.female, mixed);
      expect(female.activeFieldIds.toSet(), {'female_only_field', 'shared'});

      final unset = AmalEntryPolicy.from(UserAmalProfile.unset, mixed);
      expect(
        unset.activeFieldIds.toSet(),
        {'male_only_field', 'female_only_field', 'shared'},
      );
    });
  });
}
