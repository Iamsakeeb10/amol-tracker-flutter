import '../../models/amal_log_model.dart';

/// Canonical prayer slot labels in daily order.
const List<String> kPrayerKeys = [
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
];

/// Completion statistics for a single prayer slot across a list of logs.
class PrayerStat {
  const PrayerStat({
    required this.prayerKey,
    required this.doneCount,
    required this.eligibleDays,
  });

  /// Prayer identifier: one of [kPrayerKeys].
  final String prayerKey;

  /// Number of days this prayer was performed.
  final int doneCount;

  /// Number of days the parent field had any value (≥ 1 prayer attempted).
  final int eligibleDays;

  /// Completion rate in [0, 1]. Safe — returns 0 when eligibleDays == 0.
  double get rate => eligibleDays == 0 ? 0 : doneCount / eligibleDays;
}

/// Pure computation helper — no Flutter dependencies, easy to unit-test.
///
/// Computes per-prayer-slot completion stats for a single expandable amal
/// field (e.g. `fard_salah`) across a list of submitted logs.
///
/// Logs that pre-date prayer tracking (i.e. `log.prayers` is empty) are
/// treated as "prayer data unavailable" — they do not contribute to either
/// [PrayerStat.doneCount] or [PrayerStat.eligibleDays].  This keeps rates
/// accurate for the subset of logs that actually have per-prayer data.
class PrayerAnalytics {
  PrayerAnalytics._();

  /// Returns one [PrayerStat] per prayer slot (always [slotCount] entries).
  ///
  /// [fieldId]   — e.g. `'fard_salah'`.
  /// [slotCount] — number of prayer slots for this field (typically 5).
  static List<PrayerStat> compute({
    required List<AmalLogModel> logs,
    required String fieldId,
    int slotCount = 5,
  }) {
    final clampedSlots = slotCount.clamp(1, kPrayerKeys.length);

    // Only include logs that have per-prayer data for this field.
    final relevant = logs
        .where((log) => log.prayers.containsKey(fieldId))
        .toList();

    // Eligible = any log that has prayers data for this field.
    final eligible = relevant.length;

    // Tally done count per slot index.
    final doneCounts = List<int>.filled(clampedSlots, 0);
    for (final log in relevant) {
      for (final slotIndex in log.prayers[fieldId]!) {
        if (slotIndex >= 0 && slotIndex < clampedSlots) {
          doneCounts[slotIndex]++;
        }
      }
    }

    return List<PrayerStat>.generate(clampedSlots, (i) {
      return PrayerStat(
        prayerKey: kPrayerKeys[i],
        doneCount: doneCounts[i],
        eligibleDays: eligible,
      );
    });
  }

  /// Whether any of [logs] contains per-prayer data for [fieldId].
  static bool hasPrayerData(List<AmalLogModel> logs, String fieldId) {
    return logs.any((log) => log.prayers.containsKey(fieldId));
  }
}
