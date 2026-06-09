import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/constants/prayer_adhan_constants.dart';
import '../core/services/islamic_date_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/prayer_adhan_scheduler.dart';
import '../core/utils/prayer_adhan_time_helper.dart';
import 'notification_provider.dart';

class PrayerAdhanState {
  const PrayerAdhanState({
    required this.enabled,
    required this.usesCustomTime,
    required this.offsetMinutes,
    this.isMutating = false,
  });

  final Map<String, bool> enabled;
  final Map<String, bool> usesCustomTime;
  final int offsetMinutes;

  /// True while a persisted settings change is in flight.
  final bool isMutating;

  PrayerAdhanState copyWith({
    Map<String, bool>? enabled,
    Map<String, bool>? usesCustomTime,
    int? offsetMinutes,
    bool? isMutating,
  }) {
    return PrayerAdhanState(
      enabled: enabled ?? this.enabled,
      usesCustomTime: usesCustomTime ?? this.usesCustomTime,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      isMutating: isMutating ?? this.isMutating,
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
  int _pendingMutations = 0;

  /// Runs [mutation] after prior prayer-adhan changes finish so Hive + OS
  /// scheduling always reflect the latest combined settings.
  Future<void> _enqueueMutation(Future<void> Function() mutation) {
    _pendingMutations++;
    state = state.copyWith(isMutating: true);

    final next = _mutationChain!.then((_) async {
      try {
        await mutation();
      } finally {
        _pendingMutations--;
        if (_pendingMutations == 0) {
          state = state.copyWith(isMutating: false);
        }
      }
    });
    _mutationChain = next.catchError((_) {});
    return next;
  }

  DateTime get _todayBdDate {
    final now = IslamicDateService.nowInBD();
    return DateTime(now.year, now.month, now.day);
  }

  TimeOfDay reminderTimeToday(String prayer) {
    return PrayerAdhanTimeHelper.reminderTimeForDate(
      prayer: prayer,
      targetDate: _todayBdDate,
      scheduler: _scheduler,
    );
  }

  TimeOfDay baseTimeToday(String prayer) {
    return PrayerAdhanTimeHelper.baseTimeForDate(
      prayer: prayer,
      targetDate: _todayBdDate,
      scheduler: _scheduler,
    );
  }

  Future<void> setEnabled(String prayer, bool value) {
    return _enqueueMutation(() async {
      try {
        await _scheduler.setEnabled(prayer, value);
        state = state.copyWith(
          enabled: Map<String, bool>.from(state.enabled)..[prayer] = value,
        );
        await _notificationService.rescheduleAll();
      } catch (_) {
        refresh();
      }
    });
  }

  Future<void> setOffset(int minutes) {
    if (!PrayerAdhanConstants.offsetOptions.contains(minutes)) {
      return Future.value();
    }
    return _enqueueMutation(() async {
      try {
        await _scheduler.setOffsetMinutes(minutes);
        state = state.copyWith(offsetMinutes: minutes);
        await _notificationService.rescheduleAll();
      } catch (_) {
        refresh();
      }
    });
  }

  Future<void> setCustomTime(String prayer, TimeOfDay value) {
    return _enqueueMutation(() async {
      try {
        await _scheduler.setCustomTime(prayer, value);
        state = state.copyWith(
          usesCustomTime: Map<String, bool>.from(state.usesCustomTime)
            ..[prayer] = true,
        );
        await _notificationService.rescheduleAll();
      } catch (_) {
        refresh();
      }
    });
  }

  Future<void> clearCustomTime(String prayer) {
    return _enqueueMutation(() async {
      try {
        await _scheduler.clearCustomTime(prayer);
        state = state.copyWith(
          usesCustomTime: Map<String, bool>.from(state.usesCustomTime)
            ..[prayer] = false,
        );
        await _notificationService.rescheduleAll();
      } catch (_) {
        refresh();
      }
    });
  }

  void refresh() {
    state = PrayerAdhanState(
      enabled: _scheduler.allEnabled,
      usesCustomTime: _scheduler.allCustomTimeFlags,
      offsetMinutes: _scheduler.offsetMinutes,
    );
  }
}
