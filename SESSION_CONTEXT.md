# Session Context — Amol Tracker (Personal Amol + History Rework)

Handoff snapshot. Read this to resume the session with opencode from this
project directory: `opencode` then `--continue`.

## Objective
- Ship the **Personal Amol** redesign (private per-user amol tracking, isolated
  from community score/streak/leaderboard): a create bottom sheet, toggle/count
  tracking types, Material-icon picker, and weekday scheduling.
- Ship the two audit-approved behavior changes: **weekday gating** (weekday
  amols only show/count on scheduled days) and **deleted-amol history retention**
  (soft-deleted amols' past completions keep filling the history calendar).

## Current State (all implemented & verified)
1. **Create/edit design** (`PersonalAmolCreateSheet` + edit form screen):
   all fields (name, icon, tracking type, target, reminder for edit, weekday
   chips); count logs via +/− stepper; day "done" = target reached for
   calendar/progress/history "Completions"; streak = any day ≥1; all create
   entry points open the sheet; icons persisted as `m:<name>` tokens from const
   map `kPersonalAmolIcons` (154 icons, verified against SDK); target stepper
   default 3, max 100; weekday chips Sunday-first (2,'Sun')…(1,'Sat'); cap banner.
2. **Weekday gating**: unscheduled days are skipped (not counted) for calendar
   fill, progress denominator, day-detail rows, and streak; the single most
   recent scheduled day may be "pending" (not yet logged) without resetting the
   streak; any other scheduled-but-unlogged day breaks the chain. Home section
   filters tiles to those scheduled today; if amols exist but none are due today
   it shows a "nothing due today" hint instead of the empty state.
3. **Deleted-amol retention**: history watches all amols (incl. `isActive:false`);
   fully-done-by-day no longer filters by active; day-detail rows use all amols
   gated by weekday; best-streak covers deleted amols; history only shows the
   empty state when there are neither amols nor past completions.
4. **Streak truncation fix**: `getRecentCompletions` paginates
   (`_streakLookbackDistinctDays=30`, batch 100, max 50 pages) accumulating ≥30
   distinct Hijri dates, because count amols write one doc per increment.
5. **Month summarization**: month summary provider returns a record
   `({Map<String,int> doneByDay, Map<String,int> scheduledByDay})`; `buildMonth`
   takes `activeCountByDay` (per-day scheduled denominator) with an
   `activeCount` fallback for backward compat.

## Weekday Indices (verified)
1=Sat … 7=Fri; `1447-03-01`=Sun(idx 2), `1447-03-02`=Mon(idx 3), `1447-03-07`=idx 1,
`1447-03-08`=idx 2, `1447-03-14`=idx 1, `1447-03-15`=idx 2.
- `IslamicDateService.personalAmolWeekdayIndex(DateTime)` = `((weekday-6)%7)+1`.
- `...WeekdayIndexForStorage(String)` parses YYYY-MM-DD via raw
  `HijriCalendar().hijriToGregorian` (no BD-tz dependency; internally consistent).

## Key Decisions (user-confirmed)
- Weekday gating = "Gate by weekday". Deleted-amol history = "Keep counting".
- Personal amol stays fully isolated from community score/streak/leaderboard.
- `AppRoutes.personalAmolCreate` remains registered but unused (edit uses the
  form screen).

## Verification (all green as of last run)
- `flutter analyze` clean on all touched personal-amol/history files (146
  pre-existing warnings elsewhere unchanged).
- `flutter test test/personal_amol/` → 27/27 pass (model, constants, month
  calculator incl. per-day denominator, schedule util, streak gating, fully-done
  summary incl. deleted + weekday tests).

## Pre-existing unrelated issues (NOT blockers)
- `notification_day_policy_test.dart`: 4 failures (commit 865be22 changed
  21:15/21:45, test asserts 20:00/20:45).
- Hang on Firebase/plugin init: `app_redirect_launch_test.dart`,
  `safe_back_button_dispatcher_test.dart`, `tmp_optional_amal_preview_test.dart`.
- ~146 pre-existing analyze warnings (prints/unused imports) elsewhere.

## Relevant Files
- `lib/providers/personal_amol_provider.dart` — allPersonalAmolProvider, month
  summary record, gating guards, `_recomputeStreak` scheduledWeekdays,
  `fullyDonePersonalAmolByDay`, `toggleComplete/incrementCount/decrementCount`.
- `lib/core/utils/personal_amol_schedule.dart` — pure gating/scheduling helpers
  (`personalAmolScheduledOn`, `personalAmolScheduledToday`, `scheduledPersonalAmolByDay`).
- `lib/core/utils/personal_amol_month_calculator.dart` + `lib/features/history/
  presentation/screens/history_screen.dart` — per-day denominator, all-amol data,
  record consumption, deleted-retention empty-state.
- `lib/core/utils/streak_helper.dart` + `lib/core/services/personal_amol_repository.dart`
  — scheduled-weekday streak walk; paginated `getRecentCompletions`; `watchAllAmol`.
- `lib/core/services/islamic_date_service.dart` — weekday index helpers.
- `lib/features/personal_amol/presentation/widgets/`: `personal_amol_section.dart`
  (weekday gating + none-due hint), `personal_amol_day_detail_section.dart`
  (gated + weekday badge), `personal_amol_tile.dart` (`_staticTrailing`), all
  create/edit widgets.
- `lib/l10n/app_en.arb` / `app_bn.arb` + generated — `personalAmolNoneDueToday`
  and the create/edit keys.
- `test/personal_amol/`: `personal_amol_model_test.dart`, `constants_test.dart`,
  `personal_amol_month_calculator_test.dart`, `personal_amol_schedule_test.dart`,
  `streak_gating_test.dart`, `fully_done_summary_test.dart`.

## Next Steps (when returning)
- Run `flutter test test/personal_amol/` (expect 27/27) and `flutter analyze` on
  touched files to re-verify.
- Work was not committed to git; latest commit `865be22`. Offer to commit if
  asked: `git status` / `git diff` then `git add` relevant files.
