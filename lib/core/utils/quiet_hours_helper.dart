import 'package:flutter/material.dart';

class QuietHoursHelper {
  QuietHoursHelper._();

  /// Returns true when [time] falls inside the quiet window [from]..[to].
  /// Supports overnight windows (e.g. 22:30 → 05:00). Equal from/to disables suppression.
  static bool isSuppressed(
    TimeOfDay time, {
    required TimeOfDay from,
    required TimeOfDay to,
  }) {
    final fromMin = from.hour * 60 + from.minute;
    final toMin = to.hour * 60 + to.minute;
    final value = time.hour * 60 + time.minute;
    if (fromMin == toMin) return false;
    if (fromMin < toMin) return value >= fromMin && value < toMin;
    return value >= fromMin || value < toMin;
  }

  /// Slot for a midnight-relative reminder that must still fire **today**.
  ///
  /// If [desired] is outside quiet hours, it is used as-is. If it falls inside
  /// the quiet window, returns [from] minus [fallbackMinutes] on the same
  /// calendar day. Returns null when no same-day slot exists — callers must
  /// skip rather than shifting to after midnight (the day would already have
  /// ended).
  static TimeOfDay? sameDayTimeBeforeQuietHours(
    TimeOfDay desired, {
    required TimeOfDay from,
    required TimeOfDay to,
    int fallbackMinutes = 5,
  }) {
    if (!isSuppressed(desired, from: from, to: to)) return desired;

    final fromMin = from.hour * 60 + from.minute;
    final fallbackMin = fromMin - fallbackMinutes;
    if (fallbackMin < 0) return null;

    final fallback = TimeOfDay(
      hour: fallbackMin ~/ 60,
      minute: fallbackMin % 60,
    );
    if (isSuppressed(fallback, from: from, to: to)) return null;
    return fallback;
  }
}
