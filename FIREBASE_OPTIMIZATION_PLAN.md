# Codebase Audit — Amol Tracker App

> Generated from `lib/` read-only analysis. No code was changed.

---

## 1. Community Sheet Provider

**File:** `lib/providers/community_provider.dart`

### Snapshot vs Get

The community sheet uses **both** `.snapshots()` and `.get()`:

**Real-time stream (for "today" tab):**

```dart
// community_provider.dart:254
_todaySub = fs.communityDayStream(today).listen(
  (rows) {
    _liveTopRows = rows;
    _rebuildFromLiveAndPaged();
    state = state.copyWith(selectedDate: today, isLoading: false, clearError: true);
  },
  ...
);
```

**One-time fetch (for past dates + pagination):**

```dart
// community_provider.dart:240-241
final firstPage = await fs.communityDayFetch(today);

// community_provider.dart:192-193
final page = await fs.communityDayFetch(
  state.selectedDate,
  startAfter: state.lastDoc,
);
```

### Firestore Queries

**`communityDayStream` (snapshots):**

```dart
// firestore_service.dart:514-523
Stream<List<AmalLogModel>> communityDayStream(String hijriDate) {
  return _amalLogs.where('hijriDate', isEqualTo: hijriDate).snapshots().map((snap) {
    final rows = snap.docs.map(AmalLogModel.fromDoc).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    if (rows.length <= _communityPageSize) return rows;
    return rows.take(_communityPageSize).toList();
  });
}
```

**`communityDayFetch` (get):**

```dart
// firestore_service.dart:534-537
var query = _amalLogs
    .where('hijriDate', isEqualTo: hijriDate)
    .orderBy('score', descending: true)
    .limit(_communityPageSize);
if (startAfter != null) {
  query = query.startAfterDocument(startAfter);
}
final snap = await query.get();
```

### Caching Layer

**No dedicated caching layer.** The provider merges a live snapshot stream (`_liveTopRows`) with paginated fetch results (`_pagedRows`) in memory. Hive is NOT used for community data.

---

## 2. Leaderboard Provider

**File:** `lib/providers/leaderboard_provider.dart`

### Queries & Snapshot/Get

| Leaderboard Type | Provider Type    | Query                                                                           | snapshots() or get()? |
| ---------------- | ---------------- | ------------------------------------------------------------------------------- | --------------------- |
| Daily            | `StreamProvider` | `communityDayStream(today)` → filters by `showOnLeaderboard`                    | **snapshots()**       |
| Weekly           | `FutureProvider` | `weeklyLeaderboard()` → range query on `amal_logs`                              | **get()**             |
| Monthly          | `FutureProvider` | `monthlyLeaderboard()` → range query on `amal_logs`                             | **get()**             |
| Streak           | `FutureProvider` | `streakLeaderboard()` → `_users.orderBy('currentStreak', descending: true)`     | **get()**             |
| Quiz             | `FutureProvider` | `QuizLeaderboardService.fetchLeaderboard()` → `collectionGroup('quizAttempts')` | **get()**             |

### Weekly Leaderboard Query

```dart
// firestore_service.dart:611-614
final query = await _amalLogs
    .where('hijriDate', isGreaterThanOrEqualTo: start)
    .where('hijriDate', isLessThanOrEqualTo: end)
    .get();
```

### Monthly Leaderboard Query

```dart
// firestore_service.dart:675-678
final query = await _amalLogs
    .where('hijriDate', isGreaterThanOrEqualTo: start)
    .where('hijriDate', isLessThanOrEqualTo: end)
    .get();
```

### Streak Leaderboard Query

```dart
// firestore_service.dart:729-731
var query = _users
    .orderBy('currentStreak', descending: true)
    .limit(_leaderboardPageSize);
```

### Refresh Frequency

- **Daily:** Real-time via `stream` — auto-updates.
- **Weekly/Monthly/Streak/Quiz:** `FutureProvider` — fetched once when first read. **No automatic refresh.** Requires manual invalidation or app restart.

---

## 3. AmalLogModel

**File:** `lib/models/amal_log_model.dart`

### Fields

```dart
class AmalLogModel {
  final String uid;
  final String displayName;
  final String photoUrl;
  final bool isAnonymousDisplay;
  final String hijriDate;
  final Map<String, dynamic> toggles;
  final int score;
  final DateTime submittedAt;
  final DateTime? editedAt;
  final int editCount;
  final Map<String, List<int>> prayers;
}
```

### Document ID Format

```dart
String get docId => '${uid}_$hijriDate';
// Example: "abc123_1446-07-15"
```

### Collection Name

```
amal_logs
```

---

## 4. Activity Feed

### Collection Name

```
activity_feed
```

### Provider

```dart
// community_provider.dart:111-114
final activityFeedProvider = StreamProvider.autoDispose<List<ActivityFeedItemModel>>((ref) {
  final fs = ref.read(firestoreServiceProvider);
  return fs.activityFeedStream();
});
```

### Stream Query

```dart
// firestore_service.dart:571-577
Stream<List<ActivityFeedItemModel>> activityFeedStream() {
  return _activityFeed
      .orderBy('createdAt', descending: true)
      .limit(_activityFeedPageSize)  // 25
      .snapshots()
      .map((snap) => snap.docs.map(ActivityFeedItemModel.fromDoc).toList());
}
```

### Write Location

```dart
// firestore_service.dart:868-878
Future<void> addActivityFeedItem({
  required String type,
  required String message,
  String? uid,
}) async {
  await _activityFeed.add(<String, dynamic>{
    'type': type,
    'message': message,
    'uid': uid,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

Also written during `sendDua`:

```dart
// firestore_service.dart:781-787
await _activityFeed.add(<String, dynamic>{
  'type': 'dua',
  'message': message,
  'actorUid': senderUid,
  'targetUid': recipientUid,
  'createdAt': FieldValue.serverTimestamp(),
});
```

And after amal submission:

```dart
// amal_provider.dart:838-849
await fs.addActivityFeedItem(
  type: 'completion',
  message: '$displayName completed today\'s amal.',
  uid: user.uid,
);
```

---

## 5. Notifications

### Collection Path

```
notifications/{uid}/items/{notificationId}
```

### Code

```dart
// firestore_service.dart:40-42
CollectionReference<Map<String, dynamic>> _notificationItems(String uid) {
  return _firestore.collection('notifications').doc(uid).collection('items');
}
```

### Stream

```dart
// firestore_service.dart:843-848
Stream<List<NotificationModel>> notificationStream(String uid) {
  return _notificationItems(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(NotificationModel.fromDoc).toList());
}
```

---

## 6. FirestoreService — Complete Method List

**File:** `lib/core/services/firestore_service.dart`

| Method                                     | Collection(s) Touched                                 | Type            |
| ------------------------------------------ | ----------------------------------------------------- | --------------- |
| `userExists(uid)`                          | `users`                                               | get             |
| `fetchUser(uid)`                           | `users`                                               | get             |
| `createUser(user)`                         | `users`                                               | set             |
| `updateUser(uid, fields)`                  | `users`                                               | update          |
| `deleteUserDoc(uid)`                       | `users`                                               | delete          |
| `markBadgeCelebrationsSeen(uid, badgeIds)` | `users`                                               | update          |
| `updateUserDisplayFields(uid, ...)`        | `users`, `amal_logs`                                  | update          |
| `userStream(uid)`                          | `users`                                               | snapshots       |
| `usersByIds(ids)`                          | `users`                                               | get (batch)     |
| `getTodayLog(uid, hijriDate)`              | `amal_logs`                                           | get             |
| `getLog(uid, hijriDate)`                   | `amal_logs`                                           | get             |
| `getMonthLogs(uid, year, month)`           | `amal_logs`                                           | get             |
| `getLogsInRange(uid, start, end)`          | `amal_logs`                                           | get             |
| `updateStreak(uid, ...)`                   | `users`                                               | update          |
| `saveAmalLog(log, fields)`                 | `amal_logs`                                           | set             |
| `editAmalLog(updatedLog, fields)`          | `amal_logs`                                           | update          |
| `updateUserLastLogDate(uid, hijriDate)`    | `users`                                               | update          |
| `communityDayStream(hijriDate)`            | `amal_logs`                                           | snapshots       |
| `communityDayFetch(hijriDate, ...)`        | `amal_logs`                                           | get             |
| `activityFeedStream()`                     | `activity_feed`                                       | snapshots       |
| `addActivityFeedItem(...)`                 | `activity_feed`                                       | add             |
| `getRecentLogs(uid, ...)`                  | `amal_logs`                                           | get             |
| `weeklyLeaderboard()`                      | `amal_logs`                                           | get             |
| `monthlyLeaderboard()`                     | `amal_logs`                                           | get             |
| `streakLeaderboard(...)`                   | `users`                                               | get             |
| `hasSentDuaToday(...)`                     | `notifications/{uid}/items`                           | get             |
| `sendDua(...)`                             | `notifications/{uid}/items`, `activity_feed`, `users` | add, get        |
| `notificationStream(uid)`                  | `notifications/{uid}/items`                           | snapshots       |
| `markNotificationRead(uid, id)`            | `notifications/{uid}/items`                           | update          |
| `markAllNotificationsRead(uid)`            | `notifications/{uid}/items`                           | batch update    |
| `searchUsersByQuery(query)`                | `users`                                               | get (2 queries) |
| `announcementsStream()`                    | `announcements`                                       | snapshots       |
| `allAnnouncementsStream()`                 | `announcements`                                       | snapshots       |
| `createAnnouncement(...)`                  | `announcements`                                       | add             |
| `updateAnnouncement(id, data)`             | `announcements`                                       | update          |
| `deleteAnnouncement(id)`                   | `announcements`                                       | delete          |
| `markAnnouncementSeen(uid, id)`            | `users`                                               | update          |
| `appConfigsStream()`                       | `app_config`                                          | snapshots       |
| `activeAppConfigStream()`                  | `app_config`                                          | snapshots       |
| `createAppConfig(...)`                     | `app_config`                                          | add             |
| `updateAppConfig(id, data)`                | `app_config`                                          | update          |
| `deleteAppConfig(id)`                      | `app_config`                                          | delete          |

### All Firestore Collections Used

```
users
amal_logs
activity_feed
notifications/{uid}/items
announcements
app_config
userProgress/{uid}/lessonReviews  (via notification_service.dart)
quizAttempts                      (collectionGroup via quiz_leaderboard_service.dart)
```

---

## 7. Cleanup / Maintenance

### No dedicated cleanup/maintenance service exists.

Grep results:

- `_cleanupStaleRowControllers` — UI-only controller cleanup in `community_screen.dart`
- `cleanup failed` — error logging in `auth_service.dart` sign-out
- SharedPreferences mentioned only in `home_widget_service.dart` comments (the `home_widget` package uses SharedPreferences internally, not the app directly)

### SharedPreferences Usage

**None.** The app uses **Hive** exclusively for local persistence via `LocalStorageService`. The `home_widget` package internally uses SharedPreferences but the app does not import or call `SharedPreferences` directly.

---

## 8. main.dart / App Init

**File:** `lib/main.dart`

### Startup Sequence

```dart
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  tz.initializeTimeZones();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics (release only)
  if (kReleaseMode) { ... }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await LocalStorageService.initialize();  // Hive boxes
  unawaited(HomeWidgetService.quickPreloadWidget());  // Widget cache

  runApp(const ProviderScope(child: _RootApp()));
}
```

### App Lifecycle (app.dart)

```dart
class _AmolTrackerAppState extends ConsumerState<AmolTrackerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _router = buildAppRouter();
    unawaited(_initNotifications());
    unawaited(_setupCustomAnalyticsKeys());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(appBootstrapProvider.future));
      _scheduleSmartReminders();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }
}
```

### Safest Place to Add Background Cleanup

**Option A: After `LocalStorageService.initialize()` in `main()`**

```dart
// Already runs before runApp, no auth needed
await LocalStorageService.initialize();
unawaited(HomeWidgetService.quickPreloadWidget());
unawaited(BackgroundCleanupService.run());  // <-- Add here
```

**Option B: In `_onAppResumed()` in `app.dart` (more frequent, on every resume)**

```dart
Future<void> _onAppResumed() async {
  // ... existing code ...
  unawaited(BackgroundCleanupService.runIfDue());  // <-- Add here
}
```

**Recommended:** Option B (resume-triggered) — avoids blocking startup and runs naturally on user interaction.

---

## 9. Hive Boxes

**File:** `lib/core/services/local_storage_service.dart`

### Boxes Opened

```dart
static const String amalLogsBox = 'amal_logs';
static const String prefsBox = 'prefs';
static const String cacheBox = 'app_cache';
```

### Keys Stored in Each Box

**`amal_logs` box:**
| Key Pattern | Value Type | Purpose |
|---|---|---|
| `log_{uid}_{hijriDate}` | `Map<String, dynamic>` | Submitted amal log cache |
| `draft_{uid}_{hijriDate}` | `Map<String, dynamic>` | Draft (unsubmitted) amal |
| `selections_{uid}_{hijriDate}` | `Map<String, dynamic>` | Prayer circle positions |
| `dhikr_{hijriDate}` | `List<Map<String, dynamic>>` | Dhikr sessions |

**`prefs` box:**
| Key | Value Type | Purpose |
|---|---|---|
| `notif_morning` | `bool` | Morning notification enabled |
| `notif_morning_hour` | `int` | Morning notification hour |
| `notif_morning_min` | `int` | Morning notification minute |
| `notif_evening` | `bool` | Evening notification enabled |
| `notif_evening_hour` | `int` | Evening notification hour |
| `notif_evening_min` | `int` | Evening notification minute |
| `notif_streak` | `bool` | Streak notification enabled |
| `notif_community` | `bool` | Community notification enabled |
| `notif_study_review` | `bool` | Study review notification enabled |
| `quiet_from_hour` | `int` | Quiet hours start hour |
| `quiet_from_min` | `int` | Quiet hours start minute |
| `quiet_to_hour` | `int` | Quiet hours end hour |
| `quiet_to_min` | `int` | Quiet hours end minute |
| `dhikr_custom_presets` | `List<Map>` | Custom dhikr presets |
| `dhikr_selected_preset_id` | `String` | Selected dhikr preset |
| `husna_learned` | `List<int>` | Learned Asma ul Husna numbers |
| `app_locale` | `String` | App language code |
| `fcm_token_owner_uid` | `String` | Current FCM token owner |
| `notif_last_sent_{category}` | `String` | Last notification message sent per category |
| `widget_cached_streak` | `int` | Widget cached streak |
| `widget_cached_completed` | `int` | Widget cached completed count |
| `widget_cached_total` | `int` | Widget cached total count |
| `widget_cached_date` | `String` | Widget cached Hijri date |

**`app_cache` box:**
| Key | Value Type | Purpose |
|---|---|---|
| `amal_fields_data` | `List<Map<String, dynamic>>` | Cached amal fields from Firestore |
| (other keys via `saveCache`/`getCache`) | `String` | Generic string cache |

---

## 10. Packages (pubspec.yaml dependencies)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  flutter_compass: ^0.8.1
  firebase_core: ^4.7.0
  geolocator: ^14.0.2
  permission_handler: ^12.0.3
  firebase_auth: ^6.4.0
  cloud_firestore: ^6.3.0
  firebase_messaging: ^16.2.0
  google_sign_in: ^7.2.0
  flutter_riverpod: ^3.3.1
  hive_flutter: ^1.1.0
  go_router: ^17.2.2
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4
  adhan_dart: ^1.2.0
  hijri: ^3.0.0
  shimmer: ^3.0.0
  intl: ^0.20.2
  connectivity_plus: ^7.1.1
  collection: ^1.19.1
  flutter_screenutil: ^5.9.3
  riverpod: ^3.2.1
  flutter_timezone: ^5.0.2
  home_widget: ^0.9.1
  device_info_plus: ^11.5.0
  youtube_player_flutter: ^10.0.1
  url_launcher: ^6.3.2
  flutter_markdown: ^0.7.7+1
  share_plus: ^12.0.2
  path_provider: ^2.1.5
  just_audio: ^0.10.5
  audio_session: ^0.2.3
  sqflite: ^2.4.2+1
  audio_service: ^0.18.18
  package_info_plus: ^9.0.1
  firebase_analytics: ^12.4.3
  firebase_crashlytics: ^5.2.4
  font_awesome_flutter: ^11.0.0
  tutorial_coach_mark: ^1.3.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.14.1
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.7
```
