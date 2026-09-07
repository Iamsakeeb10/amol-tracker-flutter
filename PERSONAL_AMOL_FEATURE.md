# Personal Amol Feature — Full Implementation Plan

## Background

Amol Tracker lets users track a fixed, admin-defined list of "community amol" each day. Completions feed daily score → leaderboard, streak, and community screens. We are adding **personal amol**: a private, user-defined second category of amol tracked separately, with its own streak and progress indicator, **never visible to or comparable with other users**.

The codebase uses:
- **State management**: Riverpod (`StateNotifierProvider.family`, `FutureProvider`, `StreamProvider`)
- **Backend**: Firestore + local Hive cache
- **Routing**: go_router
- **UI tokens**: `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`
- **Language**: Bangla (bn) + English (en) via ARB l10n
- **Notification IDs already used**: 600, 630, 710–746 (hadith), 800, 840, 2200, 2250, 3000–3500, 9001, 9002 + prayer adhan range

## Codebase Audit Findings

### Leaderboard isolation is already structural
Community amol logs live in the top-level `amal_logs` collection (doc ID `{uid}_{hijriDate}`). The leaderboard/streak/score queries are:

| Function | Collection | Path risk for personal amol |
|---|---|---|
| `communityDayStream` | `amal_logs` | ✅ safe — personal lives in a subcollection |
| `communityDayFetch` | `amal_logs` | ✅ safe |
| `_weeklyLeaderboardQuery` | `amal_logs` | ✅ safe |
| `_monthlyLeaderboardQuery` | `amal_logs` | ✅ safe |
| `streakLeaderboard` | `users` → `currentStreak` | ✅ safe — we write a separate `personalStreak` field |
| `getRecentLogs` / `getLogsInRange` | `amal_logs` | ✅ safe — used for **community streak** only |
| `liveStreakProvider` | `amal_logs` via `getRecentLogs` | ✅ safe — computes community streak from community logs |
| `activityFeedStream` | `activity_feed` | ✅ safe — personal completions never written here |

**Personal amol subcollection path**: `users/{uid}/personal_amol/{amolId}`  
**Personal completion path**: `users/{uid}/personal_amol_completions/{hijriDate}_{amolId}`

Because these are subcollections under the user document, they are **physically unreachable** by any existing top-level collection query. Isolation is structural, not filter-based — but we still add a comment to every leaderboard/score function per the feature spec.

### Existing notification ID map
Existing IDs: 600 (morning), 630 (evening), 710–716 (hadith morning), 740–746 (hadith evening), 800 (jumuah), 840 (ayyam bid), 2200 (streak), 2250 (midnight fallback), 3000–3499 (lesson review), 9001–9002 (legacy).  
Prayer adhan IDs are in a separate range managed by `PrayerAdhanScheduler`.

**Personal amol reminder base ID**: `5000`. Up to 5 personal amol (free tier cap) → IDs `5000`–`5004`.

### State management pattern to follow
All providers in `/lib/providers/` are Riverpod providers. New providers go in `/lib/providers/personal_amol_provider.dart`. The feature's Firestore access goes through a new method group in `FirestoreService` (or a separate `PersonalAmolRepository` class injected into the provider — we will use a **repository class** pattern matching how `AmalFieldsService` is structured for better separation).

### Home screen architecture
`HomeScreen` → passes props to `HomeScrollBody` → uses sliver builder functions (`buildHomeEditingAmalSlivers`, `buildHomeSubmittedAmalSlivers`). The personal section will be added as new sliver builders appended after the community section, inside `home_scroll_body.dart`.

The **save FAB** (`home_save_fab.dart`, shown via `showSaveFab`) applies to community amol only. Personal amol completion is immediate (single tap, no staging state) — no separate FAB needed.

---

## Proposed Changes

### Component 1 — Data Layer

#### [NEW] `lib/models/personal_amol_model.dart`
- `PersonalAmolModel`: `id`, `name`, `icon` (emoji string, max 2 chars or empty), `frequency` (`PersonalAmolFrequency` enum: `daily` | `weekdays` — list of `List<int>` weekday indices 1–7), `reminderTime` (nullable `TimeOfDay`-serializable as `{hour, minute}`), `isActive` (bool), `createdAt` (Timestamp)
- `PersonalAmolCompletion`: `amolId`, `hijriDate`, `completedAt`
- `PersonalAmolFrequency` enum + `fromMap`/`toMap`

> **Comment in file**: Personal amol is stored in a subcollection per user. It is never queried cross-user and must never appear in community score, streak, or leaderboard calculations.

#### [NEW] `lib/models/personal_amol_streak_model.dart`
- `PersonalStreakResult`: `amolId`, `currentStreak`, `bestStreak`
- Stored in `users/{uid}/personal_amol_streaks/{amolId}` (a thin doc per amol — avoids loading all completions to compute streak at runtime)

#### [MODIFY] `lib/core/constants/app_constants.dart`
Add: `static const int kMaxFreePersonalAmol = 5;`

#### [NEW] `lib/core/services/personal_amol_repository.dart`
All Firestore access for personal amol. Methods:
- `Stream<List<PersonalAmolModel>> watchActiveAmol(String uid)`
- `Future<void> createAmol(String uid, PersonalAmolModel amol)`
- `Future<void> updateAmol(String uid, PersonalAmolModel amol)`
- `Future<void> softDeleteAmol(String uid, String amolId)` — sets `isActive=false`
- `Future<List<PersonalAmolCompletion>> getCompletionsForDate(String uid, String hijriDate)`
- `Future<void> markComplete(String uid, String amolId, String hijriDate)`
- `Future<void> unmarkComplete(String uid, String amolId, String hijriDate)`
- `Future<List<PersonalAmolCompletion>> getCompletionsInRange(String uid, String startHijri, String endHijri)`
- `Future<void> updateStreak(String uid, String amolId, {required int currentStreak, required int bestStreak})`
- `Stream<PersonalStreakResult?> watchStreak(String uid, String amolId)`

Firestore paths:
- Definition: `users/{uid}/personal_amol/{amolId}`
- Completion: `users/{uid}/personal_amol_completions/{hijriDate}_{amolId}`
- Streak: `users/{uid}/personal_amol_streaks/{amolId}`

---

### Component 2 — State / Providers

#### [NEW] `lib/providers/personal_amol_provider.dart`
- `personalAmolRepositoryProvider` — `Provider<PersonalAmolRepository>`
- `activePersonalAmolProvider(uid)` — `StreamProvider.family<List<PersonalAmolModel>, String>` — watches `watchActiveAmol`
- `personalAmolCompletionsForTodayProvider(uid)` — `StreamProvider.family<List<PersonalAmolCompletion>, String>` — auto-reloads when `currentHijriDateProvider` changes
- `personalAmolStreakProvider({uid, amolId})` — `StreamProvider.family<PersonalStreakResult?, _StreakKey>` — watches per-amol streak doc
- `PersonalAmolNotifier` (`StateNotifier`) — handles: `create`, `update`, `softDelete`, `toggleComplete` (marks/unmarks + recomputes streak), `scheduleReminder`, `cancelReminder`
- `personalAmolNotifierProvider(uid)` — `StateNotifierProvider.family`

**`toggleComplete` streak logic** (inside `PersonalAmolNotifier`):
1. Fetch completions for last 30 days.
2. Compute consecutive days ending today (using same `computeStreakFromLogs` helper already in `streak_helper.dart` — reused, not duplicated).
3. Write to `personal_amol_streaks/{amolId}`.

> This is intentionally separate from `liveStreakProvider` which computes the community streak from `amal_logs`. Personal streak is only ever read from `personal_amol_streaks`.

---

### Component 3 — Firestore Security Rules + Indexes

#### Firestore security rules (add to existing rules)
- `users/{uid}/personal_amol/{doc}` — read/write only by `request.auth.uid == uid`
- `users/{uid}/personal_amol_completions/{doc}` — same
- `users/{uid}/personal_amol_streaks/{doc}` — same

#### [MODIFY] `firestore.indexes.json`
Add composite index for `watchActiveAmol`:
`collectionGroup: personal_amol` on `isActive ASC` + `createdAt DESC`.
(All personal-amol completions/streaks queries use only single-field filters,
which need no explicit composite index.)

---

### Component 4 — Create/Edit Screen

#### [NEW] `lib/features/personal_amol/presentation/screens/personal_amol_list_screen.dart`
Manage list of personal amol (not shown on home — reached from the "+" icon in the personal section header). Shows existing personal amol with edit/delete. Has an "Add personal amol" FAB (disabled at cap).

#### [NEW] `lib/features/personal_amol/presentation/screens/personal_amol_form_screen.dart`
Create / Edit form:
- **Name field**: `TextFormField`, max 40 chars, required
- **Icon/emoji picker**: `EmojiPicker` — simple inline grid of 30 common emojis (no third-party emoji picker library dependency — avoid new pub deps unless necessary). Falls back to the first letter of the name as avatar if empty.
- **Frequency selector**: `daily` (default) or weekday picker (row of 7 circular day buttons: স রো ম বু বৃ শু শ)
- **Reminder time**: optional time picker using existing `TimePickerSheet` from `shared/widgets/time_picker_sheet.dart`
- **Save / Delete**: save validates name, delete shows confirmation dialog → calls `softDelete`
- **Cap enforcement**: if at limit and creating new, show inline banner: `"আপনি আপনার ৫টি ব্যক্তিগত আমলের সীমায় পৌঁছেছেন।"` and disable save button

#### [NEW] `lib/features/personal_amol/` directory structure:
```
lib/features/personal_amol/
  presentation/
    screens/
      personal_amol_form_screen.dart
    widgets/
      personal_amol_tile.dart       ← dashed-border card (home + list)
      personal_amol_section.dart    ← home section widget
      personal_amol_empty_state.dart
      personal_amol_progress_row.dart  ← small progress indicator
```

---

### Component 5 — Home Screen Integration

#### [MODIFY] `lib/features/home/presentation/widgets/home_scroll_body.dart`
After `buildHomeEditingAmalSlivers` / `buildHomeSubmittedAmalSlivers`, append:
```
SliverToBoxAdapter(child: SizedBox(height: 14.h)),
const SliverToBoxAdapter(
  child: PersonalAmolSection(uid: uid),
),
```

The existing `showSaveFab` logic and bottom padding already accounts for the FAB height. Since personal amol completions are immediate taps (no staging), there's no save-bar interaction from the personal section.

#### [NEW] `lib/features/personal_amol/presentation/widgets/personal_amol_section.dart`
A `ConsumerWidget` that:
1. Reads `activePersonalAmolProvider(uid)` and `personalAmolCompletionsForTodayProvider(uid)`
2. Shows section header row: `[user icon] ব্যক্তিগত আমল [leaderboard-এ নয় badge] [+ button]`
3. Loading: shimmer skeleton
4. Empty state: dashed-border card (matching `amol_tracker_empty_state_no_fab.html`)
   - Center icon, headline `"নিজের আমল যোগ করুন"`, subtitle, gold CTA button
4. Has items: one `PersonalAmolTile` per active amol + a small "personal progress" mini-bar at section top
5. At cap: "+" button still shows but navigates to list screen which shows cap message (no silent disable — user gets feedback)

#### [NEW] `lib/features/personal_amol/presentation/widgets/personal_amol_tile.dart`
- **Dashed border** (1.2px, `AppColors.emeraldMid`) — uses `CustomPaint` or `DashedBorder` (we'll implement `DashedBorderPainter` inline — no new package)
- Fields shown: `name`, `emoji/icon`, `frequency label + personal streak`
- Check toggle: tapping the trailing circle → calls `toggleComplete`
- Done state: circle fills with `AppColors.gold`; row text color brightens
- Read-only variant (for submitted community day): still shows check state but toggle disabled

#### [NEW] `lib/features/personal_amol/presentation/widgets/personal_amol_progress_row.dart`
Small row below section header: `"৩/৫ সম্পন্ন"` with a thin progress bar. Displayed above the tiles. Replaces the "leaderboard-এ নয়" badge positioning (badge is in the header; progress row is below the header, above tiles). This is the **separate progress indicator** (choice b from the feature spec), not merged into the community ring.

---

### Component 6 — Routing

#### [MODIFY] `lib/core/router/routes.dart`
```dart
static const personalAmolList = '/personal-amol';
static const personalAmolCreate = '/personal-amol/create';
static const personalAmolEditPattern = '/personal-amol/edit/:amolId';
static String personalAmolEditPath(String amolId) => '/personal-amol/edit/$amolId';
```

#### [MODIFY] `lib/core/router/router.dart`
Add three `GoRoute` entries inside the shell (authenticated guard already in place):
- `/personal-amol` → `PersonalAmolListScreen`
- `/personal-amol/create` → `PersonalAmolFormScreen(existingAmol: null)`
- `/personal-amol/edit/:amolId` → `PersonalAmolFormScreen(existingAmolId: state.pathParameters['amolId']!)`

---

### Component 7 — Notifications

#### [MODIFY] `lib/core/services/notification_service.dart`
Add:
```dart
static const int _personalAmolBaseId = 5000;
// Personal amol reminders: IDs 5000–5004 (one per free-tier slot).
// These must NEVER collide with community amol, adhan, hadith, streak, or
// lesson-review notification IDs.
```

New methods:
- `schedulePersonalAmolReminder({required int slot, required String name, required TimeOfDay time})` — schedules a daily local notification at the given time
- `cancelPersonalAmolReminder(int slot)` — cancels by `_personalAmolBaseId + slot`
- `cancelAllPersonalAmolReminders()` — cancels IDs 5000–5004

Called from `PersonalAmolNotifier.create/update/softDelete`.

---

### Component 8 — Leaderboard / Score Isolation Comments

#### [MODIFY] `lib/core/services/firestore_service.dart`
Add a one-line `// 🔒 Personal amol must never be included here — see PERSONAL_AMOL_FEATURE.md` comment above each of:
- `communityDayStream` (L568)
- `communityDayFetch` (L585)
- `_weeklyLeaderboardQuery` (L680)
- `_monthlyLeaderboardQuery` (L740)
- `streakLeaderboard` (L801)
- `getRecentLogs` (L652) — used by `liveStreakProvider`

#### [MODIFY] `lib/providers/leaderboard_provider.dart`
Same comment above each of: `dailyLeaderboardProvider`, `weeklyLeaderboardProvider`, `monthlyLeaderboardProvider`, `streakLeaderboardProvider`, `quizLeaderboardProvider`, `battleLeaderboardProvider`.

#### [MODIFY] `lib/providers/history_provider.dart`
Comment above `liveStreakProvider` — it reads only from `amal_logs` (community).

**Why no code change is needed**: personal amol completions live in `users/{uid}/personal_amol_completions/` — a subcollection never joined by any of the above queries. Structural isolation is already guaranteed. Comments are the documentation layer.

---

### Component 9 — Localization

#### [MODIFY] `lib/l10n/app_en.arb` + `app_bn.arb`
New keys (Bangla shown):
```
"personalAmolSectionTitle": "ব্যক্তিগত আমল",
"personalAmolNotOnLeaderboard": "leaderboard-এ নয়",
"personalAmolEmptyHeadline": "নিজের আমল যোগ করুন",
"personalAmolEmptySubtitle": "দৈনন্দিন যেকোনো অভ্যাস ট্র্যাক করুন, শুধু আপনার জন্য",
"personalAmolEmptyCta": "যোগ করুন",
"personalAmolCapMessage": "আপনি আপনার {max}টি ব্যক্তিগত আমলের সীমায় পৌঁছেছেন।",
"personalAmolFrequencyDaily": "প্রতিদিন",
"personalAmolFrequencyWeekdays": "নির্দিষ্ট দিনে",
"personalAmolStreakLabel": "{n} দিনের স্ট্রিক",
"personalAmolDeleteConfirm": "এই আমলটি মুছে ফেলবেন?",
"personalAmolDeleteSubtitle": "আপনার ইতিহাস মুছে যাবে না।",
"personalAmolProgressLabel": "{done}/{total} সম্পন্ন",
```

---

### Component 10 — Tests

#### [NEW] `test/personal_amol/`
Test cases per feature spec §5 (Chunk 5):
1. `personal_only_user_has_zero_community_points_test.dart` — user with only personal completions: community score = 0, not in `dailyLeaderboard`, not in `weeklyLeaderboard`
2. `community_and_personal_mixed_test.dart` — community score equals only community amol points; personal completions don't inflate
3. `leaderboard_identical_with_without_personal_test.dart` — leaderboard results identical regardless of personal completions existence
4. `personal_amol_cap_test.dart` — creating 6th personal amol is blocked; correct UI state
5. `soft_delete_preserves_completions_test.dart` — soft delete sets `isActive=false`; completion records still present
6. `notification_id_collision_test.dart` — personal reminder IDs (5000–5004) don't intersect with community IDs
7. `existing_user_regression_test.dart` — user with zero personal amol: home screen, progress ring, streak unchanged

---

## Open Questions

> [!IMPORTANT]
> **Emoji picker approach**: The plan uses an inline emoji grid (no new library). Should we allow free-text emoji input instead (user types/pastes any emoji), or stick with the curated picker grid?

> [!IMPORTANT]
> **Weekly streak reset policy**: Should the personal amol streak use the same "midnight boundary" as community streak (Gregorian midnight, Dhaka timezone), or the Hijri day boundary? The plan defaults to **Hijri day boundary** (matching the community streak system).

> [!IMPORTANT]
> **History screen**: The existing History screen shows community amol logs by Hijri month. Should personal amol completions appear in the history screen (as a separate section per day), or is that a future iteration?  The plan **defers** this to a future chunk.

> [!IMPORTANT]
> **Localization**: All personal amol UI copy in the plan above is Bangla-first. Are the Bangla strings final, or do they need copywriter review before we hard-code them in the ARB file?

> [!NOTE]
> **Reminder UX**: Reminders for personal amol will trigger a local notification with the amol name. On tap, they deep-link to `/home`. This matches the community amol reminder behavior.

---

## Proposed Execution Order

| # | Chunk | Files touched |
|---|---|---|
| 1 | Data model + repository | `personal_amol_model.dart`, `personal_amol_streak_model.dart`, `personal_amol_repository.dart`, `app_constants.dart` |
| 2 | Providers | `personal_amol_provider.dart` |
| 3 | Routing | `routes.dart`, `router.dart` |
| 4 | Create/Edit screen | `personal_amol_form_screen.dart`, `personal_amol_list_screen.dart` |
| 5 | Home screen widgets | `personal_amol_section.dart`, `personal_amol_tile.dart`, `personal_amol_progress_row.dart`, `personal_amol_empty_state.dart` |
| 6 | Home screen integration | `home_scroll_body.dart` |
| 7 | Notifications | `notification_service.dart` |
| 8 | Isolation comments | `firestore_service.dart`, `leaderboard_provider.dart`, `history_provider.dart` |
| 9 | Localization | `app_en.arb`, `app_bn.arb` |
| 10 | Firestore rules + indexes | `firestore.rules`, `firestore.indexes.json` |
| 11 | Tests | `test/personal_amol/` |

We execute each chunk sequentially and stop for review after each. No community amol model, controller, or repository is modified in behaviour at any step.

---

## Verification Plan

### Automated Tests
```bash
flutter test test/personal_amol/
```

### Manual Verification
- [ ] Existing user (zero personal amol): home screen looks unchanged; streak/progress ring unchanged
- [ ] Create personal amol → appears on home screen with dashed border; community amol tiles unchanged
- [ ] Toggle personal amol → personal progress row updates; community progress bar unchanged
- [ ] Personal amol streak increments separately; community streak unchanged
- [ ] Leaderboard tab shows same data with/without personal completions
- [ ] At cap (5 amol): "+" navigates to list → cap message shown; no 6th can be created
- [ ] Soft delete: amol disappears from home; historical personal progress records still exist in Firestore
- [ ] Reminder fires at scheduled time; notification ID does not match any community notification ID
