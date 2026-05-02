# 🗺️ Amol Tracker — Complete User Flow

> Every screen, every navigation path, every edge case.

---

## 🔑 Auth Flow

```
App Launch
    │
    ▼
Check Firebase Auth session
    │
    ├── No session ──────────────► S-00: Sign In
    │                                   │
    │                              Google Sign-In / Guest
    │                                   │
    │                         Check Firestore user doc
    │                                   │
    │                    ┌──────────────┴─────────────┐
    │               New user                      Existing user
    │                    │                              │
    │              S-01a: Onboarding 1            S-02: Home
    │                    │
    │              S-01b: Onboarding 2
    │                    │
    │              S-01c: Onboarding 3 (invite friends)
    │                    │
    │               Create user doc
    │                    │
    └── Has session ─────┴──────────────► S-02: Home
```

---

## 🏠 Home Flow (S-02)

```
S-02: Home Screen
    │
    ├── Already submitted today?
    │       ├── YES → Show locked "Logged today ✓" state (no editing)
    │       └── NO  → Show active amal toggle list
    │
    ├── Tap individual amal toggle
    │       └── Toggle ON/OFF → Update local score live
    │
    ├── Tap "Mark all done"
    │       └── All 9 toggles turn ON → CTA changes to "Submit today's log"
    │
    ├── Tap "Submit today's log"
    │       ├── Save to Firestore + Hive
    │       ├── Trigger streak calculation
    │       │       ├── Streak continues → increment + check badges
    │       │       ├── Streak would break + freeze available → Show S-16 Modal
    │       │       └── Streak breaks → reset to 1
    │       └── Navigate → S-10: Day Complete
    │
    ├── Tap streak banner
    │       └── Navigate → S-04: History
    │
    └── Bottom nav taps
            ├── History  → S-04
            ├── Friends  → S-05
            └── More     → S-09 (Settings)
```

---

## 🎉 Day Complete Flow (S-10)

```
S-10: Day Complete
    │
    ├── Shows: score ring, hadith, amal summary (done/missed)
    │
    ├── Tap "Back to home"
    │       └── Pop → S-02: Home (locked state)
    │
    └── Auto-back after 30s (optional UX improvement)
```

---

## 📅 History Flow (S-04 → S-13)

```
S-04: History / Calendar
    │
    ├── Shows: Hijri calendar grid, monthly stats, insight card
    │
    ├── Tap any past day (green/amber/red cell)
    │       └── Navigate → S-13: Day Detail (read-only)
    │                           │
    │                           ├── Shows: score, streak that day,
    │                           │         each amal done/missed, locked banner
    │                           │
    │                           └── Back button → S-04: History
    │
    └── Bottom nav taps
            ├── Home     → S-02
            ├── Friends  → S-05
            └── More     → S-09
```

---

## 👥 Friends Flow (S-05 → S-06 → S-11 → S-12 → S-14)

```
S-05: Friends & Activity Feed
    │
    ├── Shows: Activity feed, group card, friends list
    │
    ├── Tap "+ Invite" button
    │       └── Navigate → S-06: Invite / Join Group
    │                           │
    │                           ├── Copy code / Share link
    │                           ├── Enter someone else's code → Join group
    │                           └── Back → S-05
    │
    ├── Tap group card ("The Brothers")
    │       └── Navigate → S-11: Group Sheet View
    │                           │
    │                           ├── Scroll day tabs (past days)
    │                           ├── See all members' amal grid for selected day
    │                           └── Back → S-05
    │
    ├── Tap friend name / avatar
    │       └── Navigate → S-12: Friend Profile
    │                           │
    │                           ├── Shows: stats, today's amal grid, weekly chart
    │                           ├── Tap "Send Dua" → creates notification for friend
    │                           ├── Tap "Remove" → confirmation dialog → remove from group
    │                           └── Back → S-05
    │
    ├── Tap group settings icon (admin only)
    │       └── Navigate → S-14: Group Manage
    │                           │
    │                           ├── Copy/share/refresh invite code
    │                           ├── Remove member → confirmation dialog
    │                           ├── Edit group name
    │                           └── Delete group → confirmation dialog → S-05 (empty)
    │
    └── Bottom nav taps → Home / History / More
```

---

## 🏆 Leaderboard Flow (S-03)

```
S-03: Leaderboard
    │
    ├── Shows: podium top 3, full ranked list, smart nudge card
    │
    ├── Tap "Weekly" / "Daily" / "Streak" tabs
    │       └── Re-sort list in same screen (no navigation)
    │
    ├── Tap any friend's row
    │       └── Navigate → S-12: Friend Profile
    │
    └── Bottom nav taps → Home / History / Friends / More
```

---

## 🔔 Notifications Flow (S-07)

```
Notification received (system tray)
    │
    ├── Tap "Log your amal" type notification
    │       └── Deep link → S-02: Home (logging screen)
    │
    ├── Tap "Streak warning" notification
    │       └── Deep link → S-02: Home
    │
    └── Tap "Friend activity" notification
            └── Deep link → S-05: Friends

S-07: Notifications Screen
    │
    ├── Shows: unread (gold dot) vs read notifications
    ├── Tap "Mark all read" → clears gold dots
    └── Bottom nav taps → Home / History / Friends / More
```

---

## 👤 Profile & Badges Flow (S-08)

```
S-08: Profile
    │
    ├── Shows: avatar, name, streak pill, 3-stat grid,
    │         weekly bar chart, badge grid
    │
    ├── Tap locked badge
    │       └── Show tooltip: "Complete X days to unlock"
    │
    └── Bottom nav → More tab (access via Settings)
```

---

## ⚙️ Settings Flow (S-09 → S-17)

```
S-09: Settings
    │
    ├── Notification toggles (morning, evening, streak, friends)
    │       └── Toggle ON/OFF → schedule/cancel local notifications
    │
    ├── Tap "Quiet hours"
    │       └── Navigate → S-17: Quiet Hours
    │                           │
    │                           ├── Adjust start/end time with +/- controls
    │                           ├── Preview: "X hours of silence"
    │                           ├── Tap "Save quiet hours" → save + back
    │                           └── Back → S-09
    │
    ├── Privacy toggles
    │       └── Toggle → update Firestore user doc
    │
    ├── Calendar type → Hijri (default, no change needed for now)
    │
    ├── Ramadan mode toggle
    │       └── When ON → unlock extra amal fields (Phase 3)
    │
    └── Sign out
            └── Confirmation dialog → Firebase Auth sign out → S-00
```

---

## 🔥 Streak Freeze Modal Flow (S-16)

```
Triggered automatically when:
    User submits today's log AND missed yesterday AND
    streakFreezeUsed == false (weekly freeze available)
    │
    ▼
S-16: Streak Freeze Modal (bottom sheet)
    │
    ├── Tap "Yes, use my freeze"
    │       ├── streak stays the same
    │       ├── streakFreezeUsed = true (resets next Monday via Cloud Function)
    │       └── Navigate → S-10: Day Complete
    │
    └── Tap "No, reset my streak"
            ├── currentStreak = 1
            └── Navigate → S-10: Day Complete
```

---

## 🆕 New User Empty State Flow (S-15)

```
S-02: Home (new user, no log, no friends)
    │
    ├── Shows: welcome hadith, empty log prompt, empty friends prompt
    │
    ├── Tap "Log today's amal"
    │       └── Scroll down to reveal amal toggles (same screen, animated)
    │
    └── Tap "Invite friends"
            └── Navigate → S-06: Invite / Join Group
```

---

## 📱 Bottom Navigation Map

| Tab     | Icon     | Routes accessible            |
| ------- | -------- | ---------------------------- |
| Home    | House    | S-02, S-10                   |
| History | Calendar | S-04, S-13                   |
| Friends | People   | S-05, S-06, S-11, S-12, S-14 |
| More    | Menu     | S-07, S-08, S-09, S-17       |

---

## 🔗 Deep Link Map (Notifications)

| Notification type    | Deep link destination |
| -------------------- | --------------------- |
| "Log today's amal"   | `/home`               |
| "Streak warning"     | `/home`               |
| "Friend completed"   | `/friends`            |
| "Leaderboard change" | `/leaderboard`        |
| "Dua received"       | `/notifications`      |
| "Badge unlocked"     | `/profile`            |

---

## 🔒 Screen Access Rules

| Screen               | Requires auth        | Requires group | Admin only  |
| -------------------- | -------------------- | -------------- | ----------- |
| S-00 Sign in         | No                   | No             | No          |
| S-01a/b/c Onboarding | Yes (just signed in) | No             | No          |
| S-02 Home            | Yes                  | No             | No          |
| S-03 Leaderboard     | Yes                  | Yes            | No          |
| S-04 History         | Yes                  | No             | No          |
| S-05 Friends         | Yes                  | No             | No          |
| S-06 Invite          | Yes                  | No             | No          |
| S-07 Notifications   | Yes                  | No             | No          |
| S-08 Profile         | Yes                  | No             | No          |
| S-09 Settings        | Yes                  | No             | No          |
| S-10 Day Complete    | Yes                  | No             | No          |
| S-11 Group Sheet     | Yes                  | Yes            | No          |
| S-12 Friend Profile  | Yes                  | Yes            | No          |
| S-13 Day Detail      | Yes                  | No             | No          |
| S-14 Group Manage    | Yes                  | Yes            | Yes (admin) |
| S-15 Empty State     | Yes                  | No             | No          |
| S-16 Freeze Modal    | Yes                  | No             | No          |
| S-17 Quiet Hours     | Yes                  | No             | No          |
