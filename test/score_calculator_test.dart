import 'package:amol_tracker_app/core/constants/amal_fields.dart';
import 'package:amol_tracker_app/core/constants/default_amal_fields.dart';
import 'package:amol_tracker_app/core/utils/amal_entry_policy.dart';
import 'package:amol_tracker_app/core/utils/score_calculator.dart';
import 'package:amol_tracker_app/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateAmalScore', () {
    test('full default set with all done scores to 100', () {
      final fields = kDefaultAmalFields;
      final toggles = <String, dynamic>{
        for (final f in fields)
          f.id: f.type == AmalType.numeric ? f.maxValue : true,
      };
      final result = calculateAmalScore(
        toggles: toggles,
        activeFields: fields,
      );
      expect(result.maxScore, 100);
      expect(result.score, 100);
      expect(result.activeFieldIds.length, fields.length);
    });

    test('special-time reduced set uses only active field points', () {
      final policy = AmalEntryPolicy.from(
        UserAmalProfile.female,
        kDefaultAmalFields,
        specialTimeActive: true,
      );
      final toggles = <String, dynamic>{
        for (final f in policy.activeFields)
          f.id: f.type == AmalType.numeric ? f.maxValue : true,
      };
      final result = calculateAmalScore(
        toggles: toggles,
        activeFields: policy.activeFields,
      );
      // morning_azkar(10) + evening_azkar(10) + miswak(5) = 25
      expect(result.maxScore, 25);
      expect(result.score, 25);
      expect(result.activeFieldIds.toSet(), {
        'morning_azkar',
        'evening_azkar',
        'miswak',
      });
    });

    test('numeric partial progress rounds by ratio', () {
      final field = AmalField(
        id: 'quran',
        label: const {'en': 'Quran', 'bn': 'Quran'},
        sublabel: const {'en': '', 'bn': ''},
        points: 10,
        maxValue: 4,
        type: AmalType.numeric,
      );
      final result = calculateAmalScore(
        toggles: {'quran': 2},
        activeFields: [field],
      );
      expect(result.maxScore, 10);
      expect(result.score, 5);
    });

    test('inactive toggles do not contribute when not in activeFields', () {
      final active = kDefaultAmalFields
          .where((f) => f.id == 'miswak')
          .toList();
      final result = calculateAmalScore(
        toggles: {
          'miswak': true,
          'quran': true,
          'fard_salah': 5,
        },
        activeFields: active,
      );
      expect(result.score, 5);
      expect(result.maxScore, 5);
      expect(result.activeFieldIds, ['miswak']);
    });
  });
}
