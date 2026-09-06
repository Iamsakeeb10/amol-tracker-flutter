import 'package:flutter/material.dart';

/// Preferred evening windows for action-oriented amal reminders.
/// After Esha (~8–9 PM), 5 prayers are typically complete.
/// Streak reminders are therefore pushed to 9:15 PM and 9:45 PM so they
/// fire after the last prayer rather than during it.
const TimeOfDay eveningCloseReminderTime = TimeOfDay(hour: 21, minute: 15);
const TimeOfDay eveningLastChanceReminderTime = TimeOfDay(hour: 21, minute: 45);

/// Whether today's Islamic-day reminders should be suppressed.
///
/// After midnight, a log on yesterday's Hijri key means the previous day is
/// complete — it does **not** count as logging today.
bool hasLoggedCurrentIslamicDay({
  required String todayHijri,
  required String lastLogDate,
}) {
  return lastLogDate.isNotEmpty && lastLogDate == todayHijri;
}

/// Avoids a second prompt when the Maghrib/custom reminder already provides
/// a cue near the 8 PM habit-closing slot.
bool shouldScheduleEveningClose({
  required bool dailyEveningReminderEnabled,
  required TimeOfDay dailyEveningReminderTime,
}) {
  if (!dailyEveningReminderEnabled) return true;
  return (_minutes(dailyEveningReminderTime) -
              _minutes(eveningCloseReminderTime))
          .abs() >
      45;
}

/// Avoids placing the 9:45 PM prompt beside a user-selected evening reminder.
/// Suppressed when the custom time falls within ±30 min of the last-chance
/// slot (i.e. between 9:15 PM and 10:15 PM).
bool shouldScheduleEveningLastChance({
  required bool dailyEveningReminderEnabled,
  required bool hasCustomEveningTime,
  required TimeOfDay dailyEveningReminderTime,
}) {
  if (!dailyEveningReminderEnabled || !hasCustomEveningTime) return true;
  final minutes = _minutes(dailyEveningReminderTime);
  return minutes < 21 * 60 + 15 || minutes > 22 * 60 + 15;
}

/// A single catch-up may be sent after the regular slots, but never after
/// 10 PM when a reminder is more likely to interrupt sleep than help action.
bool shouldScheduleEveningCatchUp(TimeOfDay now) {
  final minutes = _minutes(now);
  return minutes >= _minutes(eveningLastChanceReminderTime) &&
      minutes < 22 * 60;
}

int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
