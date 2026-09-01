import 'package:flutter/material.dart';

/// Preferred evening windows for action-oriented amal reminders.
const TimeOfDay eveningCloseReminderTime = TimeOfDay(hour: 20, minute: 0);
const TimeOfDay eveningLastChanceReminderTime = TimeOfDay(hour: 20, minute: 45);

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

/// Avoids placing the 8:45 PM prompt beside a user-selected evening reminder.
bool shouldScheduleEveningLastChance({
  required bool dailyEveningReminderEnabled,
  required bool hasCustomEveningTime,
  required TimeOfDay dailyEveningReminderTime,
}) {
  if (!dailyEveningReminderEnabled || !hasCustomEveningTime) return true;
  final minutes = _minutes(dailyEveningReminderTime);
  return minutes < 20 * 60 + 30 || minutes > 21 * 60;
}

/// A single catch-up may be sent after the regular slots, but never after
/// 10 PM when a reminder is more likely to interrupt sleep than help action.
bool shouldScheduleEveningCatchUp(TimeOfDay now) {
  final minutes = _minutes(now);
  return minutes >= _minutes(eveningLastChanceReminderTime) &&
      minutes < 22 * 60;
}

int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
