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
