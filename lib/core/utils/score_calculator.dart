import '../constants/amal_fields.dart';
import '../constants/default_amal_fields.dart';

int getNumericValue(dynamic rawValue, int maxValue) {
  if (rawValue == null) return 0;
  if (rawValue is bool) return rawValue ? maxValue : 0;
  if (rawValue is num) return rawValue.toInt().clamp(0, maxValue);
  return 0;
}

int getMaxScore(List<AmalField> fields) {
  final active = resolveAmalFields(fields);
  return active.fold<int>(0, (sum, field) => sum + field.points);
}

int calculateScore(Map<String, dynamic> log, List<AmalField> fields) {
  final active = resolveAmalFields(fields);
  var score = 0;
  for (final field in active) {
    if (field.type == AmalType.boolean) {
      if (log[field.id] == true) {
        score += field.points;
      }
    } else {
      final maxValue = field.maxValue <= 0 ? 1 : field.maxValue;
      final val = getNumericValue(log[field.id], maxValue);
      score += ((val / maxValue) * field.points).round();
    }
  }
  return score.clamp(0, kDefaultMaxDailyScore);
}

double scoreRatio(int score, List<AmalField> fields) {
  final max = getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);
  return (score / max).clamp(0.0, 1.0);
}

/// Resolve the effective set of lit prayer-circle indices for an expandable
/// field.
///
/// When the tracked [stored] selection is consistent with the authoritative
/// [count] (same size, all indices within range) it is used as-is so
/// independent toggles are preserved. Otherwise the selection is rebuilt as a
/// left-to-right fill of [count] circles — reconciling external changes such
/// as "mark all", "clear all", or a fresh reload where only the count is known.
Set<int> resolvePrayerSelection(Set<int>? stored, int count, int slots) {
  final safeCount = count.clamp(0, slots);
  if (stored != null &&
      stored.length == safeCount &&
      stored.every((i) => i >= 0 && i < slots)) {
    return stored;
  }
  return <int>{for (var i = 0; i < safeCount; i++) i};
}
