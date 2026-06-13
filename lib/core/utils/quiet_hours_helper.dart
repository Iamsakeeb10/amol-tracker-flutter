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
}
