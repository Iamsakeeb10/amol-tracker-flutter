# Session Context — Amol Tracker (Personal Amol + History Rework)

Handoff snapshot. Read this to resume the session with opencode from this
project directory: `opencode` then `--continue`.

## Objective
- Ship the **Personal Amol** redesign (private per-user amol tracking, isolated
  from community score/streak/leaderboard): a shared create/edit bottom sheet,
  toggle/count tracking types, Material-icon picker, and weekday scheduling.
- Ship the two audit-approved behavior changes: **weekday gating** (weekday
  amols only show/count on scheduled days) and **deleted-amol history retention**
  (soft-deleted amols' past completions keep filling the history calendar).

## Current State (all implemented & verified)
1. **Create/edit design** (`PersonalAmolCreateSheet`, reused for create AND
   edit via `show()`/`showForEdit()`): all fields (name, icon, tracking type,
   target, weekday chips); count logs via +/− stepper; day "done" = target
   reached for calendar/progress/history "Completions"; streak = any day ≥1;
   all create entry points open the sheet; icons persisted as `m:<name>` tokens
   from const map `kPersonalAmolIcons` (154 icons, verified against SDK); target
   stepper default 3, max 100; weekday chips Sunday-first (2,'Sun')…(1,'Sat');
   cap banner (skipped when editing). The old full-screen edit form
   (`personal_amol_form_screen.dart`) and its router entries/route constants
   were deleted. Reminder option removed everywhere per user; the delete button
   stays on the list item.
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
6. **Create-sheet UI polish**: name-field hint is low-opacity (`textMuted`
   alpha 0.5); icon-picker body uses fixed logical 16 padding to align with the
   AppBar title; Add button is full-width `double.infinity`,
   `RoundedRectangleBorder(14.r)`, disabled colors, text+icon both
   `AppColors.emeraldDeep` (icon `Icons.add_rounded` 16.r, matching the
   empty-state CTA); button is pinned to a fixed footer inside the `Form` and
   floats above the keyboard (`bottomInset` + bottom-safe-area padding; sheet
   expands on name-field focus via a `FocusNode` listener and shrinks back on
   blur). Edit mode pre-fills in `initState` and saves via `updateAmol` with
   `reminderTime: null`.
7. **Home details dialog**: tapping a personal-amol tile opens
   `showPersonalAmolDetailsDialog` (new `personal_amol_details_dialog.dart`),
   styled like the community dialog — `PersonalAmolDialogColors` palette, gold
   icon badge when done, name+freq, progress panel (`LinearProgressIndicator`,
   weekday names), chips (type, target, 🔥 day streak, best streak), Edit
   (`showForEdit`) + Close buttons.
8. **Count stepper responsiveness (fixed)**: +/- and toggle no longer wait
   on serial network round-trips before the UI updates. Today's completions now
   stream via Firestore `snapshots()` (`watchCompletionsForDate`) so a local
   write updates the tile count instantly from the local cache; decrement and
   toggle reuse the already-loaded today snapshot instead of an extra
   `getCompletionsForDate` query before writing.
9. **Count target cap (fixed)**: `+` can no longer exceed the daily target.
   `PersonalAmolStepper` disables `+` when `doneCount >= target`, and
   `incrementCount` also guards `current >= target` (using the streamed today
   snapshot) so no extra docs are written even on rapid taps. Existing overshoot
   counts are reduced via `−`.
10. **History today-fill with deleted amols (fixed)**: home progress uses only
    active amols, but the history denominator (`scheduledPersonalAmolByDay`)
    counted soft-deleted amols too — a deleted amol scheduled today diluted
    today's ratio (e.g. 2 done / 3 scheduled = partial). Now the denominator
    drops soft-deleted amols from `today` onward (`today` param), while past
    days still include them so retained completions keep filling.
11. **Staged personal-amol edits + shared save FAB (big task, implemented)**:
    toggle/+/− on the home section no longer write to Firestore per tap — they
    mutate a Hive-persisted draft (`PersonalAmolPendingNotifier`) and are
    flushed together by the community save FAB. Official requirements
    (user-confirmed): one FAB saves both community + personal; streaks update
    only on Save; unsaved-changes signal = FAB presence (no header pill). FAB
    shows when `(community dirty && !submitted) || personalDirty`, spinner while
    either is saving; `_onSavePressed` saves personal first (try/catch, then
    community) then community submit, skipping it once already submitted.
  - Draft model: `PersonalAmolPendingState { staged, baseline, isSaving }`,
    absolute desired counts + saved snapshot per touched amol (net delta =
    staged − baseline); Hive key `personal_amol_draft_${uid}_${hijri}` storing
    `{date, staged, baseline}`, restored on provider creation, dropped on Hijri
    rollover (`currentHijriDateProvider` listener in notifier).
  - Pure helper `stagePersonalAmolValue` (unit-tested): seeds baseline on first
    touch, prunes entries that return to baseline (dirty=false), clamps never.
  - `saveToday()`: batches each amol's delta via `repo.applyCompletionDelta`
    (+delta creates count docs / toggle doc; −delta deletes |delta| most-recent
    docs), then `recomputeStreak` (best-effort, swallowed); only stales entries
    that persisted, keeps failed ones staged so a retry never duplicates; bumps
    `personalAmolRefreshProvider`. Removed `toggleComplete/incrementCount/
    decrementCount` from `PersonalAmolNotifier`; `_recomputeStreak` is now
    public `recomputeStreak(amolId)`.
  - Section reads `shown = {...counts, ...pending.staged}`; home screen
    `showSaveFab` includes `personalPendingDirty`; `HomeSaveFab` reads the
    provider for dirty state (never touches protected `notifier.state`).
  - Stage-crash fix: `dispose()`/`_stage()` used to schedule
    `Future.microtask(_persistDraft)` which read `state` AFTER `super.dispose()`
    → legacy StateNotifier throws "used after dispose". Now both snapshot
    staged/baseline/date synchronously and persist via `_persistDraftFrom(...)`.
  - FAB show/hide proven by `personal_amol_pending_notifier_test.dart`
    (ProviderContainer + temp Hive): plus→minus, multi-step revert, toggle
    on/off, toggle-off-from-saved-then-on, and Hive draft restore all drive
    `dirty` back to `false`, so `!communityDirty && !personalDirty`
    → `SizedBox.shrink()` hides the FAB correctly.

## Weekday Indices (verified)
1=Sat … 7=Fri; `1447-03-01`=Sun(idx 2), `1447-03-02`=Mon(idx 3), `1447-03-07`=idx 1,
`1447-03-08`=idx 2, `1447-03-14`=idx 1, `1447-03-15`=idx 2.
- `IslamicDateService.personalAmolWeekdayIndex(DateTime)` = `((weekday-6)%7)+1`.
- `...WeekdayIndexForStorage(String)` parses YYYY-MM-DD via raw
  `HijriCalendar().hijriToGregorian` (no BD-tz dependency; internally consistent).

## Key Decisions (user-confirmed)
- Weekday gating = "Gate by weekday". Deleted-amol history = "Keep counting".
- Personal amol stays fully isolated from community score/streak/leaderboard.
- No reminder option anywhere; delete button stays on the list item (not the
  sheet). Edit reuses the same bottom sheet via `showForEdit`.
- Add-button styling matches the empty-state CTA (emeraldDeep text+icon);
  earlier goldLight choice superseded.
- Tapping a home tile opens the details dialog (styled like community amol).

## Verification (all green as of last run)
- `flutter analyze` clean on all touched personal-amol/history files (146
  pre-existing warnings elsewhere unchanged).
- `flutter test test/personal_amol/` → 41/41 pass (model, constants, month
  calculator incl. per-day denominator, schedule util incl. soft-deleted
  cutoff, streak gating, fully-done summary incl. deleted + weekday tests,
  pending-state dirty + `stagePersonalAmolValue` pure helper,
  `personal_amol_pending_notifier_test.dart` ProviderContainer integration).

## Pre-existing unrelated issues (NOT blockers)
- `notification_day_policy_test.dart`: 4 failures (commit 865be22 changed
  21:15/21:45, test asserts 20:00/20:45).
- Hang on Firebase/plugin init: `app_redirect_launch_test.dart`,
  `safe_back_button_dispatcher_test.dart`, `tmp_optional_amal_preview_test.dart`.
- ~146 pre-existing analyze warnings (prints/unused imports) elsewhere.

## Relevant Files
- `lib/providers/personal_amol_pending_provider.dart` (new) — staged
  pending state, pure `stagePersonalAmolValue`, `PersonalAmolPendingNotifier`
  (toggle/plus/minus, Hive draft, Hijri rollover, `saveToday`),
  `personalAmolPendingProvider`.
- `lib/shared/widgets/home_save_fab.dart` — combined community+personal
  visibility and `_onSavePressed` (personal batch save then community submit).
- `lib/features/home/presentation/screens/home_screen.dart` — `showSaveFab`
  includes `personalPendingDirty` from `personalAmolPendingProvider(uid)`.
- `lib/providers/personal_amol_provider.dart` — allPersonalAmolProvider, month
  summary record, gating guards, public `recomputeStreak`,
  `fullyDonePersonalAmolByDay`, streamed
  `personalAmolCompletionsForTodayProvider` (immediate-write methods removed).
- `lib/core/utils/personal_amol_schedule.dart` — pure gating/scheduling helpers
  (`personalAmolScheduledOn`, `personalAmolScheduledToday`, `scheduledPersonalAmolByDay`).
- `lib/core/utils/personal_amol_month_calculator.dart` + `lib/features/history/
  presentation/screens/history_screen.dart` — per-day denominator, all-amol data,
  record consumption, deleted-retention empty-state.
- `lib/core/utils/streak_helper.dart` + `lib/core/services/personal_amol_repository.dart`
  — scheduled-weekday streak walk; paginated `getRecentCompletions`; `watchAllAmol`;
  `watchCompletionsForDate` snapshot stream for today.
- `lib/core/services/islamic_date_service.dart` — weekday index helpers.
- `lib/features/personal_amol/presentation/widgets/`: `personal_amol_section.dart`
  (weekday gating + none-due hint + tile onTap → details dialog),
  `personal_amol_day_detail_section.dart`
  (gated + weekday badge), `personal_amol_tile.dart` (`_staticTrailing`),
  `personal_amol_create_sheet.dart` (shared create/edit, pinned footer + keyboard
  handling), `personal_amol_details_dialog.dart` (home tile details),
  `personal_amol_icon_picker.dart` (fixed 16 body padding).
- `lib/core/router/router.dart` + `routes.dart` — create/edit form routes and
  constants removed.
- `lib/l10n/app_en.arb` / `app_bn.arb` + generated — `personalAmolNoneDueToday`,
  `personalAmolEditLabel`, `personalAmolEditTitle`, `personalAmolSaveLabel`
  keys; reminder keys removed.
- `test/personal_amol/`: `personal_amol_model_test.dart`, `constants_test.dart`,
  `personal_amol_month_calculator_test.dart`, `personal_amol_schedule_test.dart`,
  `streak_gating_test.dart`, `fully_done_summary_test.dart`,
  `personal_amol_pending_test.dart`,
  `personal_amol_pending_notifier_test.dart`.

## Next Steps (when returning)
- Run `flutter test test/personal_amol/` (expect 41/41) and `flutter analyze` on
  touched files to re-verify.
- Manually verify on a real device (Firestore remote, not emulator): the save
  FAB appears when personal edits are pending and hides when toggles/stepper are
  reverted to the saved baseline; tapping it batch-writes Firestore and then
  updates streak chips + month summary; a forced app restart while edits are
  pending restores the draft from Hive. IMPORTANT: the staging feature added a
  NEW provider file — `flutter run` hot RELOAD will not link it; do a full
  restart (Shift+R hot restart or rerun) before judging FAB behavior. Verify
  the count `+` stops at target and today's history cell fills when a deleted
  amol exists.
- Work was not committed to git; latest commit `865be22`. Offer to commit if
  asked: `git status` / `git diff` then `git add` relevant files.
