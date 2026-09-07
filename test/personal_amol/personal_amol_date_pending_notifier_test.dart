import 'package:amol_tracker_app/models/personal_amol_model.dart';
import 'package:amol_tracker_app/providers/personal_amol_date_pending_provider.dart';
import 'package:amol_tracker_app/providers/personal_amol_pending_provider.dart';
import 'package:amol_tracker_app/providers/personal_amol_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const uid = 'test-uid';
  const hijriDate = '1447-03-15';

  ProviderContainer makeContainer({
    List<PersonalAmolCompletion> completions = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        personalAmolCompletionsForDateProvider.overrideWith(
          (ref, arg) async => completions,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Keeps the autoDispose completions provider alive and fully loaded so the
  /// notifier's synchronous `_baseFor` read sees the physical snapshot.
  Future<void> loaded(ProviderContainer container) async {
    final key = PersonalAmolDateKey(uid: uid, hijriDate: hijriDate);
    final sub = container.listen(
      personalAmolCompletionsForDateProvider(key),
      (_, _) {},
    );
    addTearDown(sub.close);
    await container.read(personalAmolCompletionsForDateProvider(key).future);
  }

  PersonalAmolModel countAmol(String id, {int target = 5}) {
    return PersonalAmolModel(
      id: id,
      name: id,
      icon: 'flag',
      frequency: PersonalAmolFrequency.daily,
      weekdays: const <int>[],
      reminderTime: null,
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 1),
      type: PersonalAmolType.count,
      target: target,
    );
  }

  PersonalAmolModel toggleAmol(String id) {
    return PersonalAmolModel(
      id: id,
      name: id,
      icon: 'flag',
      frequency: PersonalAmolFrequency.daily,
      weekdays: const <int>[],
      reminderTime: null,
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 1),
      type: PersonalAmolType.toggle,
    );
  }

  PersonalAmolDatePendingNotifier notifier(ProviderContainer c) => c.read(
    personalAmolDatePendingProvider(
      PersonalAmolDateEditKey(uid: uid, hijriDate: hijriDate),
    ).notifier,
  );

  PersonalAmolPendingState state(ProviderContainer c) => c.read(
    personalAmolDatePendingProvider(
      PersonalAmolDateEditKey(uid: uid, hijriDate: hijriDate),
    ),
  );

  test('edits are isolated per hijri date', () async {
    final container = makeContainer();
    await loaded(container);
    final otherDate = PersonalAmolDateEditKey(uid: uid, hijriDate: '1447-03-16');
    final n = notifier(container);
    n.plus(countAmol('a'));

    expect(
      container
          .read(personalAmolDatePendingProvider(otherDate))
          .staged,
      isEmpty,
    );
    expect(state(container).staged['a'], 1);
  });

  test('count plus then minus back to 0 clears the pending state', () async {
    final container = makeContainer();
    await loaded(container);
    final n = notifier(container);
    final amol = countAmol('a');

    n.plus(amol);
    expect(state(container).dirty, isTrue);

    n.minus(amol);
    final after = state(container);
    expect(after.dirty, isFalse);
    expect(after.staged, isEmpty);
    expect(after.baseline, isEmpty);
  });

  test('count plus clamps at the target', () async {
    final container = makeContainer(completions: [
      PersonalAmolCompletion(
        amolId: 'a',
        hijriDate: hijriDate,
        completedAt: DateTime.now(),
      ),
      PersonalAmolCompletion(
        amolId: 'a',
        hijriDate: hijriDate,
        completedAt: DateTime.now(),
      ),
    ]);
    await loaded(container);
    final n = notifier(container);
    final amol = countAmol('a', target: 3);

    n.plus(amol);
    n.plus(amol);
    n.plus(amol);
    expect(state(container).staged['a'], 3);

    n.plus(amol);
    expect(state(container).staged['a'], 3);
  });

  test('toggle off from a saved completion then back on is clean', () async {
    final container = makeContainer(completions: [
      PersonalAmolCompletion(
        amolId: 't',
        hijriDate: hijriDate,
        completedAt: DateTime.now(),
      ),
    ]);
    await loaded(container);
    final n = notifier(container);
    final amol = toggleAmol('t');

    n.toggle(amol);
    final off = state(container);
    expect(off.dirty, isTrue);
    expect(off.staged['t'], 0);
    expect(off.baseline['t'], 1);

    n.toggle(amol);
    final on = state(container);
    expect(on.dirty, isFalse);
    expect(on.staged, isEmpty);
  });

  test('minus never goes below 0', () async {
    final container = makeContainer();
    await loaded(container);
    final n = notifier(container);
    final amol = countAmol('a');

    n.minus(amol);
    final after = state(container);
    expect(after.dirty, isFalse);
    expect(after.staged, isEmpty);
  });
}
