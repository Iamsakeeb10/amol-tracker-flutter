import 'package:amol_tracker_app/core/constants/default_amal_fields.dart';
import 'package:amol_tracker_app/models/amal_log_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmalLogModel hive round-trip', () {
    test('preserves maxScore, activeFieldIds, specialTimeApplied', () {
      final log = AmalLogModel(
        uid: 'u1',
        displayName: 'Test',
        photoUrl: '',
        isAnonymousDisplay: false,
        hijriDate: '1447-01-01',
        toggles: const {'miswak': true, 'morning_azkar': true},
        score: 15,
        submittedAt: DateTime.utc(2026, 1, 1),
        maxScore: 25,
        activeFieldIds: const ['morning_azkar', 'evening_azkar', 'miswak'],
        specialTimeApplied: true,
      );

      final restored = AmalLogModel.fromHiveMap(log.toHiveMap());
      expect(restored.maxScore, 25);
      expect(restored.activeFieldIds, [
        'morning_azkar',
        'evening_azkar',
        'miswak',
      ]);
      expect(restored.specialTimeApplied, isTrue);
      expect(restored.score, 15);
      expect(restored.hijriDate, '1447-01-01');
    });

    test('legacy hive map without new fields falls back correctly', () {
      final legacy = <String, dynamic>{
        'uid': 'u1',
        'displayName': 'Legacy',
        'photoUrl': '',
        'isAnonymousDisplay': false,
        'hijriDate': '1446-12-01',
        'score': 80,
        'submittedAtMs': DateTime.utc(2025, 6, 1).millisecondsSinceEpoch,
        'toggles': <String, dynamic>{
          for (final id in kLegacyActiveFieldIds) id: true,
        },
      };

      final restored = AmalLogModel.fromHiveMap(legacy);
      expect(restored.maxScore, 100);
      expect(restored.activeFieldIds, kLegacyActiveFieldIds);
      expect(restored.specialTimeApplied, isFalse);
      expect(restored.score, 80);
    });

    test('toHiveMap always writes the three context fields', () {
      final log = AmalLogModel(
        uid: 'u1',
        displayName: 'Test',
        photoUrl: '',
        isAnonymousDisplay: false,
        hijriDate: '1447-01-02',
        toggles: const {},
        score: 0,
        submittedAt: DateTime.utc(2026, 1, 2),
      );
      final map = log.toHiveMap();
      expect(map.containsKey('maxScore'), isTrue);
      expect(map.containsKey('activeFieldIds'), isTrue);
      expect(map.containsKey('specialTimeApplied'), isTrue);
      expect(map['maxScore'], 100);
      expect(map['activeFieldIds'], kLegacyActiveFieldIds);
      expect(map['specialTimeApplied'], isFalse);
    });

    test('toFirestoreMap writes context fields for default fields', () {
      final log = AmalLogModel(
        uid: 'u1',
        displayName: 'Test',
        photoUrl: '',
        isAnonymousDisplay: false,
        hijriDate: '1447-01-03',
        toggles: const {'miswak': true},
        score: 5,
        submittedAt: DateTime.utc(2026, 1, 3),
        maxScore: 25,
        activeFieldIds: const ['morning_azkar', 'evening_azkar', 'miswak'],
        specialTimeApplied: true,
      );
      final map = log.toFirestoreMap(kDefaultAmalFields);
      expect(map['maxScore'], 25);
      expect(map['activeFieldIds'], [
        'morning_azkar',
        'evening_azkar',
        'miswak',
      ]);
      expect(map['specialTimeApplied'], isTrue);
    });
  });
}
