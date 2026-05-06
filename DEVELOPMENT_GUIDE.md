# 📱 Amol Tracker — Flutter Development Guide

> v2.0 — Public Community Model. Private groups removed.
> Step-by-step build plan. Follow phases in order. Do not skip ahead.

---

## 🧱 Project Setup

### 1. Create Flutter project

```bash
flutter create amol_tracker --org com.yourname --platforms android,ios
cd amol_tracker
```

### 2. Folder structure

```
lib/
├── main.dart
├── app.dart                         # MaterialApp, theme, routing
├── core/
│   ├── theme/
│   │   ├── colors.dart              # Brand color constants
│   │   ├── text_styles.dart         # Typography system
│   │   └── theme.dart               # ThemeData
│   ├── constants/
│   │   ├── amal_fields.dart         # 9 amal definitions + point values
│   │   └── routes.dart              # Route name constants
│   ├── utils/
│   │   ├── hijri_helper.dart        # Hijri date conversion utils
│   │   ├── score_calculator.dart
│   │   └── streak_helper.dart
│   └── services/
│       ├── auth_service.dart
│       ├── firestore_service.dart
│       ├── notification_service.dart
│       └── local_storage_service.dart
├── models/
│   ├── user_model.dart
│   ├── amal_log_model.dart
│   └── badge_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── amal_provider.dart
│   ├── community_provider.dart      # All-users real-time stream
│   ├── streak_provider.dart
│   └── notification_provider.dart
├── screens/
│   ├── auth/
│   │   ├── sign_in_screen.dart          # S-00
│   │   ├── onboarding_one_screen.dart   # S-01a
│   │   ├── onboarding_two_screen.dart   # S-01b
│   │   └── onboarding_three_screen.dart # S-01c (display name + privacy)
│   ├── home/
│   │   ├── home_screen.dart             # S-02
│   │   └── day_complete_screen.dart     # S-10
│   ├── history/
│   │   ├── history_screen.dart          # S-04
│   │   └── day_detail_screen.dart       # S-13
│   ├── leaderboard/
│   │   └── leaderboard_screen.dart      # S-03
│   ├── community/
│   │   ├── community_screen.dart        # S-05 (tabs: Sheet + Feed)
│   │   └── user_profile_screen.dart     # S-12 (public, no friendship)
│   ├── more/
│   │   └── more_screen.dart             # More menu (links to S-03,07,08,09)
│   ├── notifications/
│   │   └── notifications_screen.dart    # S-07
│   ├── profile/
│   │   └── profile_screen.dart          # S-08
│   └── settings/
│       ├── settings_screen.dart         # S-09
│       └── quiet_hours_screen.dart      # S-17
├── widgets/
│   ├── common/
│   │   ├── app_bottom_nav.dart
│   │   ├── amal_toggle_row.dart
│   │   ├── streak_banner.dart
│   │   ├── score_ring.dart
│   │   ├── community_row_card.dart      # One row in community sheet
│   │   ├── activity_feed_item.dart      # One item in activity feed
│   │   └── geo_background.dart          # Islamic geometric SVG bg
│   └── modals/
│       └── streak_freeze_modal.dart     # S-16
└── firebase_options.dart
```

---

## 🔥 Phase 1 — Foundation (Week 1–2)

### Step 1: Firebase setup

1. Create Firebase project at console.firebase.google.com
2. Enable: Authentication, Firestore, Cloud Messaging, Remote Config
3. Run `flutterfire configure` to generate `firebase_options.dart`
4. Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

### Step 2: Theme & colors

```dart
// core/theme/colors.dart
class AppColors {
  static const emeraldDeep   = Color(0xFF0D3D2E);
  static const emeraldMid    = Color(0xFF1A5C42);
  static const emeraldLight  = Color(0xFF256B4E);
  static const gold          = Color(0xFFC9A84C);
  static const goldLight     = Color(0xFFE8C96A);
  static const goldPale      = Color(0xFFF5DFA0);
  static const cream         = Color(0xFFFAF6EE);
  static const success       = Color(0xFF2ECC71);
  static const danger        = Color(0xFFE74C3C);
  static const warning       = Color(0xFFE67E22);
  static const cardDark      = Color(0x0FFFFFFF);
  static const goldBorder    = Color(0x40C9A84C);
}
```

### Step 3: Amal field constants

```dart
// core/constants/amal_fields.dart
class AmalField {
  final String id;
  final String label;
  final String sublabel;
  final int points;
  final bool isNumeric;
  const AmalField({required this.id, required this.label,
    required this.sublabel, required this.points, this.isNumeric = false});
}

const List<AmalField> kAmalFields = [
  AmalField(id: 'fard',          label: 'Fard prayers',      sublabel: 'All 5 in congregation', points: 20, isNumeric: true),
  AmalField(id: 'takbir',        label: 'Takbir-e-Ula',      sublabel: 'With congregation',      points: 5,  isNumeric: true),
  AmalField(id: 'morning_azkar', label: 'Morning Azkar',      sublabel: 'After Fajr',             points: 8),
  AmalField(id: 'evening_azkar', label: 'Evening Azkar',      sublabel: 'After Asr',              points: 8),
  AmalField(id: 'quran',         label: 'Quran Tilawat',      sublabel: 'Any amount',             points: 10),
  AmalField(id: 'mulk',          label: 'Surah Mulk',         sublabel: 'Full recitation',        points: 10),
  AmalField(id: 'miswak',        label: 'Miswak',             sublabel: 'Before prayer',          points: 5),
  AmalField(id: 'sunnah',        label: 'Sunnah + Witr',      sublabel: 'All sunnah prayers',     points: 10),
  AmalField(id: 'post_azkar',    label: 'Post-prayer Azkar',  sublabel: 'After each fard',        points: 10),
];

const int kMaxDailyScore = 100;

int calculateScore(Map<String, dynamic> log) {
  int score = 0;
  for (final field in kAmalFields) {
    if (log[field.id] == true) score += field.points;
  }
  return score.clamp(0, kMaxDailyScore);
}
```

---

## 🔐 Phase 2 — Authentication (Week 2)

**Screens:** S-00 (Sign In), S-01a, S-01b, S-01c (Onboarding)

### Build order:

1. `sign_in_screen.dart` — Google Sign-In + anonymous fallback
2. On first login → check Firestore if user doc exists
3. New user → `onboarding_one_screen.dart`
4. Returning user → `home_screen.dart`
5. Build 3 onboarding slides with `PageView`
6. **Slide 3 (S-01c)** — user sets:
   - Display name (TextField, pre-filled from Google account)
   - Privacy toggle: "Show as Anonymous in community sheet"
   - Notification permission request
7. On slide 3 completion → create user doc → route to Home

### Firestore user document:

```
users/{uid}
  name: string
  email: string
  photoUrl: string
  createdAt: timestamp
  currentStreak: int
  bestStreak: int
  streakFreezeUsed: bool
  lastLogDate: string         # YYYY-MM-DD Hijri
  isAnonymousDisplay: bool    # shows as "Anonymous 🕌" in community sheet
  badges: [string]            # list of unlocked badge IDs
```

> No groupId. Every user is automatically part of the global community.

---

## 📋 Phase 3 — Daily Logging (Week 3)

**Screens:** S-02 (Home), S-10 (Day Complete)

### Build order:

1. `home_screen.dart`
   - Fetch today's log from Firestore (or Hive if offline)
   - Render `AmalToggleRow` for each of 9 fields
   - Live score + progress bar updates on every tap
   - Streak banner at top (tap → S-04 History)
   - CTA: **"Mark all done"** → all 9 ON
   - CTA changes to: **"Submit today's log"** → saves → navigates to S-10
   - After submit: locked "Logged today ✓" state

2. `day_complete_screen.dart`
   - Animated score ring
   - Random hadith from `assets/hadiths/hadiths.json`
   - Full amal summary (done ✓ / missed ✗ per field with points)
   - "Back to home" → pop to Home (locked state)
   - Trigger streak update + badge check via Cloud Function

### Score logic:

```dart
int calculateScore(Map<String, dynamic> log) {
  int score = 0;
  if (log['fard'] == true)          score += 20;
  if (log['takbir'] == true)        score += 5;
  if (log['morning_azkar'] == true) score += 8;
  if (log['evening_azkar'] == true) score += 8;
  if (log['quran'] == true)         score += 10;
  if (log['mulk'] == true)          score += 10;
  if (log['miswak'] == true)        score += 5;
  if (log['sunnah'] == true)        score += 10;
  if (log['post_azkar'] == true)    score += 10;
  return score.clamp(0, 100);
}
```

### Offline support:

```dart
// Enable Firestore offline cache
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
// Also cache in Hive on every toggle
final box = Hive.box('amal_logs');
await box.put('log_${todayHijri}', logData);
```

---

## 🔥 Phase 4 — Streak & History (Week 4)

**Screens:** S-04 (History), S-13 (Day Detail), S-16 (Freeze Modal)

### Build order:

1. `streak_helper.dart`
   - On submit: compare `lastLogDate` to today's Hijri date
   - Consecutive → increment `currentStreak`
   - Gap = 1 day + freeze available → show S-16 modal
   - Gap > 1 day → reset streak to 1
   - Update `bestStreak` if `currentStreak > bestStreak`

2. `history_screen.dart`
   - Hijri calendar grid using `hijri` package
   - Fetch monthly logs from Firestore (only current user's logs)
   - Green ≥ 80, amber 50–79, red < 50 or no log
   - Tap day → `day_detail_screen.dart`
   - Monthly consistency % + avg score + weakest amal insight

3. `day_detail_screen.dart` — read-only, locked banner

4. `streak_freeze_modal.dart`
   - Bottom sheet: shows freeze count (1/week), streak that would be preserved
   - "Yes, use freeze" → `streakFreezeUsed = true`, streak preserved
   - "No, reset" → `currentStreak = 1`

---

## 🌐 Phase 5 — Community Screen (Week 5–6)

**Screen:** S-05 (Community Screen — two tabs: Sheet + Feed)

### Why two tabs inside one screen:

The old Activity Feed (Islamic quotes, streak milestones, "X completed today") was in v1.0 Friends screen. It still belongs in the social tab — so Community screen has:

- **Tab 1: Sheet** — the public Google-Sheet-style grid
- **Tab 2: Feed** — activity feed (milestones, quotes, completions)

### Firestore data model:

```
amal_logs/{uid}_{hijriDate}
  uid: string
  displayName: string         # denormalized for fast reads
  photoUrl: string            # denormalized
  isAnonymousDisplay: bool
  hijriDate: string           # YYYY-MM-DD Hijri
  score: int
  fard: bool
  takbir: bool
  morning_azkar: bool
  evening_azkar: bool
  quran: bool
  mulk: bool
  miswak: bool
  sunnah: bool
  post_azkar: bool
  submittedAt: timestamp
```

### Tab 1 — Community Sheet:

```dart
// community_provider.dart — real-time stream of today's logs
final communitySheetProvider = StreamProvider<List<AmalLogModel>>((ref) {
  final today = HijriHelper.todayString();
  return FirebaseFirestore.instance
      .collection('amal_logs')
      .where('hijriDate', isEqualTo: today)
      .orderBy('score', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(AmalLogModel.fromDoc).toList());
});
```

**Grid layout:**

- Sticky column header row: Name | Fard | Takbir | M.Az | E.Az | Quran | Mulk | Miswak | Sunnah | P.Az | Score
- Current user's row pinned at index 0, gold background
- Other users below, sorted by score desc
- Cell states: ✅ done (green), ❌ missed (red), ⏳ pending (grey, today only)
- Pagination: 20 rows, infinite scroll loads next 20
- Date tabs at top: today → past days (Hijri), past day rows all final (no ⏳)
- Search bar: client-side filter on loaded displayName
- Tap row → `user_profile_screen.dart`
- Anonymous users: tap → minimal profile (no real name/avatar shown)

### Tab 2 — Activity Feed:

- Real-time Firestore listener on `activity_feed` collection
- Feed items:
  - "Ishtiyak completed all amal today 🌟"
  - "Shakil is on a 14-day streak 🔥"
  - "21 community members have logged today"
  - Islamic quote of the day (from hadiths.json, rotated daily)
  - Hadith shown to user on their own completion
- Feed items created by Cloud Function `onLogSubmit.js`
- Dua received item: "A community member sent you a dua 🤲"

### `user_profile_screen.dart` (S-12):

- Avatar (or 🕌 placeholder if anonymous), name, streak badge
- Stats grid: today's score, best streak, avg score
- Today's amal grid (9 columns, read-only)
- Weekly bar chart (last 7 days)
- **"Send Dua 🤲"** button
  - Writes to `notifications/{recipientUid}/items/{id}`
  - Rate limit: check if sender already sent dua to this user today → block if yes
  - Confirmation: "Dua sent ✓"
- Viewing own profile: edit display name + anonymous toggle

---

## 🔔 Phase 6 — Notifications (Week 6)

**Screens:** S-07 (Notifications), S-09 (Settings), S-17 (Quiet Hours)

### Build order:

1. Request notification permission on Onboarding S-01c
2. Local notifications via `flutter_local_notifications`:
   - 6:00 AM — Morning notification
   - 6:30 PM — Evening notification
   - 10:00 PM — Streak warning (if no log today)
   - Every Friday morning — Jumu'ah motivation
3. FCM push notifications (via Cloud Functions):
   - "X community members already completed today 👀"
   - "You're 2nd on the leaderboard 🏆"
   - Dua received notification
4. Quiet hours: save to SharedPreferences, reschedule all notifications
5. `notifications_screen.dart` — Firestore listener on user's notification docs
6. `quiet_hours_screen.dart` — +/- time picker, save, reschedule

### Notification Firestore model:

```
notifications/{uid}/items/{id}
  type: string       # 'dua' | 'streak' | 'community' | 'badge'
  message: string
  isRead: bool
  createdAt: timestamp
  senderUid: string | null   # null for system notifications
```

---

## 🏆 Phase 7 — Leaderboard, Profile & More (Week 7)

**Screens:** S-03 (Leaderboard), S-08 (Profile), More menu

### Build order:

1. `leaderboard_screen.dart`
   - Query all `amal_logs` for today / this week, sort by score or streak
   - Podium widget top 3, always show current user rank
   - Anonymous users show anonymised
   - Smart nudge: "X pts behind 2nd place"
   - Tap user row → `user_profile_screen.dart`

2. `more_screen.dart` — simple list screen, accessible from More tab:
   - Leaderboard → S-03
   - Notifications → S-07
   - My Profile → S-08
   - Settings → S-09

3. Badge system:

```dart
enum BadgeType {
  threeDays, sevenDays, fourteenDays, thirtyDays,
  sixtyDays, hundredDays, topOfCommunity, perfectWeek
}
```

- Check on every streak update via Cloud Function
- `topOfCommunity` = ranked #1 on global weekly leaderboard
- `perfectWeek` = 7 consecutive days score ≥ 80

4. `profile_screen.dart`
   - Stats grid, weekly bar chart (fl_chart), badge grid
   - Edit display name (inline TextField)
   - Anonymous toggle (updates Firestore + community sheet display immediately)

---

## ⚙️ Phase 8 — Polish & Edge Cases (Week 8–9)

### Empty states

- New user: Home shows welcome + "Log today's amal" CTA
- Community sheet: current user row shows ⏳ with "Log today to appear here"
- Empty leaderboard: "Be the first to log today!"
- Empty notifications: "No notifications yet"

### Midnight lock

- Check today's Hijri date on every app launch
- If log submitted → read-only home, "Logged ✓"
- No editing after submission

### Community sheet performance

- Use `ListView.builder` not `Column` for rows
- Freeze column header using `SliverPersistentHeader` or `Stack`
- Horizontal scroll via `SingleChildScrollView` wrapping fixed-width row
- Limit real-time listener to today's date only — past dates use one-time `get()`
- Use `RepaintBoundary` on each row to prevent full-grid rebuilds

### Error handling

- No internet → offline banner, Hive cache
- Firestore write fail → retry, show snackbar error
- Auth token expired → silent re-auth

### Cloud Functions:

```
functions/
├── onLogSubmit.js       # Streak update, badge check, activity feed item, smart FCM
├── onDuaSent.js         # Create notification doc for recipient
└── weeklyReset.js       # Reset streakFreezeUsed every Monday 00:00
```

---

## 🚀 Phase 9 — Release (Week 9–10)

1. Bundle ID / package name
2. App icon with `flutter_launcher_icons`
3. Splash screen with `flutter_native_splash`
4. ProGuard for Android release
5. Test on Android 10, 12, 14 + iOS 16, 17
6. Play Store internal track → TestFlight

---

## 🗑️ Removed vs v1.0

| Removed                                 | Reason                   |
| --------------------------------------- | ------------------------ |
| `group_model.dart`                      | No groups                |
| `group_provider.dart`                   | No groups                |
| `invite_screen.dart` (S-06)             | No invite codes          |
| `group_sheet_screen.dart` (S-11)        | → public community sheet |
| `group_manage_screen.dart` (S-14)       | No group admin           |
| `onMemberJoin.js`                       | No join event            |
| `groups/{groupId}` Firestore collection | No groups                |
| Invite code generation logic            | Not needed               |
