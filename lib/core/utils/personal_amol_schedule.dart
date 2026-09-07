import '../../models/personal_amol_model.dart';
import '../services/islamic_date_service.dart';

/// True when [amol] is scheduled on the given Hijri date: daily amols always;
/// weekday amols only when their [PersonalAmolModel.weekdays] list contains
/// that date's personal-amol weekday index (1 = Saturday ... 7 = Friday).
bool personalAmolScheduledOn(PersonalAmolModel amol, String hijriDate) {
  if (amol.frequency != PersonalAmolFrequency.weekdays) return true;
  return amol.weekdays.contains(
    IslamicDateService.personalAmolWeekdayIndexForStorage(hijriDate),
  );
}

/// True when [amol] is scheduled today.
bool personalAmolScheduledToday(PersonalAmolModel amol) {
  if (amol.frequency != PersonalAmolFrequency.weekdays) return true;
  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  return amol.weekdays.contains(
    IslamicDateService.personalAmolWeekdayIndexForStorage(today),
  );
}

/// Number of [amols] scheduled on each Hijri date in [firstHijri] ..
/// [lastHijri] (inclusive). Used as the per-day calendar fill denominator so
/// weekday-only amols don't dilute days they aren't due.
///
/// Soft-deleted (inactive) amols count **only on past days where they actually
/// have a completion in [completions]** — their real history keeps filling the
/// calendar, but a deleted amol no longer dilutes days it was never done.
/// From [today] onward they make no demands at all.
Map<String, int> scheduledPersonalAmolByDay({
  required List<PersonalAmolModel> amols,
  required String firstHijri,
  required String lastHijri,
  String? today,
  List<PersonalAmolCompletion> completions = const [],
}) {
  final completedKeys = <String>{};
  for (final c in completions) {
    completedKeys.add('${c.hijriDate}_${c.amolId}');
  }
  final out = <String, int>{};
  var day = firstHijri;
  var guard = 0;
  while (day.compareTo(lastHijri) <= 0 && guard++ < 366) {
    var n = 0;
    for (final a in amols) {
      if (!a.isActive) {
        if (today != null && day.compareTo(today) >= 0) continue;
        // Deleted amol: only counts on a past day it was actually completed.
        if (!completedKeys.contains('${day}_${a.id}')) continue;
      }
      if (personalAmolScheduledOn(a, day)) n++;
    }
    out[day] = n;
    day = IslamicDateService.shiftStorageByDays(day, 1);
  }
  return out;
}

/// Soft-deleted amols that have at least one completion on [hijriDate].
///
/// Used by day-detail to show read-only history that still paints the calendar
/// gold after delete, without offering editable controls for inactive amols.
List<PersonalAmolModel> historicalPersonalAmolForDay({
  required List<PersonalAmolModel> amols,
  required String hijriDate,
  required List<PersonalAmolCompletion> completions,
}) {
  final completedIds = <String>{};
  for (final c in completions) {
    if (c.hijriDate == hijriDate) completedIds.add(c.amolId);
  }
  return amols
      .where((a) => !a.isActive && completedIds.contains(a.id))
      .toList(growable: false);
}
