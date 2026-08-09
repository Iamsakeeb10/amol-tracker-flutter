# Gender-Based Amal — Remaining Completion Items

## Current State

Sections 1–5 of the implementation plan are functionally complete. Two items remain:

1. **`edit_amal_screen.dart` display bug (Section 3)** — The on-screen score/max still compute from the full field list instead of the already-derived `activeFields`.
2. **`admin_amal_field_form_screen.dart` missing personalization section (Section 6)** — No form controls exist for `genderVisibility`, `femaleDeprioritized`, or `disableDuringSpecialTime`.

## Remaining Tasks

### Task 1: Fix edit_amal_screen.dart display

**File:** `lib/features/history/presentation/screens/edit_amal_screen.dart:323–324`

**Current code:**
```dart
final maxScore = editAmalMaxScore(fields);
final score = calculateScore(_toggles, fields);
```

**Change to:**
```dart
final maxScore = editAmalMaxScore(activeFields);
final score = editAmalScore(_toggles, activeFields);
```

**Rationale:** `activeFields` is already computed at lines 152–161 using either the policy (new backfill) or the stored `existing.activeFieldIds` (edit). The display must match the same set used for scoring and persistence. This is a 2-line edit.

### Task 2: Add Personalization section to admin form

**File:** `lib/features/admin/presentation/screens/admin_amal_field_form_screen.dart`

**State to add in `_AdminAmalFieldFormScreenState`:**
```dart
late GenderVisibility _genderVisibility;
late bool _femaleDeprioritized;
late bool _disableDuringSpecialTime;
```

**Initialize in `initState`:**
```dart
_genderVisibility = e?.genderVisibility ?? GenderVisibility.all;
_femaleDeprioritized = e?.femaleDeprioritized ?? false;
_disableDuringSpecialTime = e?.disableDuringSpecialTime ?? false;
```

**Update `_buildDraft()` to pass the new fields:**
```dart
return buildDraftAmalField(
  ...
  genderVisibility: _genderVisibility,
  femaleDeprioritized: _femaleDeprioritized,
  disableDuringSpecialTime: _disableDuringSpecialTime,
);
```

**Update `_save()` `amalFieldToFirestoreMap` call to pass the new fields.**

**Add UI section in `build()` after the Display section and before `AdminFormActionRow`:**

```dart
SectionHeader(title: l10n.adminAmalFieldPersonalizationSection.toUpperCase()),
CardContainer(
  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
  child: Column(
    children: [
      AdminFormField(
        label: l10n.adminAmalFieldGenderVisibility,
        controller: _genderVisibilityCtrl, // or use a Dropdown/selector
        icon: Icons.people_outline,
      ),
      const Divider(),
      AdminToggleRow(
        icon: Icons.priority_high_outlined,
        title: l10n.adminAmalFieldFemaleDeprioritized,
        subtitle: l10n.adminAmalFieldFemaleDeprioritizedSubtitle,
        value: _femaleDeprioritized,
        onChanged: (v) => setState(() => _femaleDeprioritized = v),
      ),
      const Divider(),
      AdminToggleRow(
        icon: Icons.pause_circle_outline,
        title: l10n.adminAmalFieldDisableDuringSpecialTime,
        subtitle: l10n.adminAmalFieldDisableDuringSpecialTimeSubtitle,
        value: _disableDuringSpecialTime,
        onChanged: (v) => setState(() => _disableDuringSpecialTime = v),
      ),
    ],
  ),
),
```

**Localization keys needed in both `app_en.arb` and `app_bn.arb`:**
- `adminAmalFieldPersonalizationSection`
- `adminAmalFieldGenderVisibility`
- `adminAmalFieldFemaleDeprioritized`
- `adminAmalFieldFemaleDeprioritizedSubtitle`
- `adminAmalFieldDisableDuringSpecialTime`
- `adminAmalFieldDisableDuringSpecialTimeSubtitle`

### Task 3: Verify localization completeness

**Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_bn.arb`

Confirm the keys listed in the plan (`genderSelectionTitle`, `genderSelectionSubtitle`, `genderMale`, `genderFemale`, `genderConfirm`, `genderSkip`, `specialTimeToggleTitle`, `specialTimeToggleSubtitle`, `personalizationSection`, `settingsGender`, `optionalAmalSection`, `inactiveSpecialTimeSection`) exist in both ARB files. They already exist per the grep results — no action needed unless any are missing.

## Validation

1. Run `flutter analyze` after edits.
2. Verify `edit_amal_screen.dart` no longer references `calculateScore` or `editAmalMaxScore(fields)` — only `activeFields`.
3. Verify admin form builds a draft and saves with the three new fields by inspecting Firestore write payload.
4. Manual: Create/edit an amal field as admin and confirm the personalization attributes persist.

## Out of Scope

- `tool/migrate_amal_fields.dart` — the one-time migration script. Existing code already handles missing fields with safe defaults (`_parseBool`, `_parseGenderVisibility`). Migration can be added later if needed.
- Test additions — existing test infrastructure should be extended separately.
