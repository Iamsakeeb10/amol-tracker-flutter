import 'package:flutter/material.dart';

import '../services/islamic_date_service.dart';
import '../services/prayer_adhan_scheduler.dart';

class PrayerAdhanTimeHelper {
  PrayerAdhanTimeHelper._();

  static TimeOfDay baseTimeForDate({
    required String prayer,
    required DateTime targetDate,
    required PrayerAdhanScheduler scheduler,
  }) {
    final custom = scheduler.getCustomTime(prayer);
    if (custom != null) return custom;

    final times = IslamicDateService.getPrayerTimesForDate(targetDate);
    final prayerTime = times.forPrayer(prayer);
    return TimeOfDay(hour: prayerTime.hour, minute: prayerTime.minute);
  }

  static TimeOfDay reminderTimeForDate({
    required String prayer,
    required DateTime targetDate,
    required PrayerAdhanScheduler scheduler,
  }) {
    final base = baseTimeForDate(
      prayer: prayer,
      targetDate: targetDate,
      scheduler: scheduler,
    );
    final offset = scheduler.offsetMinutes;
    final totalMinutes = base.hour * 60 + base.minute + offset;
    final normalized = totalMinutes % (24 * 60);
    final adjusted = normalized < 0 ? normalized + 24 * 60 : normalized;
    return TimeOfDay(
      hour: adjusted ~/ 60,
      minute: adjusted % 60,
    );
  }

  static DateTime reminderDateTimeForDate({
    required String prayer,
    required DateTime targetDate,
    required PrayerAdhanScheduler scheduler,
  }) {
    final reminder = reminderTimeForDate(
      prayer: prayer,
      targetDate: targetDate,
      scheduler: scheduler,
    );
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      reminder.hour,
      reminder.minute,
    );
  }
}
