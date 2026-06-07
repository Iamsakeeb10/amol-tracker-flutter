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
  });

  final Map<String, bool> enabled;
  final Map<String, bool> usesCustomTime;
  final int offsetMinutes;

  PrayerAdhanState copyWith({
    Map<String, bool>? enabled,
    Map<String, bool>? usesCustomTime,
    int? offsetMinutes,
  }) {
    return PrayerAdhanState(
      enabled: enabled ?? this.enabled,
      usesCustomTime: usesCustomTime ?? this.usesCustomTime,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
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

  Future<void> setEnabled(String prayer, bool value) async {
    final previous = state;
    final nextEnabled = Map<String, bool>.from(state.enabled)..[prayer] = value;
    state = state.copyWith(enabled: nextEnabled);
    try {
      await _scheduler.setEnabled(prayer, value);
      await _notificationService.rescheduleAll();
    } catch (_) {
      state = previous;
    }
  }

  Future<void> setOffset(int minutes) async {
    if (!PrayerAdhanConstants.offsetOptions.contains(minutes)) return;
    final previous = state;
    state = state.copyWith(offsetMinutes: minutes);
    try {
      await _scheduler.setOffsetMinutes(minutes);
      await _notificationService.rescheduleAll();
    } catch (_) {
      state = previous;
    }
  }

  Future<void> setCustomTime(String prayer, TimeOfDay value) async {
    final previous = state;
    final nextCustom = Map<String, bool>.from(state.usesCustomTime)
      ..[prayer] = true;
    state = state.copyWith(usesCustomTime: nextCustom);
    try {
      await _scheduler.setCustomTime(prayer, value);
      await _notificationService.rescheduleAll();
    } catch (_) {
      state = previous;
    }
  }

  Future<void> clearCustomTime(String prayer) async {
    final previous = state;
    final nextCustom = Map<String, bool>.from(state.usesCustomTime)
      ..[prayer] = false;
    state = state.copyWith(usesCustomTime: nextCustom);
    try {
      await _scheduler.clearCustomTime(prayer);
      await _notificationService.rescheduleAll();
    } catch (_) {
      state = previous;
    }
  }

  void refresh() {
    state = PrayerAdhanState(
      enabled: _scheduler.allEnabled,
      usesCustomTime: _scheduler.allCustomTimeFlags,
      offsetMinutes: _scheduler.offsetMinutes,
    );
  }
}
