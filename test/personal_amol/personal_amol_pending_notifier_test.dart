import 'dart:io';

import 'package:amol_tracker_app/models/personal_amol_model.dart';
import 'package:amol_tracker_app/providers/date_provider.dart';
import 'package:amol_tracker_app/providers/personal_amol_pending_provider.dart';
import 'package:amol_tracker_app/providers/personal_amol_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  const uid = 'test-uid';
  const today = '1447-03-15';

  ProviderContainer makeContainer({
    List<PersonalAmolCompletion> completions = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        currentHijriDateProvider.overrideWithValue(today),
        personalAmolCompletionsForTodayProvider.overrideWith(
          (ref, arg) => Stream.value(completions),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Keeps the autoDispose completions provider alive and fully loaded so the
  /// notifier's synchronous `_baseFor` read sees the physical snapshot.
  Future<void> loaded(ProviderContainer container) async {
    final sub = container.listen(
      personalAmolCompletionsForTodayProvider(uid),
      (_, _) {},
    );
    addTearDown(sub.close);
    await container.read(personalAmolCompletionsForTodayProvider(uid).future);
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

  setUpAll(() {
    final tmp = Directory.systemTemp.createTempSync('personal_amol_hive_test');
    Hive.init(tmp.path);
  });

  setUp(() async {
    if (!Hive.isBoxOpen('amal_logs')) {
      await Hive.openBox('amal_logs');
    } else {
      await Hive.box('amal_logs').clear();
    }
  });

  test('count plus then minus back to 0 clears the pending state', () async {
    final container = makeContainer();
    await loaded(container);
    final notifier = container.read(personalAmolPendingProvider(uid).notifier);
    final amol = countAmol('a');

    notifier.plus(amol);
    expect(container.read(personalAmolPendingProvider(uid)).dirty, isTrue);

    notifier.minus(amol);
    final after = container.read(personalAmolPendingProvider(uid));
    expect(after.dirty, isFalse);
    expect(after.staged, isEmpty);
    expect(after.baseline, isEmpty);
  });

  test('count multi-step increments fully reverted are clean', () async {
    final container = makeContainer();
    await loaded(container);
    final notifier = container.read(personalAmolPendingProvider(uid).notifier);
    final amol = countAmol('a');

    notifier.plus(amol);
    notifier.plus(amol);
    notifier.plus(amol);
    expect(container.read(personalAmolPendingProvider(uid)).dirty, isTrue);

    notifier.minus(amol);
    notifier.minus(amol);
    notifier.minus(amol);
    final after = container.read(personalAmolPendingProvider(uid));
    expect(after.dirty, isFalse);
    expect(after.staged, isEmpty);
  });

  test('toggle on then off returns to clean', () async {
    final container = makeContainer();
    await loaded(container);
    final notifier = container.read(personalAmolPendingProvider(uid).notifier);
    final amol = toggleAmol('t');

    notifier.toggle(amol);
    expect(container.read(personalAmolPendingProvider(uid)).dirty, isTrue);

    notifier.toggle(amol);
    final after = container.read(personalAmolPendingProvider(uid));
    expect(after.dirty, isFalse);
    expect(after.staged, isEmpty);
  });

  test('toggle off from a saved completion then back on is clean', () async {
    final container = makeContainer(
      completions: [
        PersonalAmolCompletion(
          amolId: 't',
          hijriDate: today,
          completedAt: DateTime.now(),
        ),
      ],
    );
    await loaded(container);
    final notifier = container.read(personalAmolPendingProvider(uid).notifier);
    final amol = toggleAmol('t');

    notifier.toggle(amol);
    final off = container.read(personalAmolPendingProvider(uid));
    expect(off.dirty, isTrue);
    expect(off.staged['t'], 0);
    expect(off.baseline['t'], 1);

    notifier.toggle(amol);
    final on = container.read(personalAmolPendingProvider(uid));
    expect(on.dirty, isFalse);
    expect(on.staged, isEmpty);
  });

  test('draft is restored from Hive on a new provider instance', () async {
    final container = makeContainer();
    await loaded(container);
    final notifier = container.read(personalAmolPendingProvider(uid).notifier);
    notifier.plus(countAmol('a'));
    await Future<void>.delayed(Duration.zero);

    final restored = makeContainer();
    final state = restored.read(personalAmolPendingProvider(uid));
    expect(state.staged['a'], 1);
    expect(state.baseline['a'], 0);
    expect(state.dirty, isTrue);
  });
}