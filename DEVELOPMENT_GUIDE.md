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
│   └── badge_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── amal_provider.dart
│   ├── community_provider.dart    # Replaces group_provider
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
│   ├── community/
│   │   ├── community_sheet_screen.dart  # S-05 (NEW — replaces friends/group screens)
│   │   └── user_profile_screen.dart     # S-12 (public profile, no friend required)
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
  final bool isNumeric;
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
  isAnonymousDisplay: bool   # if true, show as "Anonymous" in community sheet
```

> **Note:** No `groupId` field — users are part of the global community automatically.

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
   - CTA: **"Mark all done"** → toggles all ON
   - CTA: **"Submit today's log"** → saves to Firestore → navigates to S-10

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
- `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true)`

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
   - "Yes, use my freeze" → preserve streak, `streakFreezeUsed = true`
   - "No, reset" → streak resets to 1

---

## 🌐 Phase 5 — Community Sheet (Week 5–6)

**Screen:** S-05 (Community Sheet — core social tab)

This is the public Google-Sheet-style screen. It replaces the old private group system entirely.

### Firestore data model

```
amal_logs/{uid}_{hijriDate}
  uid: string
  displayName: string        # denormalized for fast grid reads
  photoUrl: string           # denormalized
  isAnonymousDisplay: bool
  hijriDate: string          # YYYY-MM-DD
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

### Build order:

1. `community_sheet_screen.dart`

   **Header row (sticky/frozen):**
   - Date tabs at top — today selected by default, scroll left to view past days
   - Column headers: Name | Fard | Takbir | M.Azkar | E.Azkar | Quran | Mulk | Miswak | Sunnah | P.Azkar | Score

   **Data rows:**
   - Query `amal_logs` for selected date, ordered by `score` descending
   - Each row: avatar + name | ✅/❌/⏳ per column | score badge
   - Current user's row pinned at position 1 and highlighted in gold background
   - ⏳ = user exists but has not submitted for that day
   - ✅ = done (green), ❌ = missed (red)
   - Rows load with pagination (20 at a time, infinite scroll)

   **Search bar:**
   - Filter rows by display name (client-side filter on loaded data)

   **Real-time listener:**
   - Use `snapshots()` stream on `amal_logs` for today's date
   - As users submit, their row transitions from ⏳ to live amal data

   **Tap any row → navigate to `user_profile_screen.dart`**

2. `user_profile_screen.dart` (public, no friendship required)
   - User avatar, name, current streak badge
   - Stats: today's score, best streak, all-time avg score
   - Weekly bar chart (last 7 days)
   - Today's amal grid (same 9 columns, read-only)
   - **"Send Dua 🤲"** button — creates a notification in recipient's feed
   - If viewing own profile → show edit name / privacy toggle

### Widgets:

```dart
// community_row_card.dart
class CommunityRowCard extends StatelessWidget {
  final AmalLogModel log;     // today's log, or null if not submitted
  final bool isCurrentUser;
  final VoidCallback onTap;
  // Renders one row in the sheet
}
```

### Privacy:

- Users with `isAnonymousDisplay == true` show as "Anonymous 🕌" in the sheet
- Their data is still visible — only name/avatar is hidden
- Toggle in Settings screen

---

## 🔔 Phase 6 — Notifications (Week 6)

**Screens:** S-07 (Notifications), S-09/S-17 (Settings/Quiet Hours)

### Build order:

1. Request notification permissions on onboarding slide 3
2. Schedule local notifications with `flutter_local_notifications`:
   - Morning: 6:00 AM — "Start your day with amal"
   - Evening: 6:30 PM — "Don't forget your evening azkar"
   - Night: 10:00 PM — "Submit your amal before midnight"
3. Streak warning: trigger at 10 PM if no log found for today
4. Friday special: every Jumu'ah morning
5. Smart community notifications (FCM):
   - "X community members have already logged today 👀"
   - "You're 2nd on the leaderboard — log now to reach 1st 🏆"
6. Dua notification: when someone sends a dua
7. Quiet hours: cancel/reschedule notifications to respect window
8. `notifications_screen.dart`: fetch notification history from Firestore
9. `quiet_hours_screen.dart`: +/- time picker, save to user doc

---

## 🏆 Phase 7 — Leaderboard & Profile (Week 7)

**Screens:** S-03 (Leaderboard), S-08 (Profile & Badges)

### Build order:

1. `leaderboard_screen.dart`
   - Query all `amal_logs` for today / this week, aggregate by uid
   - Sort descending by score or streak (toggle tabs)
   - Podium widget for top 3
   - Always show current user rank even if outside top 3
   - Smart nudge card: "X pts behind 2nd place"
   - Tap any user row → `user_profile_screen.dart`

2. Badge system in `badge_model.dart`:

```dart
enum BadgeType { sevenDay, fourteenDay, thirtyDay, hundredDay, topOfCommunity, perfectWeek }
```

- Check badge eligibility on every streak update
- `topOfCommunity` = ranked #1 on global weekly leaderboard

3. `profile_screen.dart`
   - Personal stats grid (streak, best streak, avg score)
   - Weekly bar chart with `fl_chart`
   - Badge grid: unlocked (gold) vs locked (greyed out)

---

## ⚙️ Phase 8 — Polish & Edge Cases (Week 8–9)

### Empty states

- New user with no logs
- Empty leaderboard (no logs yet today)
- Empty notifications list

### Midnight lock

- On app launch: check if today's Hijri date matches last log date
- If log already submitted → show read-only home with "Logged ✓"
- No editing after submission

### Error handling

- No internet → show offline banner, use Hive cache
- Failed Firestore write → retry with exponential backoff
- Auth token expired → re-authenticate silently

### Cloud Functions (deploy alongside app)

```
functions/
├── onLogSubmit.js      # Update streak, check badges, trigger smart notifications
├── onDuaSent.js        # Create notification doc for recipient
└── weeklyReset.js      # Reset weekly streak freeze every Monday
```

> **Note:** `onMemberJoin.js` removed — no group join flow anymore.

---

## 🚀 Phase 9 — Release (Week 9–10)

1. Set bundle ID / package name
2. Add app icons (Islamic star/crescent theme) with `flutter_launcher_icons`
3. Add splash screen with `flutter_native_splash`
4. Enable ProGuard for Android
5. Test on real devices (Android + iOS)
6. Submit to Play Store → TestFlight

---

## 🗑️ Removed from Original Design

The following were part of the original private group system and are **no longer needed:**

| Removed                                 | Reason                             |
| --------------------------------------- | ---------------------------------- |
| `group_model.dart`                      | No groups                          |
| `group_provider.dart`                   | No groups                          |
| `invite_screen.dart` (S-06)             | No invite codes                    |
| `group_sheet_screen.dart` (S-11)        | Replaced by public community sheet |
| `group_manage_screen.dart` (S-14)       | No group admin                     |
| `onMemberJoin.js` Cloud Function        | No join event                      |
| `groups/{groupId}` Firestore collection | No groups                          |
| Invite code generation logic            | Not needed                         |
