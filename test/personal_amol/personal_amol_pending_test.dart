import 'package:amol_tracker_app/providers/personal_amol_pending_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonalAmolPendingState.dirty', () {
    test('empty state is not dirty', () {
      const state = PersonalAmolPendingState();
      expect(state.dirty, isFalse);
    });

    test('an entry differing from baseline is dirty', () {
      const state = PersonalAmolPendingState(
        staged: {'a': 3},
        baseline: {'a': 0},
      );
      expect(state.dirty, isTrue);
    });

    test('an entry matching baseline is not dirty', () {
      const state = PersonalAmolPendingState(
        staged: {'a': 3},
        baseline: {'a': 3},
      );
      expect(state.dirty, isFalse);
    });
  });

  group('stagePersonalAmolValue', () {
    test('seeds baseline and stages the desired count', () {
      final next = stagePersonalAmolValue(
        staged: const {},
        baseline: const {},
        amolId: 'a',
        baseCount: 2,
        desired: 5,
      );
      expect(next.staged, {'a': 5});
      expect(next.baseline, {'a': 2});
    });

    test('updates an already staged amol against its seeded baseline', () {
      final next = stagePersonalAmolValue(
        staged: const {'a': 3},
        baseline: const {'a': 0},
        amolId: 'a',
        baseCount: 0,
        desired: 4,
      );
      expect(next.staged, {'a': 4});
      expect(next.baseline, {'a': 0});
    });

    test('returns to baseline removes the entry (no pending change)', () {
      final next = stagePersonalAmolValue(
        staged: const {'a': 3},
        baseline: const {'a': 0},
        amolId: 'a',
        baseCount: 0,
        desired: 0,
      );
      expect(next.staged, isEmpty);
      expect(next.baseline, isEmpty);
    });

    test('toggle off stages 0 against a baseline of 1', () {
      final next = stagePersonalAmolValue(
        staged: const {},
        baseline: const {},
        amolId: 't',
        baseCount: 1,
        desired: 0,
      );
      expect(next.staged, {'t': 0});
      expect(next.baseline, {'t': 1});
      expect(
        PersonalAmolPendingState(
          staged: next.staged,
          baseline: next.baseline,
        ).dirty,
        isTrue,
      );
    });
  });
}