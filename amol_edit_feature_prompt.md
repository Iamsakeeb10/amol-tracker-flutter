# ✏️ Amol Tracker — Edit Previous Amal Log Feature

# Implementation Prompt for Cursor

# Read every word before touching any file.

---

## Context (what Cursor needs to know)

This is a Flutter app using:

- Riverpod (flutter_riverpod + riverpod)
- GoRouter (routes in lib/core/router/router.dart)
- Firestore (top-level `amal_logs` collection, doc ID = `{uid}_{hijriDate}`)
- Hive (3 boxes: `amal_logs`, `prefs`, `app_cache`)
- IslamicDateService for all date logic (Maghrib-based, Bangladesh UTC+6)
- Feature-first folder structure: lib/features/{feature}/presentation/screens/

### Key existing files to read BEFORE writing any code:

1. lib/models/amal_log_model.dart
2. lib/core/constants/default_amal_fields.dart
3. lib/core/utils/streak_helper.dart
4. lib/core/services/firestore_service.dart
5. lib/core/services/local_storage_service.dart
6. lib/core/services/islamic_date_service.dart
7. lib/providers/amal_provider.dart
8. lib/providers/history_provider.dart
9. lib/features/history/presentation/screens/history_screen.dart
10. lib/features/history/presentation/screens/day_detail_screen.dart
11. lib/core/router/router.dart
12. lib/core/router/routes.dart

---

## Feature Requirements

### What this feature does

Allow users to edit their amal log for any of the **past 6 Hijri days**
(today is always the home screen, so edit window = yesterday back 6 days = 6 past days total).

### Core rules — read carefully

- ✅ Editing updates: amal fields, score, Hive cache, Firestore doc, community sheet
- ✅ Editing updates: personal history calendar color for that day
- ✅ Editing updates: leaderboard score (edits ARE reflected — this is intentional)
- ❌ Editing NEVER changes: currentStreak, bestStreak, streakFreezeUsed, lastLogDate
- ❌ Editing NEVER triggers streak recalculation of any kind
- ❌ Editing NEVER creates a new submission — only updates existing amal field values
- ❌ Editing is NOT possible if no log was submitted for that day (no log = nothing to edit)
- ❌ Editing is NOT possible for days older than 6 Hijri days ago
- ❌ Editing is NOT possible for today (today uses the home screen)
- ❌ Editing is NOT possible for future days
- ❌ Editing is NOT possible for days before account creation

### Takbir constraint (must enforce on edit too)

Takbir value cannot exceed Fard value. Same validation as home screen.

---

## Implementation Plan

### Step 1 — Add editedAt field to AmalLogModel

In `lib/models/amal_log_model.dart`:

Add these fields:

```dart
final DateTime? editedAt;   // null if never edited
final int editCount;        // 0 if never edited, increments on each edit
```

Update `fromDoc()` to parse them:

```dart
editedAt: data['editedAt'] is Timestamp
    ? (data['editedAt'] as Timestamp).toDate()
    : null,
editCount: (data['editCount'] as num?)?.toInt() ?? 0,
```

Add a new method `toEditFirestoreMap()` that updates ONLY these fields:

```dart
Map<String, dynamic> toEditFirestoreMap(List<AmalField> fields) {
  final out = <String, dynamic>{
    'score': score,
    'editedAt': Timestamp.fromDate(DateTime.now().toUtc()),
    'editCount': FieldValue.increment(1),
  };
  for (final field in fields) {
    if (field.type == AmalType.numeric) {
      out[field.id] = getNumericValue(toggles[field.id], field.maxValue);
    } else {
      out[field.id] = toggles[field.id] == true;
    }
  }
  return out;
  // NOTE: uid, displayName, photoUrl, isAnonymousDisplay,
  //       hijriDate, submittedAt are NOT included — never change on edit
}
```

---

### Step 2 — Add editAmalLog() to FirestoreService

In `lib/core/services/firestore_service.dart`, add:

```dart
Future<void> editAmalLog({
  required AmalLogModel updatedLog,
  required List<AmalField> fields,
}) async {
  final docId = updatedLog.docId; // {uid}_{hijriDate}
  await _firestore
      .collection('amal_logs')
      .doc(docId)
      .update(updatedLog.toEditFirestoreMap(fields));
  // NOTE: update() not set() — preserves uid, submittedAt, displayName etc.
  // NOTE: streak fields on users/ doc are NOT touched here
}
```

---

### Step 3 — Add edit capability to history_provider.dart

In `lib/providers/history_provider.dart`, add a new provider:

```dart
// Checks if a given Hijri date string is within the editable window
// Editable = has a submitted log AND is within past 6 Hijri days
// Returns null if not editable, returns the existing log if editable
final editableLogProvider = FutureProvider.family<AmalLogModel?, String>(
  (ref, hijriDate) async {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return null;

    // Check date is within 6 past Hijri days
    final today = IslamicDateService.getCurrentIslamicDateString();
    if (hijriDate == today) return null; // today = home screen
    if (!IslamicDateService.isWithinEditWindow(hijriDate, today, 6)) return null;

    // Check log exists
    final firestoreService = ref.read(firestoreServiceProvider);
    final log = await firestoreService.getLog(user.uid, hijriDate);
    if (log == null) return null; // no log = nothing to edit
    return log;
  },
);
```

---

### Step 4 — Add isWithinEditWindow() to IslamicDateService

In `lib/core/services/islamic_date_service.dart`, add:

```dart
/// Returns true if [targetDate] is within [windowDays] past Hijri days
/// relative to [todayDate]. Does not include today itself.
static bool isWithinEditWindow(
  String targetDate,
  String todayDate,
  int windowDays,
) {
  try {
    final target = _parseHijriToGregorian(targetDate);
    final today  = _parseHijriToGregorian(todayDate);
    final diff   = today.difference(target).inDays;
    return diff >= 1 && diff <= windowDays;
  } catch (_) {
    return false;
  }
}

// Private helper — convert hijri storage string to Gregorian DateTime
static DateTime _parseHijriToGregorian(String hijriDate) {
  final parts = hijriDate.split('-');
  final h = HijriCalendar()
    ..hYear  = int.parse(parts[0])
    ..hMonth = int.parse(parts[1])
    ..hDay   = int.parse(parts[2]);
  final greg = h.hijriToGregorian(h.hYear, h.hMonth, h.hDay);
  return DateTime(greg.year, greg.month, greg.day);
}
```

---

### Step 5 — Create the edit screen

Create new file:
`lib/features/history/presentation/screens/edit_amal_screen.dart`

This screen is almost identical to HomeScreen's amal form, but:

- Title shows the Hijri date being edited (Bengali format)
- No streak banner
- No streak freeze flow
- Submit button says "আমল আপডেট করুন" (Update Amal)
- Shows a subtle info banner: "স্ট্রিক পরিবর্তন হবে না" (Streak will not change)
- On load: pre-fills from the existing log (all toggles and numeric values)
- On submit: calls editAmalLog(), updates Hive, pops screen
- Takbir stepper: max = current fard value (same constraint as home screen)
- Shows "সম্পাদিত" (Edited) badge after successful edit

```dart
class EditAmalScreen extends ConsumerStatefulWidget {
  final String hijriDate;        // the date being edited
  final AmalLogModel existingLog; // pre-loaded log

  const EditAmalScreen({
    super.key,
    required this.hijriDate,
    required this.existingLog,
  });
}
```

#### Edit screen state management

Do NOT reuse `amalProvider` for edits — it manages today's state.
Create a local `StateNotifier` inside this screen or use `StateProvider`
with a local override. Keep edit state fully local to this screen.

#### Edit submit flow (inside EditAmalScreen):

```
1. Validate: at least 1 field has a value
2. Validate: takbir <= fard
3. Compute new score with calculateScore()
4. Build updated AmalLogModel (keep original uid, submittedAt, hijriDate)
5. Call FirestoreService.editAmalLog(updatedLog, fields)
6. Update Hive: LocalStorageService.cacheSubmittedLog(updatedLog)
7. Invalidate historyMonthProvider for that month (force calendar refresh)
8. Invalidate dayDetailLogProvider for that date (force detail refresh)
9. Show success snackbar: "আমল আপডেট হয়েছে ✓"
10. Pop screen → back to DayDetailScreen (which now shows updated data)
```

---

### Step 6 — Update DayDetailScreen to show edit button

In `lib/features/history/presentation/screens/day_detail_screen.dart`:

Add an "Edit" button in the app bar or bottom — but only when:

- The log exists for this day (not noData)
- The day is within the 6-day edit window
- Use `editableLogProvider` to determine this

```dart
// In DayDetailScreen build():
final editableLog = ref.watch(editableLogProvider(hijriDate));

// Show edit button only when editable
editableLog.whenData((log) {
  if (log != null) {
    // Show floating edit button or app bar action
    // On tap: context.push(AppRoutes.editAmalPath(hijriDate), extra: log)
  }
});
```

The edit button UI:

- Floating action button with pencil icon
- Gold color (AppColors.gold)
- Only visible when editableLog is non-null
- Shows a tooltip: "এই দিনের আমল সম্পাদনা করুন"

If the log was previously edited, show a small "সম্পাদিত" chip
near the score (check `existingLog.editedAt != null`).

---

### Step 7 — Register new routes

In `lib/core/router/routes.dart`, add:

```dart
static const editAmal = 'editAmal';
static String editAmalPath(String hijriDate) => '/history/edit-amal/$hijriDate';
```

In `lib/core/router/router.dart`, add inside the history shell:

```dart
GoRoute(
  path: '/history/edit-amal/:date',
  name: AppRoutes.editAmal,
  builder: (context, state) {
    final hijriDate = state.pathParameters['date']!;
    final existingLog = state.extra as AmalLogModel;
    return EditAmalScreen(
      hijriDate: hijriDate,
      existingLog: existingLog,
    );
  },
),
```

---

### Step 8 — Update Hive cache after edit

In `lib/core/services/local_storage_service.dart`:

The existing `cacheSubmittedLog()` method should already work for edits
since it uses the same key `log_{uid}_{hijriDate}`. Verify it uses
`box.put()` not `box.putIfAbsent()` — it must overwrite on edit.

If it uses `putIfAbsent`, change it to `put()`.

---

### Step 9 — Invalidate providers after edit

After a successful edit in EditAmalScreen, invalidate:

```dart
// Force history calendar to reload this month
ref.invalidate(historyMonthProvider(HistoryMonthKey(
  uid: user.uid,
  year: hijriYear,
  month: hijriMonth,
)));

// Force day detail to reload
ref.invalidate(dayDetailLogProvider(DayDetailKey(
  uid: user.uid,
  hijriDate: hijriDate,
)));
```

The community sheet will update automatically since it uses
a real-time stream for today. For past dates it uses one-time
`get()` — the user can pull-to-refresh or re-tap the date tab.

---

### Step 10 — History screen: show edit indicator on calendar cells

In `lib/features/history/presentation/screens/history_screen.dart`:

For days that have been edited (`editedAt != null` on the log),
show a small pencil icon or dot overlay on the calendar cell.
This is optional polish — implement only after core flow works.

---

## What NOT to do

- ❌ Do NOT modify AmalNotifier or the home screen submit flow
- ❌ Do NOT touch streak fields (currentStreak, bestStreak, lastLogDate)
- ❌ Do NOT call computeStreakResult() from the edit flow
- ❌ Do NOT use set() to write the edit — use update() to preserve submittedAt
- ❌ Do NOT show the streak freeze modal from the edit flow
- ❌ Do NOT allow editing today's log (today = home screen only)
- ❌ Do NOT allow editing if no log was submitted for that day
- ❌ Do NOT create a new log document — only update existing one
- ❌ Do NOT reuse amalProvider state — use local state for edit form

---

## Fix the existing bug while you're here

In `lib/core/services/notification_service.dart`:

The streak warning scheduler checks:
`users/{uid}/amalLogs/{hijriDate}`

This path is wrong. The app writes logs to:
`amal_logs/{uid}_{hijriDate}`

Fix the streak warning check to use the correct path:

```dart
// WRONG:
final doc = await _firestore
    .collection('users')
    .doc(uid)
    .collection('amalLogs')
    .doc(hijriDate)
    .get();

// CORRECT:
final docId = '${uid}_$hijriDate';
final doc = await _firestore
    .collection('amal_logs')
    .doc(docId)
    .get();
```

---

## Testing checklist after implementation

### Edit flow

- [ ] DayDetailScreen shows edit button for yesterday's log
- [ ] DayDetailScreen shows edit button for 2, 3, 4, 5, 6 days ago
- [ ] DayDetailScreen does NOT show edit button for today
- [ ] DayDetailScreen does NOT show edit button for 7+ days ago
- [ ] DayDetailScreen does NOT show edit button if no log exists for that day
- [ ] Tapping edit button opens EditAmalScreen with pre-filled values
- [ ] Fard stepper shows correct current value
- [ ] Takbir stepper is capped at current fard value
- [ ] Changing fard down automatically caps takbir too
- [ ] Boolean toggles show correct current state
- [ ] "আমল আপডেট করুন" button saves changes to Firestore
- [ ] Score recalculates correctly after edit
- [ ] Hive cache updates after edit
- [ ] History calendar color updates after edit (may need screen re-enter)
- [ ] Day detail screen shows updated values after pop back
- [ ] "সম্পাদিত" badge shows on day detail after first edit
- [ ] editedAt and editCount are saved to Firestore doc

### Streak protection

- [ ] currentStreak on user doc does NOT change after edit
- [ ] bestStreak on user doc does NOT change after edit
- [ ] lastLogDate on user doc does NOT change after edit
- [ ] streakFreezeUsed on user doc does NOT change after edit

### Edge cases

- [ ] Edit a day where fard was 5, change to 3 → takbir auto-caps at 3
- [ ] Edit a day with fard=0, takbir must be 0 (cannot set takbir > 0)
- [ ] Offline edit: fails gracefully with error snackbar, no data corruption
- [ ] Editing twice: editCount increments to 2, editedAt updates to latest

### Bug fix

- [ ] Streak warning notification checks `amal_logs/{uid}_{hijriDate}` (correct path)
- [ ] Streak warning fires correctly when user hasn't logged today

---

## Implementation order

Do these in order. Test each step before moving to next.

1. AmalLogModel — add editedAt, editCount, toEditFirestoreMap()
2. IslamicDateService — add isWithinEditWindow()
3. FirestoreService — add editAmalLog()
4. history_provider — add editableLogProvider
5. Routes — add editAmal route
6. EditAmalScreen — create the file
7. DayDetailScreen — add edit button and edited badge
8. LocalStorageService — verify cache overwrite works
9. NotificationService — fix the wrong Firestore path bug
10. Test everything
