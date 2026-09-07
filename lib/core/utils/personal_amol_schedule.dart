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
Map<String, int> scheduledPersonalAmolByDay({
  required List<PersonalAmolModel> amols,
  required String firstHijri,
  required String lastHijri,
}) {
  final out = <String, int>{};
  var day = firstHijri;
  var guard = 0;
  while (day.compareTo(lastHijri) <= 0 && guard++ < 366) {
    var n = 0;
    for (final a in amols) {
      if (personalAmolScheduledOn(a, day)) n++;
    }
    out[day] = n;
    day = IslamicDateService.shiftStorageByDays(day, 1);
  }
  return out;
}
