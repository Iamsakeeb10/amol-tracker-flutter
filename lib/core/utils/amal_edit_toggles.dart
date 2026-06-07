import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/amal_log_model.dart';
import '../../providers/amal_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../constants/amal_fields.dart';
import '../services/islamic_date_service.dart';
import '../constants/default_amal_fields.dart';
import 'score_calculator.dart';

const String kFardFieldId = 'fard';
const String kTakbirFieldId = 'takbir';

AmalField? _fieldById(List<AmalField> fields, String id) {
  return fields.where((f) => f.id == id).firstOrNull;
}

/// Max selectable value for a numeric picker (takbir capped by fard).
int amalEditNumericMax(
  AmalField field,
  Map<String, dynamic> toggles,
  List<AmalField> fields,
) {
  if (field.id == kTakbirFieldId) {
    final fardField = _fieldById(fields, kFardFieldId);
    if (fardField != null) {
      return getNumericValue(toggles[kFardFieldId], fardField.maxValue);
    }
  }
  return field.maxValue;
}

bool isTakbirWithinFard(Map<String, dynamic> toggles, List<AmalField> fields) {
  final fardField = _fieldById(fields, kFardFieldId);
  final takbirField = _fieldById(fields, kTakbirFieldId);
  if (fardField == null || takbirField == null) return true;
  final fard = getNumericValue(toggles[kFardFieldId], fardField.maxValue);
  final takbir = getNumericValue(toggles[kTakbirFieldId], takbirField.maxValue);
  return takbir <= fard;
}

bool hasAnyAmalDone(Map<String, dynamic> toggles) {
  return toggles.values.any((v) => v == true || (v is int && v > 0));
}

Map<String, dynamic> toggleAmalField(
  Map<String, dynamic> toggles,
  List<AmalField> fields,
  String fieldId,
) {
  final field = _fieldById(fields, fieldId);
  if (field == null || field.type != AmalType.boolean) return toggles;

  final next = Map<String, dynamic>.from(toggles);
  next[fieldId] = !((next[fieldId] as bool?) ?? false);
  return next;
}

Map<String, dynamic> setAmalNumeric(
  Map<String, dynamic> toggles,
  List<AmalField> fields,
  String fieldId,
  int value,
) {
  final field = _fieldById(fields, fieldId);
  if (field == null || field.type != AmalType.numeric) return toggles;

  final next = Map<String, dynamic>.from(toggles);
  next[fieldId] = value.clamp(0, field.maxValue);

  if (fieldId == kFardFieldId) {
    final takbirField = _fieldById(fields, kTakbirFieldId);
    if (takbirField != null) {
      final fardVal = getNumericValue(next[kFardFieldId], field.maxValue);
      final takbirVal = getNumericValue(
        next[kTakbirFieldId],
        takbirField.maxValue,
      );
      if (takbirVal > fardVal) {
        next[kTakbirFieldId] = fardVal;
      }
    }
  }

  if (fieldId == kTakbirFieldId) {
    final fardField = _fieldById(fields, kFardFieldId);
    if (fardField != null) {
      final fardVal = getNumericValue(next[kFardFieldId], fardField.maxValue);
      next[fieldId] = (next[fieldId] as int).clamp(0, fardVal);
    }
  }

  return next;
}

int editAmalScore(Map<String, dynamic> toggles, List<AmalField> fields) {
  return calculateScore(toggles, fields);
}

int editAmalMaxScore(List<AmalField> fields) {
  return getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);
}

Map<String, dynamic> emptyTogglesForFields(List<AmalField> fields) {
  return normalizeTogglesForFields(<String, dynamic>{}, fields);
}

void invalidateAfterAmalEdit(WidgetRef ref, String uid, String hijriDate) {
  final parts = hijriDate.split('-');
  final year = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
  final month = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 1;
  ref.invalidate(
    historyMonthProvider(
      HistoryMonthKey(uid: uid, hijriYear: year, hijriMonth: month),
    ),
  );
  ref.invalidate(dayDetailLogProvider(DayLogKey(uid: uid, hijriDate: hijriDate)));
  ref.invalidate(editableDayProvider(hijriDate));

  ref.read(amalLogRefreshProvider.notifier).bump();
  ref.invalidate(weeklyLeaderboardProvider);
  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  if (hijriDate == today) {
    ref.invalidate(dailyLeaderboardProvider);
    ref.invalidate(amalProvider(uid));
  }

  ref.read(communitySheetProvider.notifier).reloadSelectedDateIfNeeded(hijriDate);
}
