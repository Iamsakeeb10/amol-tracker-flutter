import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/constants/prayer_adhan_constants.dart';
import '../core/services/islamic_date_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/prayer_adhan_scheduler.dart';
import '../core/utils/quiet_hours_helper.dart';
import 'notification_provider.dart';

class PrayerAdhanState {
  const PrayerAdhanState({
    required this.enabled,
    required this.usesCustomTime,
    required this.offsetMinutes,
    this.savingPrayers = const {},
  });

  final Map<String, bool> enabled;
  final Map<String, bool> usesCustomTime;
  final int offsetMinutes;

  /// Prayer keys awaiting background notification reschedule.
  final Set<String> savingPrayers;

  PrayerAdhanState copyWith({
    Map<String, bool>? enabled,
    Map<String, bool>? usesCustomTime,
    int? offsetMinutes,
    Set<String>? savingPrayers,
  }) {
    return PrayerAdhanState(
      enabled: enabled ?? this.enabled,
      usesCustomTime: usesCustomTime ?? this.usesCustomTime,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      savingPrayers: savingPrayers ?? this.savingPrayers,
    );
  }
}

final prayerAdhanProvider =
    StateNotifierProvider<PrayerAdhanNotifier, PrayerAdhanState>((ref) {
      return PrayerAdhanNotifier(
        ref.read(prayerAdhanSchedulerProvider),
        ref.read(notificationServiceProvider),
      );
    });

final prayerAdhanSchedulerProvider = Provider<PrayerAdhanScheduler>(
  (ref) => PrayerAdhanScheduler.instance,
);

class PrayerAdhanNotifier extends StateNotifier<PrayerAdhanState> {
  PrayerAdhanNotifier(this._scheduler, this._notificationService)
    : super(
        PrayerAdhanState(
          enabled: _scheduler.allEnabled,
          usesCustomTime: _scheduler.allCustomTimeFlags,
          offsetMinutes: _scheduler.offsetMinutes,
        ),
      );

  final PrayerAdhanScheduler _scheduler;
  final NotificationService _notificationService;

  Future<void>? _mutationChain = Future.value();

  /// Optimistic custom times pending Hive persistence. Absent key = use Hive;
  /// non-null value = custom time; null value = custom cleared.
  final Map<String, TimeOfDay?> _optimisticCustomTimes = {};

  /// In-flight reschedule jobs per prayer; spinner stays until all complete.
  final Map<String, int> _savingCounts = {};

  /// Runs [mutation] after prior prayer-adhan reschedule jobs finish.
  Future<void> _enqueueMutation(Future<void> Function() mutation) {
    final next = _mutationChain!.then((_) => mutation());
    _mutationChain = next.catchError((_) {});
    return next;
  }

  void _markSaving(Set<String> prayers) {
    for (final prayer in prayers) {
      _savingCounts[prayer] = (_savingCounts[prayer] ?? 0) + 1;
    }
    state = state.copyWith(savingPrayers: _savingCounts.keys.toSet());
  }

  void _clearSaving(Set<String> prayers) {
    var changed = false;
    for (final prayer in prayers) {
      final next = (_savingCounts[prayer] ?? 0) - 1;
      if (next <= 0) {
        changed = _savingCounts.remove(prayer) != null || changed;
      } else {
        _savingCounts[prayer] = next;
        changed = true;
      }
    }
    if (changed) {
      state = state.copyWith(savingPrayers: _savingCounts.keys.toSet());
    }
  }

  Future<void> _enqueueReschedule({required Set<String> savingKeys}) {
    return _enqueueMutation(() async {
      try {
        await _notificationService.rescheduleAll();
      } catch (_) {
        refresh();
      } finally {
        _clearSaving(savingKeys);
      }
    });
  }

  DateTime get _todayBdDate {
    final now = IslamicDateService.nowInBD();
    return DateTime(now.year, now.month, now.day);
  }

  TimeOfDay reminderTimeToday(String prayer) {
    final base = baseTimeToday(prayer);
    final offset = state.offsetMinutes;
    final totalMinutes = base.hour * 60 + base.minute + offset;
    final normalized = totalMinutes % (24 * 60);
    final adjusted = normalized < 0 ? normalized + 24 * 60 : normalized;
    return TimeOfDay(
      hour: adjusted ~/ 60,
      minute: adjusted % 60,
    );
  }

  TimeOfDay baseTimeToday(String prayer) {
    if (_optimisticCustomTimes.containsKey(prayer)) {
      final optimistic = _optimisticCustomTimes[prayer];
      if (optimistic != null) return optimistic;
    } else {
      final custom = _scheduler.getCustomTime(prayer);
      if (custom != null) return custom;
    }

    final times = IslamicDateService.getPrayerTimesForDate(_todayBdDate);
    final prayerTime = times.forPrayer(prayer);
    return TimeOfDay(hour: prayerTime.hour, minute: prayerTime.minute);
  }

  /// True when today's reminder for [prayer] falls inside quiet hours and
  /// will not be scheduled even if the prayer toggle is on.
  bool isReminderSuppressedToday(String prayer) {
    if (!(state.enabled[prayer] ?? false)) return false;
    return QuietHoursHelper.isSuppressed(
      reminderTimeToday(prayer),
      from: _notificationService.quietFrom,
      to: _notificationService.quietTo,
    );
  }

  Future<void> setEnabled(String prayer, bool value) async {
    final saving = {prayer};
    state = state.copyWith(
      enabled: Map<String, bool>.from(state.enabled)..[prayer] = value,
    );
    _markSaving(saving);
    try {
      await _scheduler.setEnabled(prayer, value);
    } catch (_) {
      refresh();
      return;
    }
    return _enqueueReschedule(savingKeys: saving);
  }

  Future<void> setOffset(int minutes) async {
    if (!PrayerAdhanConstants.offsetOptions.contains(minutes)) {
      return;
    }
    final saving = PrayerAdhanConstants.prayerKeys.toSet();
    state = state.copyWith(offsetMinutes: minutes);
    _markSaving(saving);
    try {
      await _scheduler.setOffsetMinutes(minutes);
    } catch (_) {
      refresh();
      return;
    }
    return _enqueueReschedule(savingKeys: saving);
  }

  Future<void> setCustomTime(String prayer, TimeOfDay value) async {
    final saving = {prayer};
    _optimisticCustomTimes[prayer] = value;
    state = state.copyWith(
      usesCustomTime: Map<String, bool>.from(state.usesCustomTime)
        ..[prayer] = true,
    );
    _markSaving(saving);
    try {
      await _scheduler.setCustomTime(prayer, value);
      _optimisticCustomTimes.remove(prayer);
    } catch (_) {
      _optimisticCustomTimes.remove(prayer);
      refresh();
      return;
    }
    return _enqueueReschedule(savingKeys: saving);
  }

  Future<void> clearCustomTime(String prayer) async {
    final saving = {prayer};
    _optimisticCustomTimes[prayer] = null;
    state = state.copyWith(
      usesCustomTime: Map<String, bool>.from(state.usesCustomTime)
        ..[prayer] = false,
    );
    _markSaving(saving);
    try {
      await _scheduler.clearCustomTime(prayer);
      _optimisticCustomTimes.remove(prayer);
    } catch (_) {
      _optimisticCustomTimes.remove(prayer);
      refresh();
      return;
    }
    return _enqueueReschedule(savingKeys: saving);
  }

  void refresh() {
    _optimisticCustomTimes.clear();
    _savingCounts.clear();
    state = PrayerAdhanState(
      enabled: _scheduler.allEnabled,
      usesCustomTime: _scheduler.allCustomTimeFlags,
      offsetMinutes: _scheduler.offsetMinutes,
    );
  }
}
