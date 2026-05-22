# Codebase Analysis Report

Scope: all files under `lib/`, plus Firestore/security infrastructure files at the repo root.

## 1. Screens & Navigation

There is no top-level `lib/screens/` directory in this project. Screens are organized by feature under `lib/features/**/screens/`. The app currently has 21 screen files in that structure.

### Screen inventory

| File                                                                                                                                                   | What it does                                                                                                                                                                                 |
| ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [lib/features/auth/presentation/screens/sign_in_screen.dart](lib/features/auth/presentation/screens/sign_in_screen.dart)                               | Entry screen for Google sign-in or anonymous guest access. It also syncs the FCM token after a successful sign-in.                                                                           |
| [lib/features/onboarding/presentation/screens/onboarding_screen.dart](lib/features/onboarding/presentation/screens/onboarding_screen.dart)             | Three-step onboarding flow that explains the app, captures display name/privacy preference, and optionally requests notification permission. It creates the initial Firestore user document. |
| [lib/features/home/presentation/screens/home_screen.dart](lib/features/home/presentation/screens/home_screen.dart)                                     | Main daily amal dashboard. It shows today’s progress, lets the user toggle/enter amals, submit today’s log, and handles streak-freeze decisions.                                             |
| [lib/features/home/presentation/screens/day_complete_screen.dart](lib/features/home/presentation/screens/day_complete_screen.dart)                     | Post-submit success screen showing the score ring, a hadith, and a summary of earned points for the day.                                                                                     |
| [lib/features/home/presentation/screens/empty_state_screen.dart](lib/features/home/presentation/screens/empty_state_screen.dart)                       | Empty-state landing screen used when no daily log exists yet. It shows a hadith and prompts the user toward Home or Community.                                                               |
| [lib/features/history/presentation/screens/history_screen.dart](lib/features/history/presentation/screens/history_screen.dart)                         | Hijri month calendar/history view. It visualizes past days, consistency, average score, best streak, and weak amals.                                                                         |
| [lib/features/history/presentation/screens/day_detail_screen.dart](lib/features/history/presentation/screens/day_detail_screen.dart)                   | Read-only detail view for a selected Hijri day. It displays the saved log, score, and all amal fields for that date.                                                                         |
| [lib/features/community/presentation/screens/community_screen.dart](lib/features/community/presentation/screens/community_screen.dart)                 | Community feed and daily sheet view. It shows today’s ranking/table, supports date switching, search, pagination, and opens user profiles.                                                   |
| [lib/features/community/presentation/screens/user_profile_screen.dart](lib/features/community/presentation/screens/user_profile_screen.dart)           | Public profile page for a community member. It shows their streak, score summaries, daily amal breakdown, recent week logs, and lets the owner edit privacy/name or send dua to others.      |
| [lib/features/leaderboard/presentation/screens/leaderboard_screen.dart](lib/features/leaderboard/presentation/screens/leaderboard_screen.dart)         | Daily, weekly, and streak leaderboards with podium, rank rows, and a motivational nudge.                                                                                                     |
| [lib/features/notifications/presentation/screens/notifications_screen.dart](lib/features/notifications/presentation/screens/notifications_screen.dart) | Notification inbox with unread count, mark-all-read action, and routing based on notification type.                                                                                          |
| [lib/features/profile/presentation/screens/profile_screen.dart](lib/features/profile/presentation/screens/profile_screen.dart)                         | Personal profile, privacy toggle, weekly chart, stats, and badge progress. It also supports editing the user display name.                                                                   |
| [lib/features/settings/presentation/screens/settings_screen.dart](lib/features/settings/presentation/screens/settings_screen.dart)                     | Main settings hub for notifications, quiet hours, privacy, language, sign-out, and some app toggles.                                                                                         |
| [lib/features/settings/presentation/screens/reminder_times_screen.dart](lib/features/settings/presentation/screens/reminder_times_screen.dart)         | Dedicated screen for morning/evening reminder times.                                                                                                                                         |
| [lib/features/settings/presentation/screens/quiet_hours_screen.dart](lib/features/settings/presentation/screens/quiet_hours_screen.dart)               | Quiet-hours editor with time pickers and hour bump controls.                                                                                                                                 |
| [lib/features/settings/presentation/screens/more_screen.dart](lib/features/settings/presentation/screens/more_screen.dart)                             | Secondary hub screen for account, leaderboard, notifications, profile, and settings navigation.                                                                                              |
| [lib/features/friends/presentation/screens/friends_screen.dart](lib/features/friends/presentation/screens/friends_screen.dart)                         | Mock social/friends dashboard showing activity, a group card, and friend cards.                                                                                                              |
| [lib/features/friends/presentation/screens/friend_profile_screen.dart](lib/features/friends/presentation/screens/friend_profile_screen.dart)           | Mock friend profile view with stats, amal grid, and week chart.                                                                                                                              |
| [lib/features/friends/presentation/screens/group_manage_screen.dart](lib/features/friends/presentation/screens/group_manage_screen.dart)               | Mock group-management view with invite code actions, member list, and group settings toggles.                                                                                                |
| [lib/features/friends/presentation/screens/group_sheet_screen.dart](lib/features/friends/presentation/screens/group_sheet_screen.dart)                 | Mock group sheet/table view for member amal comparison.                                                                                                                                      |
| [lib/features/friends/presentation/screens/invite_screen.dart](lib/features/friends/presentation/screens/invite_screen.dart)                           | Mock invite/join-group flow with copyable invite code and a join input.                                                                                                                      |

### Registered routes

Routes are registered in [lib/core/router/router.dart](lib/core/router/router.dart) and route names/constants live in [lib/core/router/routes.dart](lib/core/router/routes.dart).

| Route name    | Path                          | Screen                                                                                           |
| ------------- | ----------------------------- | ------------------------------------------------------------------------------------------------ |
| launch        | `/launch`                     | [AppLaunchRoute](lib/shared/widgets/app_launch_route.dart)                                       |
| signIn        | `/sign-in`                    | [SignInScreen](lib/features/auth/presentation/screens/sign_in_screen.dart)                       |
| onboarding    | `/onboarding`                 | [OnboardingScreen](lib/features/onboarding/presentation/screens/onboarding_screen.dart)          |
| dev           | `/dev`                        | [DevScreen](lib/shared/widgets/dev_screen.dart)                                                  |
| home          | `/home`                       | [HomeScreen](lib/features/home/presentation/screens/home_screen.dart)                            |
| history       | `/history`                    | [HistoryScreen](lib/features/history/presentation/screens/history_screen.dart)                   |
| community     | `/community`                  | [CommunityScreen](lib/features/community/presentation/screens/community_screen.dart)             |
| more          | `/more`                       | [MoreScreen](lib/features/settings/presentation/screens/more_screen.dart)                        |
| dayComplete   | `/home/day-complete`          | [DayCompleteScreen](lib/features/home/presentation/screens/day_complete_screen.dart)             |
| emptyState    | `/home/empty`                 | [EmptyStateScreen](lib/features/home/presentation/screens/empty_state_screen.dart)               |
| dayDetail     | `/history/day-detail/:date`   | [DayDetailScreen](lib/features/history/presentation/screens/day_detail_screen.dart)              |
| userProfile   | `/community/user-profile/:id` | [UserProfileScreen](lib/features/community/presentation/screens/user_profile_screen.dart)        |
| leaderboard   | `/leaderboard`                | [LeaderboardScreen](lib/features/leaderboard/presentation/screens/leaderboard_screen.dart)       |
| notifications | `/notifications`              | [NotificationsScreen](lib/features/notifications/presentation/screens/notifications_screen.dart) |
| profile       | `/profile`                    | [ProfileScreen](lib/features/profile/presentation/screens/profile_screen.dart)                   |
| settings      | `/settings`                   | [SettingsScreen](lib/features/settings/presentation/screens/settings_screen.dart)                |
| quietHours    | `/settings/quiet-hours`       | [QuietHoursScreen](lib/features/settings/presentation/screens/quiet_hours_screen.dart)           |
| reminderTimes | `/settings/reminder-times`    | [ReminderTimesScreen](lib/features/settings/presentation/screens/reminder_times_screen.dart)     |

The router also wraps the main app content in a shell route with [ScaffoldWithBottomNav](lib/shared/widgets/bottom_nav.dart), so Home, History, Community, and More share the bottom navigation structure.

### Incomplete or placeholder behavior

I did not find any literal TODO/FIXME comments in `lib/`. What I did find are several deliberate no-op or placeholder handlers that look unfinished:

| File                                                                                                                                         | Incomplete behavior                                                                            |
| -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [lib/features/friends/presentation/screens/friends_screen.dart](lib/features/friends/presentation/screens/friends_screen.dart)               | The Invite button is wired to Community, but the row action button uses an empty handler.      |
| [lib/features/friends/presentation/screens/friend_profile_screen.dart](lib/features/friends/presentation/screens/friend_profile_screen.dart) | The remove button is empty; this is mock UI only.                                              |
| [lib/features/friends/presentation/screens/group_manage_screen.dart](lib/features/friends/presentation/screens/group_manage_screen.dart)     | Share/refresh/delete/member actions are placeholders.                                          |
| [lib/features/friends/presentation/screens/invite_screen.dart](lib/features/friends/presentation/screens/invite_screen.dart)                 | Share tiles are no-op placeholders and the join flow only shows a snackbar.                    |
| [lib/features/settings/presentation/screens/settings_screen.dart](lib/features/settings/presentation/screens/settings_screen.dart)           | The calendar type row is a stub and Ramadan mode is local-only UI state.                       |
| [lib/features/community/presentation/screens/user_profile_screen.dart](lib/features/community/presentation/screens/user_profile_screen.dart) | Dua sending is implemented, but some profile actions are still mock-driven depending on state. |
| [lib/shared/widgets/dev_screen.dart](lib/shared/widgets/dev_screen.dart)                                                                     | Developer navigation menu, not a production feature.                                           |

## 2. Amal Log Model

The model lives in [lib/models/amal_log_model.dart](lib/models/amal_log_model.dart). There is no `toMap()` method in this class; the Firestore writer is `toFirestoreMap()`, and there is also `toHiveMap()` for offline cache storage.

### Exact class shape

```dart
class AmalLogModel {
  AmalLogModel({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.isAnonymousDisplay,
    required this.hijriDate,
    required this.toggles,
    required this.score,
    required this.submittedAt,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final bool isAnonymousDisplay;
  final String hijriDate;
  final Map<String, dynamic> toggles;
  final int score;
  final DateTime submittedAt;

  String get docId => '${uid}_$hijriDate';

  factory AmalLogModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final toggles = _togglesFromSource(data);
    final submitted = data['submittedAt'];
    return AmalLogModel(
      uid: (data['uid'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?) ?? '',
      isAnonymousDisplay: (data['isAnonymousDisplay'] as bool?) ?? false,
      hijriDate: (data['hijriDate'] as String?) ?? '',
      toggles: toggles,
      score: (data['score'] as num?)?.toInt() ?? 0,
      submittedAt: submitted is Timestamp
          ? submitted.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap(List<AmalField> fields) {
    final out = <String, dynamic>{
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymousDisplay': isAnonymousDisplay,
      'hijriDate': hijriDate,
      'score': score,
      'submittedAt': Timestamp.fromDate(submittedAt.toUtc()),
    };
    for (final field in fields) {
      if (field.type == AmalType.numeric) {
        out[field.id] = getNumericValue(toggles[field.id], field.maxValue);
      } else {
        out[field.id] = toggles[field.id] == true;
      }
    }
    return out;
  }
}
```

### How the document ID is generated

`docId` is `uid + '_' + hijriDate`, so a user submits one log per Hijri day and the document is addressed as `amal_logs/{uid}_{hijriDate}`.

### Firestore collection

The model is read from and written to the top-level `amal_logs` collection via [lib/core/services/firestore_service.dart](lib/core/services/firestore_service.dart).

### Are `fard` and `takbir` stored as int or bool?

In the mock amal definitions, both `fard` and `takbir` are numeric fields with `type: AmalType.numeric`, so they are stored as integers in Firestore, not booleans. The writer normalizes numeric fields with `getNumericValue(...)`, so those values are saved as `0..maxValue` integers.

## 3. Amal Fields Config

There is no production hard-coded `kAmalFields` alias in the app logic. Production startup now also has a bundled fallback list, `kDefaultAmalFields`, in [lib/core/constants/default_amal_fields.dart](lib/core/constants/default_amal_fields.dart). The same 9-field shape is re-exported as `kAmalFields` from [lib/shared/mock/mock_data.dart](lib/shared/mock/mock_data.dart) for mock-only screens.

### Exact 9-field list

```dart
const List<AmalField> kMockAmalFields = [
  AmalField(
    id: 'fard',
    label: {'en': 'Fard Salah', 'bn': 'জামাতে ফরয নামাজ'},
    sublabel: {
      'en': 'All five fard in congregation',
      'bn': 'জামাতে মোট ফরয নামাজ আদায়',
    },
    points: 30,
    maxValue: 5,
    type: AmalType.numeric,
    order: 1,
  ),
  AmalField(
    id: 'takbir',
    label: {'en': 'Takbir-e-Ula', 'bn': 'তাকবীরে উলা'},
    sublabel: {
      'en': 'Fard with takbir-e-ula in congregation',
      'bn': 'তাকবীরে উলার সাথে জামাতে মোট ফরয নামাজ',
    },
    points: 10,
    maxValue: 5,
    type: AmalType.numeric,
    order: 2,
  ),
  AmalField(
    id: 'morning_azkar',
    label: {'en': 'Morning Azkar', 'bn': 'সকালের আযকার'},
    sublabel: {'en': 'Morning azkar completed', 'bn': 'সকালের আযকার সম্পন্ন'},
    points: 10,
    order: 3,
  ),
  AmalField(
    id: 'evening_azkar',
    label: {'en': 'Evening Azkar', 'bn': 'সন্ধ্যার আযকার'},
    sublabel: {'en': 'Evening azkar completed', 'bn': 'সন্ধ্যার আযকার সম্পন্ন'},
    points: 10,
    order: 4,
  ),
  AmalField(
    id: 'quran',
    label: {'en': 'Quran Tilawat', 'bn': 'কুরআন তিলাওয়াত'},
    sublabel: {
      'en': 'At least one ruku of recitation',
      'bn': 'কমপক্ষে এক রুকু তিলাওয়াত',
    },
    points: 10,
    order: 5,
  ),
  AmalField(
    id: 'mulk',
    label: {'en': 'Surah Mulk', 'bn': 'সূরা মূলক'},
    sublabel: {
      'en': 'Surah Mulk before sleep',
      'bn': 'রাতে ঘুমের আগে সূরা মূলক তিলাওয়াত',
    },
    points: 10,
    order: 6,
  ),
  AmalField(
    id: 'miswak',
    label: {'en': 'Miswak', 'bn': 'মিসওয়াক'},
    sublabel: {
      'en': 'Miswak with wudu (at least once daily)',
      'bn': 'ওজুতে মিসওয়াক (কমপক্ষে দিনে একবার)',
    },
    points: 5,
    order: 7,
  ),
  AmalField(
    id: 'sunnah',
    label: {'en': 'Sunnah + Witr', 'bn': 'সুন্নাহ + বিতির'},
    sublabel: {
      'en': '12 rakah sunnah + witr besides fard',
      'bn': 'ফরয নামাজ ব্যতীত ১২ রাকাত সুন্নাহ + বিতির',
    },
    points: 10,
    order: 8,
  ),
  AmalField(
    id: 'post_azkar',
    label: {'en': 'Post-prayer Azkar', 'bn': 'নামাজ পরবর্তী আযকার'},
    sublabel: {
      'en': 'Azkar after fard prayers',
      'bn': 'ফরয নামাজ পরবর্তী আযকার সম্পন্ন',
    },
    points: 5,
    order: 9,
  ),
];
```

`kAmalFields` is just an alias for that list in [lib/shared/mock/mock_data.dart](lib/shared/mock/mock_data.dart).

### AmalType usage

Yes, `AmalType` is used. Its values are:

```dart
enum AmalType { boolean, numeric }
```

The mock amal list uses `numeric` for `fard` and `takbir`, and `boolean` for the other seven fields.

### `kMaxDailyScore`

`kMaxDailyScore` is set to `100` in [lib/shared/mock/mock_data.dart](lib/shared/mock/mock_data.dart). The production scoring code also uses `kDefaultMaxDailyScore = 100` as a clamp.

### `calculateScore()` implementation

```dart
int calculateScore(Map<String, dynamic> log, List<AmalField> fields) {
  final active = resolveAmalFields(fields);
  var score = 0;
  for (final field in active) {
    if (field.type == AmalType.boolean) {
      if (log[field.id] == true) {
        score += field.points;
      }
    } else {
      final maxValue = field.maxValue <= 0 ? 1 : field.maxValue;
      final val = getNumericValue(log[field.id], maxValue);
      score += ((val / maxValue) * field.points).round();
    }
  }
  return score.clamp(0, kDefaultMaxDailyScore);
}
```

It sums active fields only, adds full points for checked booleans, scales numeric values proportionally, and clamps to `100`.

## 4. Firestore Collections

The app reads/writes these Firestore collections from the code under `lib/`:

| Collection/path             | Direction  | Document fields observed in code                                                                                                                                                                                                                              |
| --------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `users`                     | Read/write | `name`, `email`, `photoUrl`, `createdAt`, `currentStreak`, `bestStreak`, `streakFreezeUsed`, `streakFreezeWeekKey`, `lastLogDate`, `isAnonymousDisplay`, `showOnLeaderboard`, `badges`, `seenBadgeCelebrations`, and `fcmToken` written by notification sync. |
| `amal_logs`                 | Read/write | `uid`, `displayName`, `photoUrl`, `isAnonymousDisplay`, `hijriDate`, `score`, `submittedAt`, plus one field per amal ID. The writer stores flat field IDs, not a nested `toggles` map.                                                                        |
| `activity_feed`             | Read/write | `type`, `message`, `createdAt`, `actorUid`, `targetUid`. One helper method also writes a `uid` field, which looks inconsistent with the model.                                                                                                                |
| `notifications/{uid}/items` | Read/write | `type`, `message`, `isRead`, `createdAt`, `senderUid`, `senderName`, `hijriDate`.                                                                                                                                                                             |
| `amal_fields`               | Read/write | `id`, `label`, `sublabel`, `points`, `maxValue`, `type`, `order`, `isActive`.                                                                                                                                                                                 |
| `config/amal_fields_meta`   | Read       | `version` field used for field-list invalidation.                                                                                                                                                                                                             |

### Subcollections

There is one explicit subcollection in the app’s Firestore service: `notifications/{uid}/items`.

There is also an inconsistent subcollection lookup in [lib/core/services/notification_service.dart](lib/core/services/notification_service.dart): the streak-warning scheduler checks `users/{uid}/amalLogs/{hijriDate}`. That path does not match the app’s real log storage, which is the top-level `amal_logs` collection.

### Firestore rules

I did not find a `firestore.rules` file in the repository, so I could not verify any Firestore security rules from source. The repo also does not appear to contain a `functions/` directory.

## 5. History Screen

History is implemented in [lib/features/history/presentation/screens/history_screen.dart](lib/features/history/presentation/screens/history_screen.dart).

### Current behavior

The screen initializes to the current Hijri month/year using `IslamicDateService.currentHijriYearMonth()`, then fetches month logs via `historyMonthProvider`, which calls `FirestoreService.getMonthLogs(uid, year, month)`.

The calendar cells are built from the fetched logs plus local day-state logic:

- past days with logs show their score/state,
- past days without logs are shown as `noData`,
- future days are locked,
- days before account creation are shown as `preAccount`,
- today is highlighted separately.

### Tap behavior

Yes, users can tap past days.

- Tapping a future day does nothing.
- Tapping a pre-account day does nothing.
- Tapping today routes back to Home.
- Tapping any other past day pushes `AppRoutes.dayDetailPath(keyDate)`.

### Day detail editability

The day detail screen is read-only. It shows a read-only badge, renders every amal row with `readOnly: true`, and has no editing controls.

### Data sources

History month data comes from Firestore via `getMonthLogs`. Day detail data comes from `dayDetailLogProvider`, which first tries Firestore `getLog(...)` and then falls back to the Hive cache entry `log_{uid}_{hijriDate}`.

## 6. Providers & State

Provider files under [lib/providers](lib/providers) and what they manage:

| File                                                                                           | State managed                                                                                                                                                                     |
| ---------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [lib/providers/auth_provider.dart](lib/providers/auth_provider.dart)                           | `authServiceProvider`, `firestoreServiceProvider`, `authStateProvider`, and `currentUserProvider`. These cover auth session state and the current Firestore user document stream. |
| [lib/providers/amal_fields_provider.dart](lib/providers/amal_fields_provider.dart)             | Cached Firestore amal field list, Hive field cache, bundled fallback fields, meta-version refresh, TTL handling, and startup preloading.                                          |
| [lib/providers/amal_provider.dart](lib/providers/amal_provider.dart)                           | Daily amal form state, toggles, submission state, draft caching, Hive/Firebase sync, and streak-freeze flow.                                                                      |
| [lib/providers/history_provider.dart](lib/providers/history_provider.dart)                     | Monthly history fetches and day-detail lookup with Hive fallback.                                                                                                                 |
| [lib/providers/community_provider.dart](lib/providers/community_provider.dart)                 | Community sheet state: selected date, search query, rows, pagination cursor, and live today stream. It also exposes the activity feed stream.                                     |
| [lib/providers/leaderboard_provider.dart](lib/providers/leaderboard_provider.dart)             | Daily, weekly, and streak leaderboard entry lists.                                                                                                                                |
| [lib/providers/notification_provider.dart](lib/providers/notification_provider.dart)           | Notification service preferences, notification stream, unread count, and local preference state.                                                                                  |
| [lib/providers/badge_celebration_provider.dart](lib/providers/badge_celebration_provider.dart) | Badge unlock queue and celebration animation state.                                                                                                                               |
| [lib/providers/locale_provider.dart](lib/providers/locale_provider.dart)                       | Current UI locale persisted in Hive preferences.                                                                                                                                  |

### Amal submission flow end-to-end

The exact flow is:

1. Home screen edits go into `AmalNotifier` state through `toggle`, `setNumeric`, `markAllDone`, or `clearAll`.
2. Draft changes are written locally to Hive under `draft_{uid}_{hijriDate}`.
3. When the user taps save, `HomeScreen._onSubmit(...)` calls `AmalNotifier.submit(user)`.
4. `submit(...)` normalizes toggles, computes score with `calculateScore(...)`, and constructs a new `AmalLogModel`.
5. The current streak state is computed client-side with `computeStreakResult(...)` from `lib/core/utils/streak_helper.dart`.
6. The log is written to Firestore with `FirestoreService.saveAmalLog(...)`.
7. Streak fields are updated with `FirestoreService.updateStreak(...)` and `lastLogDate` is updated to the Hijri date string.
8. Badge/feed sync helpers run afterward, and the submitted log is cached in Hive under `log_{uid}_{hijriDate}`.
9. On success the app navigates to Day Complete, passing the log in `state.extra`.
10. If the streak result is `showFreeze`, Home shows the freeze modal and lets the user either use the freeze or reset the streak before navigating forward.

### Amal-fields startup path

The amal-fields provider now starts in this order:

1. Try Hive field cache from `app_cache`.
2. If that exists, use it immediately and refresh in the background.
3. Otherwise try Firestore cache/server reads.
4. If Firestore is unavailable or returns empty, fall back to `kDefaultAmalFields`.

When fresh Firestore fields are loaded, they are written back to Hive under the amal-fields cache key so the app can start offline later.

### Community provider streaming

Yes, there is a community provider. `communitySheetProvider` manages the daily community sheet and streams the current day through `FirestoreService.communityDayStream(...)`. The separate `activityFeedProvider` streams the `activity_feed` collection.

## 7. Streak Logic

Streak calculation is client-side in [lib/core/utils/streak_helper.dart](lib/core/utils/streak_helper.dart). The server only receives the updated fields through `FirestoreService.updateStreak(...)`.

### Fields used on the user document

The streak flow reads and writes these user fields:

- `currentStreak`
- `bestStreak`
- `streakFreezeUsed`
- `streakFreezeWeekKey`
- `lastLogDate`

### How `lastLogDate` is stored

`lastLogDate` is stored as a Hijri storage string in `YYYY-MM-DD` format, not a Gregorian date.

### Submit flow details

`computeStreakResult(...)` first handles the empty-history case, then converts both the previous and current Hijri storage strings into Gregorian dates through the Hijri calendar bridge. It increments streak when the dates are consecutive, shows the freeze modal when the gap is exactly two days and the freeze is still available, and otherwise resets to `1`.

`HomeScreen._onSubmit(...)` then applies one of two paths:

- `increment` or `reset`: save log, update streak fields, and navigate to Day Complete.
- `showFreeze`: show the streak freeze modal, then either apply freeze or reset streak before navigating to Day Complete.

### Maghrib vs midnight

The app uses a Maghrib-based day change, not midnight.

### Client or Cloud Function

Streak is calculated client-side. I did not find a Cloud Functions directory, and there is no Cloud Function implementation in the repo to do the streak math server-side.

## 8. Islamic Date Service

`IslamicDateService` is implemented in [lib/core/services/islamic_date_service.dart](lib/core/services/islamic_date_service.dart).

### Prayer-time package

The app uses `adhan_dart`, not `adhan`.

### Day-change model

It uses a Maghrib boundary. The current Bangladesh-local time is compared with the day’s Maghrib time, and after Maghrib the service advances the Gregorian base date before converting to Hijri.

### Exact `getCurrentIslamicDateString()` logic

```dart
static String getCurrentIslamicDateString() {
  final now = nowInBD();
  final maghrib = getMaghribTimeSafe();
  return islamicDateStringForBangladeshMoment(
    now,
    maghribAtBdMoment: maghrib,
  );
}
```

This delegates to `islamicDateStringForBangladeshMoment(...)`, which compares the current Bangladesh-local moment to Maghrib and then converts the resulting Gregorian date to Hijri. The conversion also applies the global `hijriDayAdjustment = -1` from [lib/core/constants/app_constants.dart](lib/core/constants/app_constants.dart).

## 9. Hive / Offline

### Open Hive boxes

[lib/core/services/local_storage_service.dart](lib/core/services/local_storage_service.dart) opens three Hive boxes:

- `amal_logs`
- `prefs`
- `app_cache`

### What is cached

- `amal_logs`: submitted log payloads and draft data, stored as Hive maps.
- `prefs`: app preferences such as locale, notification toggles, and reminder times.
- `app_cache`: generic string cache entries plus the serialized amal-fields cache (`amal_fields_data`).

### Offline sync behavior

The offline story is partial rather than a full queue system.

- On load, `AmalFieldsNotifier` tries Hive field cache first, then Firestore, then bundled defaults if needed.
- On load, `AmalNotifier` tries Firestore first for today’s log.
- If Firestore fails or is offline, it falls back to the Hive submitted-log cache.
- If a cached submitted log is found, the notifier restores state and then schedules `_trySyncSubmittedLog(...)` on a microtask to push the log back to Firestore.
- Drafts are stored locally, reloaded on startup, and re-serialized after edits, but they are not automatically uploaded when connectivity returns.
- The amal-fields list itself is cached locally in Hive and refreshed in the background when version metadata changes.
- On app resume, the app explicitly refreshes badges, notification scheduling, and amal-fields freshness, but it does not run a generic sync queue for drafts.

So the answer is: submitted logs do sync opportunistically after reconnect, but drafts do not have a dedicated online reconciliation path.

## 10. Anything Extra

### Additional features / widgets not part of the main plan

I found several extra pieces that are clearly beyond the core daily-log flow:

- [lib/shared/widgets/dev_screen.dart](lib/shared/widgets/dev_screen.dart) is a developer jump menu exposing routes like S-00 through S-17.
- [lib/shared/widgets/app_launch_route.dart](lib/shared/widgets/app_launch_route.dart) and [lib/shared/widgets/app_launch_screen.dart](lib/shared/widgets/app_launch_screen.dart) implement a branded launch handoff before the router picks the first real screen.
- [lib/features/badges/presentation/widgets/badge_celebration_overlay.dart](lib/features/badges/presentation/widgets/badge_celebration_overlay.dart) renders badge-unlock celebrations with animation and queueing.
- [lib/features/friends/presentation/screens/\*](lib/features/friends/presentation/screens) contains mock friend/group UX that is not backed by real Firestore collections yet.
- [lib/core/services/hadith_asset_service.dart](lib/core/services/hadith_asset_service.dart) loads and caches hadith text from assets for the launch/home/day-complete experience.

### Cloud Functions

There is no `functions/` directory in the repository, so I did not find any Cloud Functions.

### Notable TODO/FIXME/incomplete code

I did not find TODO/FIXME comments in `lib/`, but there are several no-op handlers and placeholder paths, especially in the mock friends/settings surfaces and the developer menu.

### Packages that seem unused or unexpected

I did not find a clearly unused runtime package in `pubspec.yaml` from the code paths I inspected.

Notable observations:

- `google_fonts` is used in the theme files, so it is not unused.
- `riverpod` is used alongside `flutter_riverpod` because some files import `riverpod/legacy.dart`.
- `flutter_launcher_icons` and `flutter_native_splash` are build-time tooling dependencies, which is expected.
- `adhan_dart` is the prayer-time package actually used by the Islamic date service.

### One implementation inconsistency worth noting

`NotificationService._scheduleStreakWarning()` queries `users/{uid}/amalLogs/{hijriDate}`, while the rest of the app writes daily logs to `amal_logs/{uid}_{hijriDate}`. That mismatch means the streak warning logic is checking a path the current app does not use for logs.
