# 🗺️ Amol Tracker — Complete User Flow

> Every screen, every navigation path, every edge case.
> **v2.0 — Public Community Model. Private groups and invite codes removed.**

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
    │              S-01c: Onboarding 3 (set display name, privacy pref)
    │                    │
    │               Create user doc (auto-joined to global community)
    │                    │
    └── Has session ─────┴──────────────► S-02: Home
```

> **No invite codes. No group selection.** Every new user is automatically part of the public community.

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
    │       ├── Save to Firestore amal_logs + Hive
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
            ├── Community → S-05
            ├── History   → S-04
            └── More      → S-09 (Settings)
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
            ├── Home      → S-02
            ├── Community → S-05
            └── More      → S-09
```

---

## 🌐 Community Sheet Flow (S-05 → S-12)

This is the public, open community screen — the Google Sheet for the whole app.

```
S-05: Community Sheet Screen
    │
    ├── Header: date tabs (today selected, scroll left for past days)
    ├── Column headers: Name | 9 amal columns | Score
    │
    ├── Current user row → pinned at top, gold highlight
    │
    ├── All other users listed below, sorted by score (desc)
    │       ├── ✅ = completed that amal
    │       ├── ❌ = missed that amal
    │       └── ⏳ = hasn't submitted yet today
    │
    ├── Tap date tab (past day)
    │       └── Reload grid for that Hijri date (read-only, no ⏳ — everyone's status final)
    │
    ├── Search bar → filter visible rows by display name (client-side)
    │
    ├── Tap any user row
    │       └── Navigate → S-12: User Profile
    │                           │
    │                           ├── Shows: avatar, name, streak badge
    │                           ├── Today's amal grid (read-only)
    │                           ├── Stats: score, best streak, avg score
    │                           ├── Weekly bar chart (last 7 days)
    │                           ├── Tap "Send Dua 🤲" → creates notification for that user
    │                           │       └── Confirmation: "Dua sent ✓"
    │                           └── Back → S-05
    │
    └── Bottom nav taps → Home / History / More
```

---

## 🏆 Leaderboard Flow (S-03)

```
S-03: Leaderboard
    │
    ├── Shows: global podium top 3, full ranked list, smart nudge card
    │
    ├── Tap "Weekly" / "Daily" / "Streak" tabs
    │       └── Re-sort list in same screen (no navigation)
    │
    ├── Tap any user row
    │       └── Navigate → S-12: User Profile
    │
    └── Bottom nav taps → Home / Community / History / More
```

---

## 🔔 Notifications Flow (S-07)

```
Notification received (system tray)
    │
    ├── Tap "Log your amal" type notification
    │       └── Deep link → S-02: Home
    │
    ├── Tap "Streak warning" notification
    │       └── Deep link → S-02: Home
    │
    ├── Tap "Community activity" notification
    │       └── Deep link → S-05: Community Sheet
    │
    └── Tap "Dua received" notification
            └── Deep link → S-07: Notifications

S-07: Notifications Screen
    │
    ├── Shows: unread (gold dot) vs read notifications
    ├── Tap "Mark all read" → clears gold dots
    └── Bottom nav taps → Home / Community / History / More
```

---

## 👤 Profile & Badges Flow (S-08)

```
S-08: Profile (own profile)
    │
    ├── Shows: avatar, name, streak pill, 3-stat grid,
    │         weekly bar chart, badge grid
    │
    ├── Tap "Edit display name"
    │       └── Inline text field → save to Firestore user doc
    │
    ├── Toggle "Show as Anonymous in community"
    │       └── Updates isAnonymousDisplay in Firestore
    │
    ├── Tap locked badge
    │       └── Show tooltip: "Complete X days to unlock"
    │
    └── Bottom nav → More tab
```

---

## ⚙️ Settings Flow (S-09 → S-17)

```
S-09: Settings
    │
    ├── Notification toggles (morning, evening, streak, community)
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
    ├── Privacy toggle: "Show as Anonymous in community"
    │       └── Toggle → update Firestore isAnonymousDisplay field
    │
    ├── Ramadan mode toggle (Phase 3)
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
    │       ├── streakFreezeUsed = true
    │       └── Navigate → S-10: Day Complete
    │
    └── Tap "No, reset my streak"
            ├── currentStreak = 1
            └── Navigate → S-10: Day Complete
```

---

## 🆕 New User Empty State Flow (S-15)

```
S-02: Home (new user, no log)
    │
    ├── Shows: welcome hadith, empty log prompt
    │
    └── Tap "Log today's amal"
            └── Scroll down to reveal amal toggles (same screen, animated)

S-05: Community Sheet (new user, no log yet today)
    │
    └── Current user row shows ⏳ with "Log today to appear here" hint
```

---

## 📱 Bottom Navigation Map

| Tab       | Icon        | Routes accessible            |
| --------- | ----------- | ---------------------------- |
| Home      | House       | S-02, S-10                   |
| Community | Grid/people | S-05, S-12                   |
| History   | Calendar    | S-04, S-13                   |
| More      | Menu        | S-03, S-07, S-08, S-09, S-17 |

> **Note:** Community tab replaces the old Friends tab. Leaderboard (S-03) is accessible from More menu.

---

## 🔗 Deep Link Map (Notifications)

| Notification type    | Deep link destination |
| -------------------- | --------------------- |
| "Log today's amal"   | `/home`               |
| "Streak warning"     | `/home`               |
| "Community activity" | `/community`          |
| "Leaderboard change" | `/leaderboard`        |
| "Dua received"       | `/notifications`      |
| "Badge unlocked"     | `/profile`            |

---

## 🔒 Screen Access Rules

| Screen               | Requires auth        | Notes                                |
| -------------------- | -------------------- | ------------------------------------ |
| S-00 Sign in         | No                   | —                                    |
| S-01a/b/c Onboarding | Yes (just signed in) | New users only                       |
| S-02 Home            | Yes                  | —                                    |
| S-03 Leaderboard     | Yes                  | Global, no group required            |
| S-04 History         | Yes                  | —                                    |
| S-05 Community Sheet | Yes                  | All users visible, no group required |
| S-07 Notifications   | Yes                  | —                                    |
| S-08 Profile         | Yes                  | —                                    |
| S-09 Settings        | Yes                  | —                                    |
| S-10 Day Complete    | Yes                  | —                                    |
| S-12 User Profile    | Yes                  | Any user's public profile            |
| S-13 Day Detail      | Yes                  | —                                    |
| S-15 Empty State     | Yes                  | —                                    |
| S-16 Freeze Modal    | Yes                  | —                                    |
| S-17 Quiet Hours     | Yes                  | —                                    |

---

## 🗑️ Screens Removed vs Original Design

| Removed Screen           | Was                               | Why                                     |
| ------------------------ | --------------------------------- | --------------------------------------- |
| S-06 Invite / Join Group | Invite code entry + sharing       | No groups — everyone is auto-joined     |
| S-11 Group Sheet View    | Private group amal grid           | Replaced by public S-05 Community Sheet |
| S-14 Group Manage        | Admin: rename/remove/delete group | No groups to manage                     |

> **S-05 in this document = Community Sheet** (previously Friends & Activity Feed).
> **S-12 in this document = Public User Profile** (previously Friend Profile, but now requires no friendship).
