# 🗺️ Amol Tracker — Complete User Flow

> v2.0 — Public Community Model. Private groups and invite codes removed.
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
    │                         Google Sign-In / Guest
    │                                   │
    │                      Check Firestore user doc exists?
    │                                   │
    │                    ┌─────────────┴─────────────┐
    │               New user                     Existing user
    │                    │                             │
    │              S-01a: Onboarding 1           S-02: Home
    │                    │
    │              S-01b: Onboarding 2 (streaks/badges)
    │                    │
    │              S-01c: Onboarding 3
    │                    ├── Set display name
    │                    ├── Set privacy (anonymous toggle)
    │                    └── Request notification permission
    │                    │
    │         Create user doc in Firestore
    │         (auto-joined to global community — no invite needed)
    │                    │
    └── Has session ─────┴─────────────► S-02: Home
```

---

## 🏠 Home Flow (S-02)

```
S-02: Home Screen
    │
    ├── Already submitted today (Hijri date match)?
    │       ├── YES → Locked state: "Logged today ✓" (read-only, no toggles)
    │       └── NO  → Active amal toggle list
    │
    ├── Tap individual amal toggle
    │       └── Toggle ON/OFF → score + progress bar updates live
    │
    ├── Tap "Mark all done"
    │       └── All 9 ON → CTA label changes to "Submit today's log"
    │
    ├── Tap "Submit today's log"
    │       ├── Validate: at least 1 field toggled
    │       ├── Save to Firestore amal_logs/{uid}_{hijriDate}
    │       ├── Save to Hive (offline backup)
    │       ├── Streak calculation:
    │       │       ├── Consecutive day → increment currentStreak + check badges
    │       │       ├── 1 day gap + freeze available → Show S-16 Freeze Modal
    │       │       └── Gap > 1 day → reset streak to 1
    │       └── Navigate → S-10: Day Complete
    │
    ├── Tap streak banner
    │       └── Navigate → S-04: History
    │
    ├── Tap Hijri date header
    │       └── Navigate → S-04: History (calendar view)
    │
    └── Bottom nav
            ├── Community → S-05
            ├── History   → S-04
            └── More      → More screen
```

---

## 🎉 Day Complete Flow (S-10)

```
S-10: Day Complete (full-screen, no bottom nav)
    │
    ├── Shows animated score ring, random hadith, amal summary
    │
    ├── Tap "Back to home"
    │       └── Pop → S-02 (locked state, "Logged ✓")
    │
    └── Hardware back → same as "Back to home"
```

---

## 📅 History Flow (S-04 → S-13)

```
S-04: History
    │
    ├── Hijri calendar grid, monthly stats, weakest amal insight
    │
    ├── Tap past day cell (green/amber/red)
    │       └── Navigate → S-13: Day Detail
    │                           │
    │                           ├── Read-only amal list (✓/✗ per field)
    │                           ├── Score, streak value that day
    │                           ├── "Locked — cannot edit" banner at bottom
    │                           └── Back → S-04
    │
    ├── Tap today's cell
    │       └── Navigate → S-02 Home (if not yet logged) or show today's summary
    │
    └── Bottom nav → Home / Community / More
```

---

## 🌐 Community Screen Flow (S-05 → S-12)

```
S-05: Community Screen
    │
    ├── Two tabs at top:
    │       ├── [Sheet] ← default tab
    │       └── [Feed]
    │
    │── TAB 1: Community Sheet
    │       │
    │       ├── Date tabs (horizontal scroll): Today ← past Hijri days
    │       │       ├── Today tab → real-time stream (⏳/✅/❌)
    │       │       └── Past tab  → one-time fetch (✅/❌ only, no ⏳)
    │       │
    │       ├── Sticky column header: Name | 9 amal cols | Score
    │       │
    │       ├── Current user row (pinned top, gold bg)
    │       │       └── If not yet submitted → shows ⏳ "Log today to appear"
    │       │
    │       ├── All other users sorted by score desc
    │       │       ├── ✅ = done (green cell)
    │       │       ├── ❌ = missed (red cell)
    │       │       └── ⏳ = not yet submitted (grey, today only)
    │       │
    │       ├── Real-time updates: submitted user row transitions ⏳ → live data
    │       │
    │       ├── Infinite scroll: loads next 20 on reach bottom
    │       │
    │       ├── Search bar → filter by displayName (client-side)
    │       │       └── Anonymous users excluded from name search
    │       │
    │       └── Tap any row → S-12: User Profile
    │               │
    │               ├── Regular user → full profile (name, avatar, stats)
    │               └── Anonymous user → minimal profile
    │                       (shows 🕌 avatar, "Anonymous", stats only — no real name)
    │
    └── TAB 2: Activity Feed
            │
            ├── Real-time list from Firestore `activity_feed` collection
            │
            ├── Feed item types:
            │       ├── "[Name] completed all amal today 🌟"
            │       ├── "[Name] is on a X-day streak 🔥"
            │       ├── "X community members have logged today"
            │       ├── Islamic quote of the day (rotated daily from hadiths.json)
            │       └── "A community member sent you a dua 🤲"
            │
            └── Tap dua item → S-07 Notifications
```

---

## 👤 User Profile Flow (S-12)

```
S-12: User Profile (public — any user, no friendship needed)
    │
    ├── Viewing another user:
    │       ├── Avatar / name (or 🕌 / "Anonymous" if isAnonymousDisplay)
    │       ├── Streak badge, stats grid, weekly chart
    │       ├── Today's amal grid (read-only, same 9 columns)
    │       ├── Tap "Send Dua 🤲"
    │       │       ├── Check: already sent dua to this user today?
    │       │       │       ├── YES → "You already sent a dua today"
    │       │       │       └── NO  → Write notification doc, show "Dua sent ✓"
    │       └── Back → wherever they came from (S-05 or S-03)
    │
    └── Viewing own profile (tapping own row in sheet):
            ├── Same layout + stats
            ├── Edit display name (inline TextField → save to Firestore)
            ├── Anonymous toggle → updates isAnonymousDisplay in Firestore
            │       └── Community sheet reflects change immediately
            └── Back → S-05
```

---

## 🏆 Leaderboard Flow (S-03)

```
S-03: Leaderboard (accessed via More menu)
    │
    ├── Tabs: Weekly (default) | Daily | Streak
    │       └── Toggle re-sorts list in place (no navigation)
    │
    ├── Podium: top 3 (anonymous users show 🕌 / "Anonymous")
    │
    ├── Full ranked list below podium
    │       └── Current user's row always visible (pinned if outside top view)
    │
    ├── Smart nudge card: "X pts behind 2nd place — log today to close the gap"
    │
    ├── Tap any user row → S-12: User Profile
    │
    └── Back → More screen
```

---

## 📋 More Menu Flow

```
More Screen (bottom nav tab 4)
    │
    ├── Leaderboard     → S-03
    ├── Notifications   → S-07
    ├── My Profile      → S-08
    └── Settings        → S-09
```

---

## 🔔 Notifications Flow (S-07)

```
System tray notification tapped
    │
    ├── "Log your amal"         → deep link → S-02 Home
    ├── "Streak warning"        → deep link → S-02 Home
    ├── "Community activity"    → deep link → S-05 Community (Sheet tab)
    ├── "Leaderboard position"  → deep link → S-03 Leaderboard
    └── "Dua received"          → deep link → S-07 Notifications

S-07: Notifications Screen
    │
    ├── Unread items: gold dot indicator
    ├── Read items: dimmed
    ├── Tap "Mark all read" → clear all gold dots
    └── Tap individual item → mark read + relevant deep link
```

---

## 👤 Own Profile Flow (S-08)

```
S-08: My Profile (via More menu)
    │
    ├── Avatar (or initials), display name, streak pill
    ├── Stats: current streak, best streak, avg score
    ├── Weekly bar chart (fl_chart, last 7 days)
    ├── Badge grid:
    │       ├── Unlocked → gold state
    │       └── Locked   → grey + tap shows "Complete X days to unlock"
    ├── Edit display name → inline TextField → save → update Firestore
    ├── Anonymous toggle → update isAnonymousDisplay in Firestore
    └── Back → More screen
```

---

## ⚙️ Settings Flow (S-09 → S-17)

```
S-09: Settings
    │
    ├── Notification toggles (each cancels/reschedules local notifications):
    │       ├── Morning reminder (6:00 AM)
    │       ├── Evening reminder (6:30 PM)
    │       ├── Streak warning (10:00 PM)
    │       └── Community activity (FCM — toggle disables FCM topic sub)
    │
    ├── Tap "Quiet hours" →
    │       S-17: Quiet Hours
    │               ├── +/- controls for start and end time
    │               ├── Preview: "X hours of silence"
    │               ├── Tap "Save" → SharedPreferences + reschedule
    │               └── Back → S-09
    │
    ├── Privacy: "Show as Anonymous in community"
    │       └── Toggle → update Firestore isAnonymousDisplay
    │
    ├── Calendar type: Hijri (default, read-only for now)
    │
    ├── Ramadan mode toggle (Phase 3)
    │
    └── Sign out
            └── Confirmation dialog → sign out → clear Hive → S-00
```

---

## 🔥 Streak Freeze Modal (S-16)

```
Trigger: user submits log + missed exactly 1 day + streakFreezeUsed == false
    │
    ▼
S-16: Bottom Sheet Modal
    │
    ├── Shows: current streak, freeze count (1 remaining this week)
    ├── "Yes, use my freeze"
    │       ├── currentStreak unchanged
    │       ├── streakFreezeUsed = true (resets Monday via Cloud Function)
    │       └── Navigate → S-10 Day Complete
    │
    └── "No, reset my streak"
            ├── currentStreak = 1
            └── Navigate → S-10 Day Complete
```

---

## 🆕 Empty State Flows (S-15)

```
S-02 Home (new user, no logs ever):
    └── Welcome state: hadith card + "Log today's amal" CTA

S-05 Community Sheet (current user not yet logged today):
    └── Own row pinned at top, ⏳, text: "Log today to appear in the sheet"

S-03 Leaderboard (no logs today yet):
    └── "Be the first to log today! 🌟"

S-07 Notifications (none yet):
    └── "No notifications yet — your community activity will appear here"

S-04 History (brand new user, no past logs):
    └── Calendar shows all grey + "Start logging to build your history"
```

---

## 📱 Bottom Navigation Map

| Tab       | Icon     | Primary screens                            |
| --------- | -------- | ------------------------------------------ |
| Home      | House    | S-02, S-10                                 |
| Community | Grid     | S-05 (Sheet + Feed tabs), S-12             |
| History   | Calendar | S-04, S-13                                 |
| More      | Menu     | More screen → S-03, S-07, S-08, S-09, S-17 |

---

## 🔗 Deep Link Map

| Notification type    | Route            |
| -------------------- | ---------------- |
| Log today's amal     | `/home`          |
| Streak warning       | `/home`          |
| Community activity   | `/community`     |
| Leaderboard position | `/leaderboard`   |
| Dua received         | `/notifications` |
| Badge unlocked       | `/profile`       |

---

## 🔒 Screen Access Rules

| Screen               | Auth required | Notes                   |
| -------------------- | ------------- | ----------------------- |
| S-00 Sign In         | No            | —                       |
| S-01a/b/c Onboarding | Yes (new)     | One-time only           |
| S-02 Home            | Yes           | —                       |
| S-03 Leaderboard     | Yes           | Global, no group        |
| S-04 History         | Yes           | Own logs only           |
| S-05 Community Sheet | Yes           | All users visible       |
| S-07 Notifications   | Yes           | Own notifications       |
| S-08 Profile         | Yes           | Own profile             |
| S-09 Settings        | Yes           | —                       |
| S-10 Day Complete    | Yes           | Requires submitted log  |
| S-12 User Profile    | Yes           | Any user, public        |
| S-13 Day Detail      | Yes           | Own past log, read-only |
| S-15 Empty State     | Yes           | Auto-shown when empty   |
| S-16 Freeze Modal    | Yes           | Auto-triggered          |
| S-17 Quiet Hours     | Yes           | —                       |
| More Screen          | Yes           | Menu only               |

---

## 🗑️ Removed Screens vs v1.0

| Screen | Was                   | Why removed                               |
| ------ | --------------------- | ----------------------------------------- |
| S-06   | Invite / Join Group   | No groups — everyone auto-joined          |
| S-11   | Group Sheet (private) | → replaced by public S-05 Community Sheet |
| S-14   | Group Manage          | No groups to manage                       |
