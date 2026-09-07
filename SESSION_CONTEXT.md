# Session Context — Amol Tracker (Personal Amol + History Rework)

Handoff snapshot. Read this to resume the session with opencode from this
project directory: `opencode` then `--continue`.

## Objective
- Complete the **Personal Amol** feature (private per-user amol tracking, isolated
  from community score/streak/leaderboard) and rework the **History** screen into
  two tabs — Community Amol and Personal Amol — styled identically.

## Current State (all implemented & verified)
1. **History = two tabs**: `historyTabCommunityAmol` / `historyTabPersonalAmol`.
   Community grid fully decoupled from personal amol (toggling personal never
   affects community cells, `avgScore`, consistency, weakest-amal).
2. **Personal tab** (`_PersonalAmolHistoryTab`): stat cards **Logged days +
   Completions + Best streak**, fill-style grid matching community grid, legend.
3. **Realtime today fill**: today's personal cell fills by completion ratio
   (>=0.8 full, >=0.5 partial, >=0.2 light, else minimal) instead of a fixed
   "আজ" marker; "আজ" marker only if zero completions today. Community tab keeps
   its today marker. `personalAmolMonthCompletionSummaryProvider` watches
   `personalAmolRefreshProvider` so toggling updates instantly.
4. **Streak phantom bug fixed**: `_recomputeStreak` resets `bestStreak` to 0 when
   an amol has no completions (was keeping stale best=1 forever); history tab's
   `_maxBestStreak(..., hasCompletions)` returns 0 when `loggedDays == 0`.
5. **Home screen spacing**: divider before Personal Amol title reverted to
   `AppColors.cardBorder`; gap after divider 20.h; gap after progress row 16.h.
6. **Streak chip** (personal tiles): inline `text • 🔥 dayStreak(streak)` with
   `Icons.local_fire_department` in `AppColors.warning`, no border/pill.

## Key Decisions (user-confirmed)
- Personal tab stats = **Logged days + Completions + Best streak**.
- No weekday day-labels (`_DayLabels` class deleted) on either tab.
- No gold title above personal stat cards.
- Today cell fills realtime, drops special `today` style (personal tab only).
- Streak shows 0 when no completions.

## Architecture / Isolation
- Personal amol lives in `users/{uid}/personal_amol*` subcollections; 🔒 isolation
  comments in `firestore_service.dart`, `leaderboard_provider.dart` (6 providers),
  `history_provider.dart` (`liveStreakProvider`).
- Thresholds via pure helper `PersonalAmolMonthCalculator.buildMonth()`.

## Verification (all green as of last run)
- `flutter analyze` clean on all touched files.
- `flutter test test/personal_amol/` → 7/7 pass (incl. today-fill test).

## Pre-existing unrelated issues (NOT blockers)
- `notification_day_policy_test.dart`: 4 failures (commit 865be22 changed 21:15/21:45,
  test asserts 20:00/20:45).
- Hang on Firebase/plugin init: `app_redirect_launch_test.dart`,
  `safe_back_button_dispatcher_test.dart`, `tmp_optional_amal_preview_test.dart`.
- ~146 pre-existing analyze warnings (prints/unused imports) elsewhere.

## Relevant Files
- `lib/core/utils/personal_amol_month_calculator.dart` — personal month calendar.
- `lib/core/utils/history_month_calculator.dart` — community calendar (decoupled).
- `lib/features/history/presentation/screens/history_screen.dart` — two tabs.
- `lib/providers/personal_amol_provider.dart` — notifier, month summary, streak,
  refresh provider.
- `lib/providers/history_provider.dart` — community-only monthly summary.
- `lib/features/personal_amol/presentation/widgets/personal_amol_section.dart` —
  home section (16.h after progress row).
- `lib/features/personal_amol/presentation/widgets/personal_amol_tile.dart` — inline
  streak chip.
- `lib/features/home/presentation/widgets/home_scroll_body.dart` — personal amol
  divider (cardBorder, 20.h after).
- `lib/l10n/app_en.arb` / `app_bn.arb` + generated — tab/total keys.
- `test/personal_amol/personal_amol_month_calculator_test.dart` — 7 tests.
- `firestore.indexes.json`, `PERSONAL_AMOL_FEATURE.md` — index + feature doc.

## Next Steps (when returning)
- Run `flutter test test/personal_amol/` (expect 7/7) and `flutter analyze` on
  touched files to re-verify.
- Work was not committed to git; latest commit `865be22`. Offer to commit if asked:
  `git status` / `git diff` then `git add` relevant files.