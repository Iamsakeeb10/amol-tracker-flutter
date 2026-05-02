# 📱 Amol Tracker — Flutter Development Guide

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
├── app.dart                    # MaterialApp, theme, routing
├── core/
│   ├── theme/
│   │   ├── colors.dart         # Brand color constants
│   │   ├── text_styles.dart    # Typography system
│   │   └── theme.dart          # ThemeData
│   ├── constants/
│   │   ├── amal_fields.dart    # 9 amal definitions + point values
│   │   └── routes.dart         # Route name constants
│   ├── utils/
│   │   ├── hijri_helper.dart   # Hijri date conversion utils
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
│   ├── group_model.dart
│   └── badge_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── amal_provider.dart
│   ├── group_provider.dart
│   ├── streak_provider.dart
│   └── notification_provider.dart
├── screens/
│   ├── auth/
│   │   ├── sign_in_screen.dart          # S-00
│   │   ├── onboarding_one_screen.dart   # S-01a
│   │   ├── onboarding_two_screen.dart   # S-01b
│   │   └── onboarding_three_screen.dart # S-01c
│   ├── home/
│   │   ├── home_screen.dart             # S-02
│   │   └── day_complete_screen.dart     # S-10
│   ├── history/
│   │   ├── history_screen.dart          # S-04
│   │   └── day_detail_screen.dart       # S-13
│   ├── leaderboard/
│   │   └── leaderboard_screen.dart      # S-03
│   ├── friends/
│   │   ├── friends_screen.dart          # S-05
│   │   ├── invite_screen.dart           # S-06
│   │   ├── friend_profile_screen.dart   # S-12
│   │   ├── group_sheet_screen.dart      # S-11
│   │   └── group_manage_screen.dart     # S-14
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
│   │   ├── member_card.dart
│   │   └── geo_background.dart         # Islamic geometric SVG bg
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

Define brand colors in `core/theme/colors.dart`:

```dart
class AppColors {
  static const emeraldDeep   = Color(0xFF0D3D2E);
  static const emeraldMid    = Color(0xFF1A5C42);
  static const gold          = Color(0xFFC9A84C);
  static const goldLight     = Color(0xFFE8C96A);
  static const goldPale      = Color(0xFFF5DFA0);
  static const cream         = Color(0xFFFAF6EE);
  static const success       = Color(0xFF2ECC71);
  static const danger        = Color(0xFFE74C3C);
  static const warning       = Color(0xFFE67E22);
}
```

### Step 3: Amal field constants

Define all 9 amal fields with points in `core/constants/amal_fields.dart`:

```dart
class AmalField {
  final String id;
  final String label;
  final int points;
  final bool isNumeric; // true for Fard (5) and Takbir (count)
  const AmalField({required this.id, required this.label, required this.points, this.isNumeric = false});
}

const List<AmalField> kAmalFields = [
  AmalField(id: 'fard',         label: 'Fard prayers',      points: 20, isNumeric: true),
  AmalField(id: 'takbir',       label: 'Takbir-e-Ula',      points: 5,  isNumeric: true),
  AmalField(id: 'morning_azkar',label: 'Morning Azkar',      points: 8),
  AmalField(id: 'evening_azkar',label: 'Evening Azkar',      points: 8),
  AmalField(id: 'quran',        label: 'Quran Tilawat',      points: 10),
  AmalField(id: 'mulk',         label: 'Surah Mulk',         points: 10),
  AmalField(id: 'miswak',       label: 'Miswak',             points: 5),
  AmalField(id: 'sunnah',       label: 'Sunnah + Witr',      points: 10),
  AmalField(id: 'post_azkar',   label: 'Post-prayer Azkar',  points: 10),
];
// Max score = 86 base + up to 14 for full Fard = 100 total
```

---

## 🔐 Phase 2 — Authentication (Week 2)

**Screens:** S-00 (Sign In), S-01a, S-01b, S-01c (Onboarding)

### Build order:

1. `sign_in_screen.dart` — Google Sign-In button + anonymous fallback
2. On first login → check Firestore if user doc exists
3. If new user → route to `onboarding_one_screen.dart`
4. If returning user → route to `home_screen.dart`
5. Build 3 onboarding slides with `PageView`
6. On last slide → create user doc in Firestore, route to Home

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
  lastLogDate: string (YYYY-MM-DD Hijri)
  groupId: string | null
```

---

## 📋 Phase 3 — Daily Logging (Week 3)

**Screens:** S-02 (Home), S-10 (Day Complete)

### Build order:

1. `home_screen.dart`
   - Fetch today's log from Firestore (or Hive if offline)
   - Render `AmalToggleRow` widgets for each of 9 fields
   - Live score calculation as user taps
   - Progress bar updates in real-time
   - Streak banner at top
   - CTA button: **"Mark all done"** → toggles all ON → shows "Submit today's log"
   - CTA button: **"Submit today's log"** → saves to Firestore → navigates to S-10

2. `day_complete_screen.dart`
   - Animated score ring (use `fl_chart` or custom `CustomPainter`)
   - Hadith card (random from local list of 20 hadiths)
   - Full amal summary (done/missed per field)
   - "Back to home" → pops to Home
   - Trigger streak update Cloud Function

### Score calculation logic:

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

- Use Hive to cache today's log locally on every toggle
- On app launch: check Hive first, sync to Firestore when online
- Firestore offline persistence: `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true)`

---

## 🔥 Phase 4 — Streak & History (Week 4)

**Screens:** S-04 (History), S-13 (Day Detail)

### Build order:

1. Streak logic in `streak_helper.dart`
   - On submit: compare `lastLogDate` to today's Hijri date
   - If consecutive → increment `currentStreak`
   - If gap = 1 day AND `streakFreezeUsed == false` → show S-16 modal
   - If gap > 1 day → reset streak to 1
   - Update `bestStreak` if `currentStreak > bestStreak`

2. `history_screen.dart`
   - Hijri calendar grid using `hijri` package
   - Fetch monthly logs from Firestore
   - Color each day: green ≥80, amber 50–79, red <50 or no log
   - Tap day → navigate to `day_detail_screen.dart`
   - Monthly stats: consistency %, avg score

3. `day_detail_screen.dart`
   - Read-only view of any past day's amal
   - Show score, streak value that day
   - Each field: done (green tick) or missed (red cross)
   - Locked banner at bottom

4. `streak_freeze_modal.dart`
   - Bottom sheet that appears when streak would break
   - Shows freeze count (1 per week)
   - "Yes, use freeze" → preserve streak, mark `streakFreezeUsed = true`
   - "No, reset" → streak resets to 1

---

## 🔔 Phase 5 — Notifications (Week 5)

**Screens:** S-07 (Notifications), S-09/S-17 (Settings/Quiet Hours)

### Build order:

1. Request notification permissions on onboarding slide 3
2. Schedule local notifications with `flutter_local_notifications`:
   - Morning: 6:00 AM — "Start your day with amal"
   - Evening: 6:30 PM — "Don't forget your evening azkar"
   - Night: 10:00 PM — "Submit your amal before midnight"
3. Streak warning: trigger at 10 PM if no log found for today
4. Friday special: every Jumu'ah morning
5. Quiet hours: cancel/reschedule notifications to respect window
6. `notifications_screen.dart`: fetch notification history from Firestore
7. `quiet_hours_screen.dart`: +/- time picker, save to user doc

---

## 👥 Phase 6 — Friends & Social (Week 6–7)

**Screens:** S-05, S-06, S-11, S-12, S-14

### Build order:

1. Group creation: generate 6-char invite code, save to Firestore `groups` collection
2. Join group: query by invite code, add uid to `members[]`
3. `friends_screen.dart`: real-time listener on group members
4. `group_sheet_screen.dart`: scrollable day tabs + member amal grid
5. `invite_screen.dart`: show/copy/share invite code
6. `friend_profile_screen.dart`: other user's stats, weekly chart, send dua
7. `group_manage_screen.dart`: admin only — rename, remove members, delete

### Firestore group document:

```
groups/{groupId}
  name: string
  inviteCode: string (6 chars)
  adminUid: string
  members: [uid1, uid2, ...]
  createdAt: timestamp
  groupStreak: int
```

### Dua feature:

- "Send Dua" creates a Firestore notification document for that user
- The recipient sees it in S-07 as "X sent you a dua"

---

## 🏆 Phase 7 — Leaderboard & Profile (Week 7–8)

**Screens:** S-03 (Leaderboard), S-08 (Profile & Badges)

### Build order:

1. `leaderboard_screen.dart`
   - Query group members' scores for today / this week
   - Sort descending by score or streak (toggle tabs)
   - Podium widget for top 3
   - Always show current user rank even if outside top 3
   - Smart nudge card: "X pts behind 2nd place"

2. Badge system in `badge_model.dart`:

```dart
enum BadgeType { sevenDay, fourteenDay, thirtyDay, hundredDay, topOfGroup, perfectWeek }
```

- Check badge eligibility on every streak update
- Unlock = add to user's `badges[]` array in Firestore

3. `profile_screen.dart`
   - Personal stats grid (streak, best streak, avg score)
   - Weekly bar chart with `fl_chart`
   - Badge grid: unlocked (gold) vs locked (greyed out)

---

## ⚙️ Phase 8 — Polish & Edge Cases (Week 8–9)

### Empty states

- S-15: New user with no logs, no friends
- Empty leaderboard (no group yet)
- Empty notifications list

### Midnight lock

- On app launch: check if today's Hijri date matches last log date
- If log already submitted today → show read-only home with "Logged ✓"
- No editing after submission

### Error handling

- No internet → show offline banner, use Hive cache
- Failed Firestore write → retry with exponential backoff
- Auth token expired → re-authenticate silently

### Cloud Functions (deploy alongside app)

```
functions/
├── onLogSubmit.js      # Update streak, check badges, trigger smart notifications
├── onMemberJoin.js     # Notify group members of new member
└── weeklyReset.js      # Reset weekly streak freeze every Monday
```

---

## 🚀 Phase 9 — Release (Week 9–10)

1. Set bundle ID / package name
2. Add app icons (Islamic star/crescent theme) with `flutter_launcher_icons`
3. Add splash screen with `flutter_native_splash`
4. Enable ProGuard for Android
5. Test on real devices (Android + iOS)
6. Submit to Play Store (Android) → TestFlight (iOS)
