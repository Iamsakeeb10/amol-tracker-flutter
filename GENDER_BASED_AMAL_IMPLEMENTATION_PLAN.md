# Gender-Based Amal Personalization — Implementation Plan

> **Derived entirely from the audited codebase. Every claim references the actual file and line(s) read.**

---

## Audit Findings

### 1. User Model (`lib/models/user_model.dart`)

`UserModel` is an immutable Dart class with a `fromMap` factory, a `fromDoc` factory, and a `toMap` serializer. Existing optional profile fields — `role`, `lmsXp`, `streakFreezeDate`, `badges`, `seenBadgeCelebrations`, `seenAnnouncements` — use `?? default` in `fromMap` and conditional inclusion (e.g. `if (lmsXp > 0) 'lmsXp': lmsXp`) in `toMap`. **There is currently no `gender` or `specialTimeActive` field.** There is no existing `copyWith` method.

Onboarding creates a user in `OnboardingScreen._completeOnboarding()` (L145–161) by constructing a `UserModel` literally and calling `FirestoreService.createUser`. The call uses only fields present at construction time; the Firestore method is `_users.doc(uid).set(user.toMap())`.

Optional settings (e.g. `showOnLeaderboard`, `isAnonymousDisplay`) are persisted via `FirestoreService.updateUserDisplayFields(uid, {...})` (L318–349), which uses `_users.doc(uid).update(fields)`. A local boolean in `_SettingsScreenState` optimistically tracks the UI value; the provider `currentUserProvider` (a `StreamProvider` wrapping `FirestoreService.userStream`) provides the live value.

**Conclusion:** The pattern for adding optional profile preferences is:
1. Add nullable field to `UserModel.fromMap` (with `?? default`).
2. Add conditional entry in `toMap` (omit when unset, matching existing `role`/`lmsXp` patterns).
3. Add a targeted update method on `FirestoreService` (narrow update map).
4. Persist optimistically in the Settings state, roll back on error.

### 2. Amal Field Model (`lib/core/constants/amal_fields.dart`)

`AmalField` is a `const`-eligible class. `fromMap` uses `_parseBool` (robust to string/num/bool/null, returns false by default) and `parseIsActive` (robust, returns true by default). `toMap` includes all current fields. **No gender-related attributes exist today.** Adding three new boolean/enum fields with safe defaults is fully forward-compatible because existing Firestore documents that lack these keys will hit the `?? false` / `?? 'all'` branches.

**Confirmed IDs in `kDefaultAmalFields`** (`lib/core/constants/default_amal_fields.dart`):
`fard_salah`, `fard`, `takbir`, `morning_azkar`, `evening_azkar`, `quran`, `mulk`, `miswak`, `sunnah`, `post_azkar` — 10 fields, total 100 points.

`kDefaultMaxDailyScore = 100` is defined in `default_amal_fields.dart` and used as a hard cap in `calculateScore`, `scoreRatio`, `AmalState.maxScore`, `editAmalMaxScore`, and `home_screen.dart` (L330: `getMaxScore(fields).clamp(1, kDefaultMaxDailyScore)`). This is the primary constraint-#1 risk area.

`AmalFieldsService` creates/updates fields via `_collection.doc(field.id).set(data)` / `batch.update(...)`, then bumps `config/amal_fields_meta.version`. Clients are notified via `_metaSub` (a Firestore stream listener in `AmalFieldsNotifier`) and refresh the cache.

### 3. Score Maximum — Spread Locations (Constraint #1)

I found score/max computation at the following sites:

| Location | What it does |
|---|---|
| `score_calculator.dart:calculateScore` | Computes score, clamps to `kDefaultMaxDailyScore` (100) |
| `score_calculator.dart:getMaxScore` | Sums active field points |
| `score_calculator.dart:scoreRatio` | `.clamp(1, kDefaultMaxDailyScore)` |
| `amal_edit_toggles.dart:editAmalMaxScore` | `getMaxScore(fields).clamp(1, kDefaultMaxDailyScore)` |
| `amal_edit_toggles.dart:editAmalScore` | calls `calculateScore` |
| `AmalState.maxScore` (amal_provider.dart:140) | `getMaxScore(fields).clamp(1, kDefaultMaxDailyScore)` |
| `AmalState.totalScore` (amal_provider.dart:138) | calls `calculateScore(toggles, fields)` |
| `home_screen.dart:330` | `getMaxScore(fields).clamp(1, kDefaultMaxDailyScore)` |
| `report_provider.dart:129` | `getMaxScore(fields).clamp(1, kDefaultMaxDailyScore)` |
| `history_provider.dart:92–93` | `getMaxScore(fields).clamp(1, kDefaultMaxDailyScore)` |
| `day_complete_screen.dart:105` | `getMaxScore(fields).clamp(1, kDefaultMaxDailyScore)` |
| `_syncClientSideBadgesAndFeed` (amal_provider.dart:783) | `getMaxScore(state.fields).clamp(1, kDefaultMaxDailyScore)` |
| `ReportCalculator.compute` parameter | receives `maxScore` from `report_provider` (live fields) |
| `HistoryMonthCalculator.compute` parameter | receives `maxScore` from `history_provider` (live fields) |

**All these locations currently compute max from the live field list, not from the stored log.** After this feature ships, logs for female users during special time will have a *different* max than the live field list produces, so all these call sites will show wrong values unless updated.

### 4. Amal Log Write Path (`lib/models/amal_log_model.dart`, `amal_provider.dart`)

`AmalLogModel` today stores: `uid`, `displayName`, `photoUrl`, `isAnonymousDisplay`, `hijriDate`, `toggles`, `score`, `submittedAt`, `editedAt`, `editCount`, `prayers`.  
**Neither `maxScore`, `activeFieldIds`, nor `specialTimeApplied` exists today.**

`toFirestoreMap` (L161–184) serializes field values by iterating the passed `fields` list. `toHiveMap` (L207–225) does not accept a `fields` argument; it stores the toggles map directly. `toEditFirestoreMap` (L186–205) only updates `score`, `editedAt`, `editCount`, and field values — **it does not currently write `maxScore` or `activeFieldIds`**.

There are **two separate submit paths**:
1. `AmalNotifier.submit` (amal_provider.dart, L557–773) — the normal Home submission
2. `EditAmalScreen._onSubmit` (edit_amal_screen.dart, L141–...) — the backfill/edit path, which calls `fs.saveAmalLog` for new logs and `fs.editAmalLog` for edits

### 5. Home Screen / Daily Entry UI

`home_screen.dart` passes `maxScore = getMaxScore(fields).clamp(1, kDefaultMaxDailyScore)` to `HomeScrollBody` (L330). `HomeScrollBody` passes it to `HomeProgressCard`. The Amal field list is exposed via `amalFieldsListProvider` (which wraps `amalFieldsProvider`). The list renders through `buildHomeEditingAmalSlivers` → `home_editing_amal_sliver.dart`, which in turn calls `buildHomeAmalFieldSlivers` in `home_amal_fields_sliver.dart`.

`home_amal_fields_sliver.dart` renders all fields in `loadedFields` (which is the raw `fieldsAsync.when` result from `amalFieldsProvider`). **There is no existing gender-based filtering, grouping, or sectioning today.** The `AmalFieldTile` and `AmalRow` components accept `field`, `done`, `numericValue`, `locale`, and `readOnly`.

For expand/collapse, `fard_prayer_expand_row.dart` uses `AnimatedSize` and a chevron-based expand pattern. This is the closest existing expand/collapse UI in the app.

### 6. Settings Screen

`settings_screen.dart` uses `ToggleRow` (for boolean switches) and `NavRow` (for navigation rows with optional trailing text). The file has a `_SettingsScreenState` with local state vars (`_showInLeaderboard`, `_anonymousDisplay`) that mirror Firestore values and are optimistically updated. The `firestoreServiceProvider` is accessed via `ref.read`.

### 7. Streak Logic (`lib/core/utils/streak_helper.dart`)

Streak is determined by `isBackfilledLog(log)` and `computeStreakFromLogs(loggedDates, todayHijri, frozenDates)`. It depends **only** on whether a non-backfilled log exists for a Hijri day. Score and active field count are irrelevant. **No changes required here.**

### 8. Localization (`lib/l10n/app_en.arb`, `app_bn.arb`)

ARB files with `@@locale` are the source. Generated files (`app_localizations*.dart`) are **never hand-edited**. Keys use `camelCase`. Existing patterns: `"settingsLabel": "..."`, `"someToggleSubtitle": "..."`. Both en and bn entries are required.

### 9. Admin Amal Fields Form

`admin_amal_field_form_screen.dart` — the form collects fields from text controllers and calls `amalFieldToFirestoreMap(...)` (in `admin_amal_field_helpers.dart`) to build the Firestore payload, then calls `service.updateField` or `service.createField`. **Adding new field attributes is a small addition**: add parameters to `amalFieldToFirestoreMap` and `buildDraftAmalField`, add form controls in the screen, and add them to `AmalField.fromMap`/`toMap`.

### 10. No Existing Modals for Profile Preferences

The app shows announcements via `AnnouncementModal` (full-screen dialog) and update prompts via `UpdateModal` (also a dialog). The Jummah reminder uses `showModalBottomSheet`. There is no existing "one-time profile preference modal" pattern. The closest is the announcement modal, which uses `showDialog` with `barrierDismissible: true` and emerald/gold theming.

---

## Discrepancies vs. the Proposal's Prior Plan (`GENDER_BASED_AMAL_IMPLEMENTATION_PLAN.md`)

1. **`UserModel` has no `copyWith`** — the prior plan implies one; not needed, the `fromMap`/`toMap` pattern works without it.
2. **`AmalLogModel.toHiveMap` does not accept a `fields` list** — the prior plan's note about updating `toHiveMap` must ensure `maxScore` and `activeFieldIds` are stored as literal values (not re-derived from `fields`).
3. **`EditAmalScreen` constructs its own `AmalLogModel` from local state** — it does not call `AmalNotifier`. The prior plan correctly identified this as a second write path.
4. **`_SettingsScreenState` uses local state booleans** for optimistic UI, not a dedicated Riverpod notifier. New fields should follow the same pattern.
5. **`kDefaultMaxDailyScore = 100` is in `default_amal_fields.dart`**, not `score_calculator.dart` — the cap is imported by `score_calculator.dart`. After this feature, `calculateScore` must not cap against 100 when the active set is smaller.
6. **Leaderboard scores** (`weeklyLeaderboard`, `monthlyLeaderboard`) in `FirestoreService` aggregate raw scores from logs. No changes needed for v1 if we keep raw-score rankings (see Open Questions below).
7. **`mock_data.dart` is referenced by `history_month_calculator.dart`** — `MockDay` and `DayCompletion` are imported from `lib/shared/mock/mock_data.dart`. These are not test-only; they are production types used by the calendar UI.

---

## User Review Required

> [!IMPORTANT]
> **Q1 — Leaderboard/Badge Fairness**: Badges (perfect-week threshold at `maxScore * 0.8`) and weekly/monthly leaderboards aggregate raw `score`. A female user in special-time mode has a smaller `maxScore`, so a "perfect" day might earn only 25 raw points vs 100. Should v1 keep raw-score rankings (simpler, documented tradeoff) or switch to normalized ratios (`score / maxScore`)? **Recommended: keep raw scores in v1, accept the tradeoff, revisit in v2.**

> [!IMPORTANT]
> **Q2 — "Skip" on the Gender Prompt**: If a user taps "Skip" on the initial gender modal, should the modal *never automatically appear again* (requiring a `genderPromptDismissedAt` field on the user document), or should it reappear on the next app launch until answered? **Recommended: store `genderPromptDismissedAt` (a Firestore bool field `genderPromptDismissed: true`) so Skip is permanent for auto-prompting, while Settings always allows re-opening the modal.**

> [!IMPORTANT]
> **Q3 — Editing an Existing Log's Eligibility**: When a user edits a past submitted log, should the edit screen use the historical log's stored `activeFieldIds` (so editing a special-time log doesn't suddenly show all 10 fields) or the current live profile? **Recommended: use stored `activeFieldIds` for editing existing logs; only new backfills use current policy.**

---

## Target Data Contracts

### `users/{uid}` — New Optional Fields

```
gender: "male" | "female"  // absent = unset
specialTimeActive: bool     // default false (write on first profile update)
genderPromptDismissed: bool // default false; true after Skip
```

Only write `specialTimeActive` and `genderPromptDismissed` on first use — do not add them to `UserModel.toMap()` creation payload in onboarding (keep onboarding minimal).

### `amal_fields/{id}` — New Optional Attributes

```
genderVisibility: "all" | "male_only" | "female_only"  // missing → "all"
femaleDeprioritized: bool                               // missing → false
disableDuringSpecialTime: bool                          // missing → false
```

### `amal_logs/{uid}_{hijriDate}` — New Immutable Context Fields

```
maxScore: int               // sum of active field points at submit time
activeFieldIds: List<String> // IDs of score-eligible fields for this log
specialTimeApplied: bool    // true if special-time mode was on at submit
```

### Default Field Attribute Mapping

| Field IDs | `femaleDeprioritized` | `disableDuringSpecialTime` |
|---|---|---|
| `fard_salah`, `fard`, `takbir` | true | true |
| `quran`, `mulk`, `sunnah`, `post_azkar` | false | true |
| `morning_azkar`, `evening_azkar`, `miswak` | false | false |

All 10 default fields get `genderVisibility: "all"` (no field is hidden entirely by gender — only deprioritized or disabled).

---

## Proposed Changes

### Database & Models

#### [MODIFY] `lib/models/user_model.dart`
- Add three nullable/defaulted fields: `String? gender`, `bool specialTimeActive`, `bool genderPromptDismissed`.
- Add `UserAmalProfile` enum: `enum UserAmalProfile { unset, male, female }` in the same file (or a new `lib/models/user_amal_profile.dart`).
- Add a single computed getter `UserAmalProfile get amalProfile` that derives the enum from `gender` — the **only** place in the app that converts `gender` string to enum.
- `fromMap`: parse `gender` as `String?` (absent → null), `specialTimeActive` as `bool? ?? false`, `genderPromptDismissed` as `bool? ?? false`.
- `toMap`: include `if (gender != null) 'gender': gender`, `if (specialTimeActive) 'specialTimeActive': true`, `if (genderPromptDismissed) 'genderPromptDismissed': true` (conditional inclusion follows `role`/`lmsXp` pattern).

#### [MODIFY] `lib/core/constants/amal_fields.dart`
- Add `GenderVisibility` enum: `enum GenderVisibility { all, maleOnly, femaleOnly }`.
- Add three fields to `AmalField`: `genderVisibility`, `femaleDeprioritized`, `disableDuringSpecialTime`.
- Extend `fromMap` using `_parseBool` for booleans and a new `_parseGenderVisibility` function for the enum (missing/invalid → `GenderVisibility.all`).
- Extend `toMap` to include all three new fields.

#### [MODIFY] `lib/core/constants/default_amal_fields.dart`
- Update the 10 entries in `kDefaultAmalFields` with the attribute mapping table above. Existing const constructors will need the new named parameters.
- No change to `kDefaultMaxDailyScore` — it remains 100 and is now only used as a display cap for ratios, never as the score computation maximum.

#### [MODIFY] `lib/features/admin/presentation/widgets/admin_amal_field_helpers.dart`
- Add `genderVisibility`, `femaleDeprioritized`, `disableDuringSpecialTime` parameters to `amalFieldToFirestoreMap` and `buildDraftAmalField`.

#### [MODIFY] `lib/models/amal_log_model.dart`
- Add `maxScore`, `activeFieldIds`, `specialTimeApplied` fields.
- **Legacy fallback in `fromDoc` and `fromHiveMap` only**: if `maxScore` is absent/null → `100`; if `activeFieldIds` is absent/null → a named constant `kLegacyActiveFieldIds` (a `const List<String>` of all 10 default field IDs, defined in this file). `specialTimeApplied` → `false`. These fallbacks must exist **only in these two deserialization methods** — no other code in the app may do `?? 100`.
- Extend `toFirestoreMap` to always write `maxScore`, `activeFieldIds`, `specialTimeApplied` (these are not conditional).
- Extend `toHiveMap` to always write the same three fields (as literal values).
- Extend `toEditFirestoreMap` to always update `maxScore`, `activeFieldIds`, `specialTimeApplied` alongside `score` and field values.
- Update `_logMetadataKeys` to include `'maxScore'`, `'activeFieldIds'`, `'specialTimeApplied'` so they are not mistakenly parsed as toggle values.

---

### Logic & Entry Policy

#### [NEW] `lib/core/utils/amal_entry_policy.dart`
Define `AmalEntryPolicy` (an immutable value object) and a Riverpod provider. This is the single place that applies gender + special-time filtering/ordering. Fields:
- `mainFields: List<AmalField>` — always interactive
- `optionalFields: List<AmalField>` — `femaleDeprioritized: true` fields shown in a collapsed section (female + specialTime off only)
- `inactiveSpecialTimeFields: List<AmalField>` — `disableDuringSpecialTime: true` fields shown as disabled (female + specialTime on)
- `activeFields: List<AmalField>` — score-eligible fields (= mainFields + optionalFields for normal; = only the 3 non-disabled for special time)
- `isSpecialTimeActive: bool` — derived, not re-computed anywhere else

Logic table:
| `amalProfile` | `specialTimeActive` | Result |
|---|---|---|
| `unset` or `male` | any | all fields in `mainFields`; `optionalFields = []`; `inactiveSpecialTimeFields = []` |
| `female` | false | `femaleDeprioritized` fields in `optionalFields`; rest in `mainFields` |
| `female` | true | `disableDuringSpecialTime` fields in `inactiveSpecialTimeFields`; rest in `mainFields` |

**Named provider**: `amalEntryPolicyProvider` — depends on `amalFieldsListProvider` and `currentUserProvider`. Exposes `isSpecialTimeActiveForCurrentEntryProvider` as a derived provider.

#### [MODIFY] `lib/core/utils/score_calculator.dart`
- Refactor `calculateScore` to accept a pre-filtered `List<AmalField>` of **active** fields (not all fields — the policy selects which are active). Remove the `resolveAmalFields` call inside `calculateScore`; it is now the caller's responsibility to pass only active fields.
- Remove the hard cap `score.clamp(0, kDefaultMaxDailyScore)` from `calculateScore`. The max is now dynamic.
- Add `AmalScoreResult` class: `{ int score, int maxScore, List<String> activeFieldIds }`.
- Add `AmalScoreResult calculateAmalScore({ required Map<String, dynamic> toggles, required List<AmalField> activeFields })` — the **single function** that computes all three values together.
- Keep `getNumericValue` and `resolvePrayerSelection` unchanged.
- Keep `getMaxScore` for backward compatibility during migration (remove after all callers are updated).

---

### Log Write Paths

#### [MODIFY] `lib/providers/amal_provider.dart`
In `AmalNotifier.submit` (L557–773):
- Update score calculation logic to use `amalEntryPolicyProvider` and `calculateAmalScore`.
- Build `AmalLogModel` with `score`, `maxScore`, `activeFieldIds`, `specialTimeApplied` from the result.
- In `_syncClientSideBadgesAndFeed` (L783): update perfect-week logic to check `log.score >= (log.maxScore * 0.8).round()` per log instead of a global max.
- `AmalState.maxScore` getter: return policy-driven max when unsubmitted, or `state.submittedLog?.maxScore ?? policyMax` when submitted.

#### [MODIFY] `lib/features/history/presentation/screens/edit_amal_screen.dart`
- In `_onSubmit` (L141):
  - For **new backfill**: use current `amalEntryPolicyProvider` to get `activeFields` and call `calculateAmalScore`. Store fields on the new log.
  - For **editing existing log**: reconstruct a "stored policy" from `existing.activeFieldIds` and call `calculateAmalScore` with those fields to prevent changing eligibility.

#### [MODIFY] `lib/core/utils/amal_edit_toggles.dart`
- `editAmalMaxScore`: derive from the active fields passed by caller, not `getMaxScore(fields)`.
- `editAmalScore`: call `calculateAmalScore` and return the score.

---

### Home & Settings UI

#### [MODIFY] `lib/core/services/firestore_service.dart`
Add `updateUserGenderPreferences(String uid, { String? gender, bool? specialTimeActive, bool? genderPromptDismissed })` — the only write path for these three fields.

#### [NEW] `lib/shared/widgets/gender_selection_modal.dart`
Modal dialog widget matching existing app modal style (emeraldDeep background, gold accents).
Contains: Male/Female selection cards, Confirm button, "Skip for now" button.

#### [MODIFY] `lib/features/home/presentation/screens/home_screen.dart`
- Add one-time gender prompt check after `_didInitialAnnouncementCheck`. Show `GenderSelectionModal` only if `user.amalProfile == UserAmalProfile.unset && !user.genderPromptDismissed`.
- Add Special Time toggle widget for female users, reading from `isSpecialTimeActiveForCurrentEntryProvider`.

#### [MODIFY] `lib/features/settings/presentation/screens/settings_screen.dart`
- Add `SectionHeader` for personalization.
- Add `NavRow` for "Gender" to reopen `GenderSelectionModal`.
- Add `ToggleRow` for Special Time (visible only for female profile).

#### [MODIFY] `lib/features/home/presentation/widgets/home_editing_amal_sliver.dart`
Replace simple field iteration with policy-aware rendering:
1. Main fields
2. Optional section (collapsed by default)
3. Inactive (special-time) group (disabled style, `readOnly: true`)

#### [MODIFY] `lib/features/home/presentation/widgets/home_scroll_body.dart`
Use policy-derived `maxScore` for the `HomeProgressCard` instead of global max.

#### [MODIFY] `lib/features/home/presentation/screens/day_complete_screen.dart`
Use `widget.log.maxScore` instead of global max for score ring rendering.

---

### Reports & History

#### [MODIFY] `lib/core/utils/report_calculator.dart`
- `ReportBarPoint`: add `maxScore: int` and `specialTimeApplied: bool` fields.
- `_buildBars`: map per-log `maxScore` and `specialTimeApplied`.
- `ReportSummary.avgScore`: average of normalized per-log `score/maxScore` ratios.
- Compute consistency using per-log denominators (`halfScore = log.maxScore * 0.5`).
- `_amalBreakdown`: compute eligible days based on `activeFieldIds` presence across logs.

#### [MODIFY] `lib/core/utils/history_month_calculator.dart`
- `_buildDays`: use per-log denominator for `_scoreToState`.
- `_calcConsistency`: compare against per-log thresholds.

#### [MODIFY] `lib/providers/report_provider.dart` & `lib/providers/history_provider.dart`
Remove global `maxScore` parameter from computations.

#### [MODIFY] `lib/features/reports/presentation/screens/reports_screen.dart`
Apply subtle visual differentiator for special-time bars (e.g., small icon overlay or muted fill).

---

### Admin & Localization

#### [MODIFY] `lib/features/admin/presentation/screens/admin_amal_field_form_screen.dart`
Add "Personalization" section for admin to configure `genderVisibility`, `femaleDeprioritized`, and `disableDuringSpecialTime`.

#### [MODIFY] `lib/l10n/app_en.arb` and `lib/l10n/app_bn.arb`
Add all new localization keys for the modal, settings, and home screen sections.

#### [NEW] `tool/migrate_amal_fields.dart`
One-time production data migration script to patch existing `amal_fields` collection with the new attribute values.

---

## Verification Plan

### Automated Tests
- `UserModel` round-trips for new fields.
- `AmalField` round-trips for new attributes.
- `AmalEntryPolicy` computation across all 6 combos.
- `calculateAmalScore` for reduced active sets.
- `AmalLogModel` legacy fallback exact usage.

### Manual Verification
- Three-account check: unset, male, female.
- Critical sequence: female, special-time on → submit × 2 → off → submit × 1 → History shows correct max on old logs.
- Gender change after logs: old logs unchanged.
- Admin config change + force-reload.
- Offline submit as female with special-time on.
- Legacy log display (max shows 100, no crash).
