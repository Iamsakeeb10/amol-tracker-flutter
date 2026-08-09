import '../constants/amal_fields.dart';

int getNumericValue(dynamic rawValue, int maxValue) {
  if (rawValue == null) return 0;
  if (rawValue is bool) return rawValue ? maxValue : 0;
  if (rawValue is num) return rawValue.toInt().clamp(0, maxValue);
  return 0;
}

class AmalScoreResult {
  final int score;
  final int maxScore;
  final List<String> activeFieldIds;

  const AmalScoreResult({
    required this.score,
    required this.maxScore,
    required this.activeFieldIds,
  });
}

AmalScoreResult calculateAmalScore({
  required Map<String, dynamic> toggles,
  required List<AmalField> activeFields,
}) {
  var score = 0;
  final activeFieldIds = <String>[];
  for (final field in activeFields) {
    activeFieldIds.add(field.id);
    if (field.type == AmalType.boolean) {
      if (toggles[field.id] == true) {
        score += field.points;
      }
    } else {
      final maxValue = field.maxValue <= 0 ? 1 : field.maxValue;
      final val = getNumericValue(toggles[field.id], maxValue);
      score += ((val / maxValue) * field.points).round();
    }
  }
  final maxScore = activeFields.fold<int>(0, (sum, field) => sum + field.points);
  return AmalScoreResult(
    score: score,
    maxScore: maxScore,
    activeFieldIds: activeFieldIds,
  );
}

Set<int> resolvePrayerSelection(Set<int>? stored, int count, int slots) {
  final safeCount = count.clamp(0, slots);
  if (stored != null &&
      stored.length == safeCount &&
      stored.every((i) => i >= 0 && i < slots)) {
    return stored;
  }
  return <int>{for (var i = 0; i < safeCount; i++) i};
}
