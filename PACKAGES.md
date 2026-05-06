# 📦 Amol Tracker — Flutter Package Reference

> v2.0 — Public Community Model.

---

## pubspec.yaml — Full Dependencies

```yaml
name: amol_tracker
description: Daily Islamic habit tracker with public community accountability
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

  # ─── Firebase ──────────────────────────────────────
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.2.0
  firebase_messaging: ^15.0.0
  firebase_remote_config: ^5.1.0

  # ─── Google Sign-In ────────────────────────────────
  google_sign_in: ^6.2.1

  # ─── State Management ──────────────────────────────
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # ─── Local Storage / Offline ───────────────────────
  hive_flutter: ^1.1.0
  shared_preferences: ^2.3.1

  # ─── Navigation ────────────────────────────────────
  go_router: ^14.2.7

  # ─── Notifications ─────────────────────────────────
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4

  # ─── Islamic / Hijri Calendar ──────────────────────
  hijri: ^2.0.1

  # ─── Charts ────────────────────────────────────────
  fl_chart: ^0.68.0

  # ─── Fonts ─────────────────────────────────────────
  google_fonts: ^6.2.1

  # ─── Animations ────────────────────────────────────
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  lottie: ^3.1.2

  # ─── Images ────────────────────────────────────────
  cached_network_image: ^3.3.1

  # ─── Utilities ─────────────────────────────────────
  intl: ^0.19.0
  share_plus: ^10.0.0
  url_launcher: ^6.3.0
  package_info_plus: ^8.0.2
  connectivity_plus: ^6.0.3
  collection: ^1.18.0
  uuid: ^4.4.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.11
  hive_generator: ^2.0.1
  flutter_launcher_icons: ^0.14.1
  flutter_native_splash: ^2.4.1

# ─── App Icon ────────────────────────────────────────
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/icon.png"
  adaptive_icon_background: "#0D3D2E"
  adaptive_icon_foreground: "assets/images/icon_fg.png"
  min_sdk_android: 21

# ─── Splash Screen ───────────────────────────────────
flutter_native_splash:
  color: "#0D3D2E"
  image: assets/images/splash_logo.png
  color_dark: "#0D3D2E"
  android_12:
    color: "#0D3D2E"
    image: assets/images/splash_logo.png

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/animations/
    - assets/hadiths/
  fonts:
    - family: CormorantGaramond
      fonts:
        - asset: assets/fonts/CormorantGaramond-Regular.ttf
          weight: 400
        - asset: assets/fonts/CormorantGaramond-Medium.ttf
          weight: 500
        - asset: assets/fonts/CormorantGaramond-SemiBold.ttf
          weight: 600
```

---

## Package Breakdown

### 🔥 Firebase

| Package                  | Purpose                                                 |
| ------------------------ | ------------------------------------------------------- |
| `firebase_core`          | Initialize Firebase                                     |
| `firebase_auth`          | Google Sign-In + anonymous auth                         |
| `cloud_firestore`        | All data: logs, users, notifications, activity feed     |
| `firebase_messaging`     | FCM push — community activity, dua, leaderboard alerts  |
| `firebase_remote_config` | Enable/disable amal fields without app update (Phase 3) |

```dart
// main.dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

---

### 🔐 Google Sign-In

```dart
// auth_service.dart
final googleUser = await GoogleSignIn().signIn();
final googleAuth = await googleUser!.authentication;
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
await FirebaseAuth.instance.signInWithCredential(credential);
```

---

### 🧠 Riverpod — State Management

```dart
// community_provider.dart — real-time community sheet stream
@riverpod
Stream<List<AmalLogModel>> communitySheet(CommunitySheetRef ref, String hijriDate) {
  return FirebaseFirestore.instance
      .collection('amal_logs')
      .where('hijriDate', isEqualTo: hijriDate)
      .orderBy('score', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(AmalLogModel.fromDoc).toList());
}

// amal_provider.dart — local toggle state
@riverpod
class AmalLog extends _$AmalLog {
  @override
  Map<String, bool> build() => {};

  void toggle(String fieldId) =>
      state = {...state, fieldId: !(state[fieldId] ?? false)};

  void markAll() =>
      state = {for (final f in kAmalFields) f.id: true};
}
```

---

### 💾 Hive — Offline Storage

```dart
// local_storage_service.dart
final box = Hive.box('amal_logs');

// Save on every toggle
await box.put('log_${todayHijri}', logData);

// Load on app start
final cached = box.get('log_${todayHijri}');
```

---

### 🧭 GoRouter — Navigation (v2.0)

```dart
// core/router/router.dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sign-in',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final onAuth = state.matchedLocation.startsWith('/sign-in') ||
                     state.matchedLocation.startsWith('/onboarding');
      if (user == null && !onAuth) return '/sign-in';
      if (user != null && onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in',    builder: (_, __) => SignInScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => OnboardingScreen()),
      GoRoute(path: '/day-complete', builder: (_, __) => DayCompleteScreen()),
      ShellRoute(
        builder: (_, __, child) => ScaffoldWithBottomNav(child: child),
        routes: [
          GoRoute(path: '/home',    builder: (_, __) => HomeScreen()),
          GoRoute(
            path: '/community',
            builder: (_, __) => CommunityScreen(),
            routes: [
              GoRoute(
                path: 'profile/:uid',
                builder: (_, s) => UserProfileScreen(uid: s.pathParameters['uid']!),
              ),
            ],
          ),
          GoRoute(
            path: '/history',
            builder: (_, __) => HistoryScreen(),
            routes: [
              GoRoute(
                path: ':date',
                builder: (_, s) => DayDetailScreen(date: s.pathParameters['date']!),
              ),
            ],
          ),
          GoRoute(
            path: '/more',
            builder: (_, __) => MoreScreen(),
          ),
          GoRoute(path: '/leaderboard',  builder: (_, __) => LeaderboardScreen()),
          GoRoute(path: '/notifications',builder: (_, __) => NotificationsScreen()),
          GoRoute(path: '/profile',      builder: (_, __) => ProfileScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, __) => SettingsScreen(),
            routes: [
              GoRoute(path: 'quiet-hours', builder: (_, __) => QuietHoursScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
```

> **Note:** `/friends`, `/friends/invite`, `/friends/group-sheet`, `/friends/group-manage` routes are all removed. Replaced by `/community` and `/community/profile/:uid`.

---

### 🔔 Local Notifications

```dart
// notification_service.dart
// Morning reminder at 6:00 AM daily
await flutterLocalNotificationsPlugin.zonedSchedule(
  0,
  'Assalamu Alaikum',
  'Start your day with your morning amal 🌅',
  _nextInstanceOf(hour: 6, minute: 0),
  const NotificationDetails(
    android: AndroidNotificationDetails('daily', 'Daily Reminders',
        importance: Importance.high),
    iOS: DarwinNotificationDetails(),
  ),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
  matchDateTimeComponents: DateTimeComponents.time,
);

// Streak warning at 10:00 PM if not logged
await flutterLocalNotificationsPlugin.zonedSchedule(
  1,
  'Don\'t break your streak 🔥',
  'You haven\'t logged today yet. Submit before midnight!',
  _nextInstanceOf(hour: 22, minute: 0),
  // ... same options
);
```

---

### 🕌 Hijri Calendar

```dart
// core/utils/hijri_helper.dart
import 'package:hijri/hijri_calendar.dart';

class HijriHelper {
  static String todayString() {
    final h = HijriCalendar.now();
    return '${h.hYear}-${h.hMonth.toString().padLeft(2,'0')}-${h.hDay.toString().padLeft(2,'0')}';
  }

  static String formatDisplay(HijriCalendar h) {
    const months = ['Muharram','Safar','Rabi I','Rabi II','Jumada I',
                    'Jumada II','Rajab','Sha\'ban','Ramadan','Shawwal',
                    'Dhul Qadah','Dhul Hijja'];
    return '${h.hDay} ${months[h.hMonth - 1]} ${h.hYear}';
  }

  static bool isConsecutive(String prev, String current) {
    // Parse both and check if current is exactly 1 Hijri day after prev
    // Use HijriCalendar arithmetic
    final p = HijriCalendar()..setHijriDate(
      int.parse(prev.split('-')[0]),
      int.parse(prev.split('-')[1]),
      int.parse(prev.split('-')[2]),
    );
    final c = HijriCalendar.now();
    // Compare Gregorian equivalents for simplicity
    final pGreg = p.hijriToGregorian(p.hYear, p.hMonth, p.hDay);
    final cGreg = DateTime.now();
    return cGreg.difference(DateTime(pGreg.year, pGreg.month, pGreg.day)).inDays == 1;
  }
}
```

---

### 📊 fl_chart — Weekly Bar Chart

```dart
// profile_screen.dart / user_profile_screen.dart
BarChart(
  BarChartData(
    barGroups: weeklyScores.asMap().entries.map((e) =>
      BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(
          toY: e.value.toDouble(),
          color: e.value >= 80
              ? AppColors.gold
              : AppColors.goldLight.withOpacity(.55),
          width: 22,
          borderRadius: BorderRadius.circular(4),
        ),
      ]),
    ).toList(),
    gridData: FlGridData(show: false),
    borderData: FlBorderData(show: false),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) => Text(
            ['S','M','T','W','T','F','S'][val.toInt()],
            style: TextStyle(color: Colors.white30, fontSize: 9),
          ),
        ),
      ),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
  ),
)
```

---

### ✨ flutter_animate — Toggle Animation

```dart
// amal_toggle_row.dart — animate on toggle
Icon(Icons.check_circle, color: AppColors.success)
  .animate(target: isDone ? 1.0 : 0.0)
  .scale(duration: 200.ms, curve: Curves.elasticOut)
  .fadeIn()
```

---

### 🌐 Community Sheet Performance Widgets

```dart
// community_sheet_screen.dart — frozen header + scrollable grid
Widget build(BuildContext context) {
  return Column(children: [
    // Sticky column headers
    _buildColumnHeaders(),
    // Scrollable rows
    Expanded(
      child: ListView.builder(
        itemCount: logs.length + 1, // +1 for own pinned row
        itemBuilder: (_, i) => RepaintBoundary( // prevent cascade rebuilds
          child: CommunityRowCard(log: i == 0 ? ownLog : logs[i - 1]),
        ),
      ),
    ),
  ]);
}
```

---

## Firestore Security Rules (v2.0)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users — read by anyone authenticated, write own only
    match /users/{uid} {
      allow read:  if request.auth != null;
      allow write: if request.auth.uid == uid;
    }

    // Amal logs — read by all authenticated users (public community sheet)
    //             write own log only, no editing after submit
    match /amal_logs/{logId} {
      allow read:   if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.uid
                    && !exists(/databases/$(database)/documents/amal_logs/$(logId));
      allow update: if false;  // No editing after submit
      allow delete: if false;
    }

    // Notifications — read/update own, anyone can create (for dua)
    match /notifications/{uid}/items/{itemId} {
      allow read:   if request.auth.uid == uid;
      allow create: if request.auth != null;  // anyone can send dua
      allow update: if request.auth.uid == uid;  // mark read
      allow delete: if false;
    }

    // Activity feed — read by all authenticated, write by Cloud Functions only
    match /activity_feed/{itemId} {
      allow read:  if request.auth != null;
      allow write: if false;  // Cloud Functions only
    }
  }
}
```

> **Key difference from v1.0:** `amal_logs` is now publicly readable by all authenticated users — this powers the community sheet. In v1.0 it was scoped to group members only.

---

## Cloud Functions Reference

```javascript
// functions/onLogSubmit.js
exports.onLogSubmit = functions.firestore
  .document("amal_logs/{logId}")
  .onCreate(async (snap, context) => {
    const log = snap.data();
    // 1. Update user streak
    await updateStreak(log.uid, log.hijriDate);
    // 2. Check and unlock badges
    await checkBadges(log.uid);
    // 3. Write activity feed item
    await writeActivityFeed(log);
    // 4. Send smart FCM to community members who haven't logged
    await sendCommunityNudge(log);
  });

// functions/onDuaSent.js
exports.onDuaSent = functions.firestore
  .document("notifications/{uid}/items/{itemId}")
  .onCreate(async (snap, context) => {
    const notif = snap.data();
    if (notif.type !== "dua") return;
    // Send FCM push to recipient
    await sendDuaPush(context.params.uid, notif.senderUid);
  });

// functions/weeklyReset.js
exports.weeklyReset = functions.pubsub
  .schedule("every monday 00:00")
  .timeZone("Asia/Dhaka")
  .onRun(async () => {
    // Reset streakFreezeUsed = false for all users
    const users = await admin.firestore().collection("users").get();
    const batch = admin.firestore().batch();
    users.docs.forEach((doc) =>
      batch.update(doc.ref, { streakFreezeUsed: false }),
    );
    await batch.commit();
  });
```
