# Task 4 + 5: Amal Log Write Path & Home Screen / Daily Entry UI

> Implementation-ready plan for gender-based amal personalization write path and home UI.

---

## Audit: Android Widget ↔ Flutter Mapping

`android/app/src/main/res/layout/widget_amal_row.xml` maps correctly to `lib/shared/widgets/amal_row.dart`:

| Android | Flutter |
|---|---|
| `@+id/amal_row_label` (weight=1, ellipsize) | `field.getLabel(locale)` + sublabel in `detailsContent` |
| `@+id/amal_row_value` (gold, bold, gone) | earned points `+$earnedPoints/${field.points} pts` / `AmalNumericPicker` |
| `@+id/amal_row_status` (13dp icon) | `Switch.adaptive` (boolean) or `check_circle/cancel_outlined` (read-only) |

Mapping is consistent. No Android changes required.

---

## Task 4 — Amal Log Write Path

### Current gaps
- `AmalLogModel` lacks `maxScore`, `activeFieldIds`, `specialTimeApplied` in ctor, `toFirestoreMap`, `toHiveMap`, `toEditFirestoreMap`, `_logMetadataKeys`, and legacy fallbacks.
- `AmalNotifier.submit` uses `calculateScore(toggles, fields)` (global, all fields) and does not store policy context on the log.
- `EditAmalScreen._onSubmit` calls `calculateScore(toggles, fields)` directly; no policy context stored.
- `_syncClientSideBadgesAndFeed` uses global `getMaxScore(state.fields)` for perfect-week threshold.

### Implementation steps

#### 4.1 Extend `AmalLogModel` (`lib/models/amal_log_model.dart`)
- Add fields: `final int maxScore; final List<String> activeFieldIds; final bool specialTimeApplied;`
- Add legacy fallbacks in `fromDoc`/`fromHiveMap`: `maxScore ?? 100`, `activeFieldIds ?? const <String>['fard_salah','fard','takbir','morning_azkar','evening_azkar','quran','mulk','miswak','sunnah','post_azkar']`, `specialTimeApplied ?? false`.
- Add `'maxScore'`, `'activeFieldIds'`, `'specialTimeApplied'` to `_logMetadataKeys`.
- Update `toFirestoreMap`, `toEditFirestoreMap`, `toHiveMap` to write the three new fields unconditionally.

#### 4.2 Create `AmalEntryPolicy` (`lib/core/utils/amal_entry_policy.dart`)
- Immutable value object with: `mainFields`, `optionalFields`, `inactiveSpecialTimeFields`, `activeFields`, `isSpecialTimeActive`.
- Logic table:
  - `unset`/`male` → all in `mainFields`, others empty
  - `female` + `specialTimeActive == false` → `femaleDeprioritized` fields in `optionalFields`, rest in `mainFields`
  - `female` + `specialTimeActive == true` → `disableDuringSpecialTime` fields in `inactiveSpecialTimeFields`, rest in `mainFields`
- Riverpod provider `amalEntryPolicyProvider` depending on `amalFieldsListProvider` + `currentUserProvider`.

#### 4.3 Update `AmalNotifier.submit` (`lib/providers/amal_provider.dart`)
- Read `amalEntryPolicyProvider` to get `activeFields`.
- Replace `calculateScore(toggles, fields)` with `calculateAmalScore(toggles: toggles, activeFields: activeFields)`.
- Build `AmalLogModel` with `maxScore`, `activeFieldIds`, `specialTimeApplied` from the result.
- Update `_syncClientSideBadgesAndFeed` perfect-week threshold to `log.score >= (log.maxScore * 0.8).round()` per log.
- Update `AmalState.maxScore` getter to use policy-derived max when unsubmitted, or `state.submittedLog?.maxScore ?? policyMax` when submitted.

#### 4.4 Update `EditAmalScreen._onSubmit` (`lib/features/history/presentation/screens/edit_amal_screen.dart`)
- For **new backfill**: use current `amalEntryPolicyProvider.activeFields` and `calculateAmalScore`. Store `maxScore`, `activeFieldIds`, `specialTimeApplied`.
- For **editing existing log**: reconstruct stored policy from `existingLog.activeFieldIds` (filter `fields` to those IDs) and call `calculateAmalScore` with that list to prevent changing eligibility.

#### 4.5 Update `amal_edit_toggles.dart` (`lib/core/utils/amal_edit_toggles.dart`)
- `editAmalMaxScore` → accept `List<AmalField> activeFields` parameter; derive from that list instead of `getMaxScore(fields)`.
- `editAmalScore` → accept `List<AmalField> activeFields` and call `calculateAmalScore`.

---

## Task 5 — Home Screen / Daily Entry UI

### Current gaps
- `home_screen.dart:321` computes `maxScore = getMaxScore(fields).clamp(1, kDefaultMaxDailyScore)` — global, not policy-aware.
- `home_amal_fields_sliver.dart` renders all `loadedFields` flat — no grouping into main / optional / inactive.
- No gender prompt modal on home screen.
- No special-time toggle in settings.
- `home_progress_card.dart` receives `total: widget.fields.length` — should be active count.

### Implementation steps

#### 5.1 Add gender prompt to Home (`lib/features/home/presentation/screens/home_screen.dart`)
- After `_didInitialAnnouncementCheck` (line ~309), add one-time check: if `user.amalProfile == UserAmalProfile.unset && !user.genderPromptDismissed`, show `GenderSelectionModal`.
- Add `SpecialTimeToggle` widget for female users, reading from `isSpecialTimeActiveForCurrentEntryProvider`.

#### 5.2 Create `GenderSelectionModal` (`lib/shared/widgets/gender_selection_modal.dart`)
- `showDialog` with emerald/gold theming matching `AnnouncementModal`.
- Male/Female selection cards, Confirm button, "Skip for now" button.
- On confirm: call `firestoreService.updateUserGenderPreferences(uid, gender: selected)`.
- On skip: call `firestoreService.updateUserGenderPreferences(uid, genderPromptDismissed: true)`.

#### 5.3 Add Firestore helper (`lib/core/services/firestore_service.dart`)
- `updateUserGenderPreferences(String uid, {String? gender, bool? specialTimeActive, bool? genderPromptDismissed})` — narrow update map.

#### 5.4 Update Settings (`lib/features/settings/presentation/screens/settings_screen.dart`)
- Add `SectionHeader(title: l10n.personalizationSection)`.
- Add `NavRow` for "Gender" that reopens `GenderSelectionModal` (visible for `unset` or always? Recommended: always visible, disabled state if already set).
- Add `ToggleRow` for Special Time (visible only for `female` profile), reading from `isSpecialTimeActiveForCurrentEntryProvider`.

#### 5.5 Policy-aware home field slivers (`lib/features/home/presentation/widgets/home_editing_amal_sliver.dart`)
- Read `amalEntryPolicyProvider` and split fields into three groups:
  1. Main fields (always interactive)
  2. Optional section (`femaleDeprioritized`, collapsed by default for female + specialTime off)
  3. Inactive group (`disableDuringSpecialTime`, disabled style, readOnly)
- Each group rendered via its own `buildHomeAmalFieldSlivers` call or a new grouped builder.

#### 5.6 Update `home_amal_fields_sliver.dart`
- Optionally add a `group` parameter or accept pre-grouped lists; at minimum ensure it can render a subset of fields cleanly.

#### 5.7 Update Home progress card inputs (`lib/features/home/presentation/widgets/home_scroll_body.dart`)
- `done: widget.doneCount` stays (already policy-aware via `AmalState.doneCount` if updated).
- `total: widget.fields.length` → change to policy active count.
- `maxScore: widget.maxScore` → use policy-derived max.

---

## Verification

### Automated
- `flutter test` — existing tests must pass.
- Add tests for `AmalEntryPolicy` across all 6 gender/specialTime combos.
- Add tests for `AmalLogModel` legacy fallback exact values.
- Add tests for `calculateAmalScore` with reduced active sets.

### Manual
- Three-account flow: unset → male → female.
- Female + special-time on → submit → verify `maxScore` and field count in log and UI.
- Female + special-time off → submit → verify full fields restored.
- Edit an existing log → verify stored `activeFieldIds` locks the field set.
- Settings → change gender → home prompt does not reappear if dismissed.

---

## Dependencies / Ordering
1. Task 4.1 (model) + 4.2 (policy) must land first — submit and UI both depend on them.
2. Task 4.3 (submit) + 4.4 (edit submit) can land in parallel after 4.1+4.2.
3. Task 5.1–5.4 (home prompt + settings + modal) can land after 4.2.
4. Task 5.5–5.7 (home UI grouping) lands last, after 4.2 and 5.x.

---

## Open Questions
None. `UserModel`, `UserAmalProfile`, `calculateAmalScore`, and `AmalField` gender attributes already exist in the codebase. The work is integration only.
