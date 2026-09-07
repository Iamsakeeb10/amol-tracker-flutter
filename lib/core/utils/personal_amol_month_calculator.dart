import '../../shared/mock/mock_data.dart';
import '../services/islamic_date_service.dart';

/// Builds the personal-amol calendar for the history screen.
///
/// This models only the user's own personal amol — it never reads community
/// `amal_logs` and never feeds leaderboard, achievement, or streak data.
class PersonalAmolMonthCalculator {
  /// Renders one [MockDay] per day of the Hijri month using the number of
  /// personal completions on each day, expressed as a fraction of the total
  /// active personal amol. Pre-account, future, and today cells behave exactly
  /// like the community calendar.
  static List<MockDay> buildMonth({
    required Map<String, int> completionsByDay,
    required int activeCount,
    required int hijriYear,
    required int hijriMonth,
    required String todayStr,
    required String accountCreatedHijri,
    required int daysInMonth,
  }) {
    final out = <MockDay>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final key = IslamicDateService.storageFromParts(hijriYear, hijriMonth, d);
      if (key.compareTo(accountCreatedHijri) < 0) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.preAccount));
        continue;
      }
      final cmp = key.compareTo(todayStr);
      if (cmp > 0) {
        out.add(MockDay(day: d, score: 0, state: DayCompletion.future));
        continue;
      }

      if (key == todayStr) {
        final done = completionsByDay[key] ?? 0;
        if (done == 0 || activeCount <= 0) {
          out.add(MockDay(day: d, score: done, state: DayCompletion.today));
        } else {
          final ratio = done / activeCount;
          out.add(MockDay(day: d, score: done, state: _ratioToState(ratio)));
        }
        continue;
      }

      final done = completionsByDay[key] ?? 0;
      if (done == 0 || activeCount <= 0) {
        out.add(MockDay(day: d, score: done, state: DayCompletion.noData));
        continue;
      }

      final ratio = done / activeCount;
      final state = _ratioToState(ratio);
      out.add(MockDay(day: d, score: done, state: state));
    }
    return out;
  }

  static DayCompletion _ratioToState(double ratio) {
    if (ratio >= 0.8) return DayCompletion.full;
    if (ratio >= 0.5) return DayCompletion.partial;
    if (ratio >= 0.2) return DayCompletion.light;
    return DayCompletion.minimal;
  }
}