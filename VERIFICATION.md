# ✅ Amol Tracker — Verification Checklist

> Test every feature before shipping. Check each box only after manual testing on a real device.
> **v2.0 — Public Community Model. Private groups and invite codes removed.**

---

## 🔐 Authentication

### Sign In (S-00)

- [ ] Google Sign-In button opens Google account picker
- [ ] After selecting account, user is authenticated in Firebase
- [ ] Guest / anonymous login works as fallback
- [ ] New users are routed to Onboarding (S-01a)
- [ ] Returning users are routed directly to Home (S-02)
- [ ] Sign-in screen does NOT show if user is already authenticated
- [ ] App handles Google Sign-In cancellation gracefully (no crash)

### Onboarding (S-01a, S-01b, S-01c)

- [ ] Slide 1 → Slide 2 → Slide 3 navigation works
- [ ] "Skip" on any slide routes to Home
- [ ] User can set display name on Slide 3
- [ ] Privacy preference (anonymous mode) can be set on Slide 3
- [ ] User document is created in Firestore on first login
- [ ] User is **automatically part of global community** — no group join step
- [ ] Onboarding is NOT shown again after first completion
- [ ] Notification permission is requested on Slide 3

### Sign Out

- [ ] Sign out clears Firebase Auth session
- [ ] After sign out, app routes to S-00
- [ ] Hive local cache is cleared on sign out

---

## 📋 Daily Logging (S-02)

### Amal toggles

- [ ] All 9 amal rows render correctly with correct labels and point values
- [ ] Tapping a toggle switches it ON (green) or OFF (grey)
- [ ] Score updates live with every toggle tap
- [ ] Progress bar updates in real-time (0–100%)
- [ ] "7 / 9" counter updates as toggles turn on
- [ ] Fard and Takbir show numeric input, not just YES/NO toggle

### Submit flow

- [ ] "Mark all done" sets all 9 toggles to ON
- [ ] CTA button label changes from "Mark all done" to "Submit today's log" after any toggle
- [ ] Tapping "Submit today's log" saves data to Firestore `amal_logs` collection
- [ ] Data is also saved to Hive for offline access
- [ ] After submit, app navigates to S-10 (Day Complete)
- [ ] Submitted log is locked — cannot be edited after submission
- [ ] Re-opening app after submit shows "Logged today ✓" locked state
- [ ] After submission, user's row in Community Sheet updates from ⏳ to live data

### Offline behaviour

- [ ] Toggles work with no internet connection
- [ ] Data is saved to Hive when offline
- [ ] Hive data syncs to Firestore when connection is restored
- [ ] Offline banner is shown when no connectivity detected
- [ ] Hijri date header shows correctly regardless of internet

---

## 🎉 Day Complete Screen (S-10)

- [ ] Score ring shows correct score (matches submitted log)
- [ ] Score ring animation plays on screen load
- [ ] Hadith card shows a relevant hadith
- [ ] All 9 amal fields show correct done (green ✓) or missed (red ✗) status
- [ ] Points are correct per field (Fard 20, Azkar 8, etc.)
- [ ] "Back to home" returns to Home in locked state
- [ ] Screen cannot be reached without a submitted log

---

## 🔥 Streak System

- [ ] Streak increments by 1 when log is submitted on consecutive Hijri days
- [ ] Streak resets to 1 when a day is skipped (no log submitted)
- [ ] Best streak is saved and never decreases
- [ ] Streak value on Home screen updates after submission
- [ ] Streak freeze modal (S-16) appears when:
  - [ ] User missed exactly 1 day
  - [ ] `streakFreezeUsed == false` for this week
- [ ] "Use freeze" preserves streak and sets `streakFreezeUsed = true`
- [ ] "Reset my streak" sets streak to 1
- [ ] Streak freeze resets every Monday (via Cloud Function)
- [ ] Streak freeze does NOT appear if already used this week
- [ ] Streak freeze does NOT appear if missed more than 1 day

---

## 📅 History & Calendar (S-04, S-13)

- [ ] Hijri calendar grid renders correctly for current month
- [ ] Days with score ≥ 80 show green
- [ ] Days with score 50–79 show amber
- [ ] Days with score < 50 or no log show red
- [ ] Days not yet reached show empty/grey
- [ ] Today's cell is highlighted distinctly
- [ ] Monthly consistency % calculates correctly
- [ ] Average daily score calculates correctly
- [ ] Weakest amal insight is accurate (most-missed amal this month)
- [ ] Tapping a day opens S-13 Day Detail
- [ ] Day Detail shows correct amal data for that specific date
- [ ] Day Detail shows "read-only — cannot edit" banner

---

## 🌐 Community Sheet (S-05)

### Grid display

- [ ] Column headers render: Name | Fard | Takbir | M.Azkar | E.Azkar | Quran | Mulk | Miswak | Sunnah | P.Azkar | Score
- [ ] Current user's row is pinned at position 1 with gold background
- [ ] All other users appear below, sorted by score descending
- [ ] ✅ = amal done (green), ❌ = amal missed (red), ⏳ = not yet submitted (grey)
- [ ] Score badge at end of each row is correct
- [ ] Anonymous users show as "Anonymous 🕌" (no real name or avatar)
- [ ] Rows load in batches (pagination, 20 at a time)
- [ ] Infinite scroll loads more users correctly

### Date tabs

- [ ] Today is selected by default
- [ ] Scrolling left shows past dates (Hijri)
- [ ] Tapping a past date reloads the grid for that date
- [ ] Past date view: no ⏳ status — all rows are final (✅ or ❌)
- [ ] Today's view: real-time updates as users submit

### Real-time updates

- [ ] When a user submits today's log, their row updates live (⏳ → live data) without page refresh
- [ ] Score column updates live
- [ ] Row re-sorts by score after update (or shows update in place — consistent UX)

### Search

- [ ] Search bar filters visible rows by display name
- [ ] Clearing search restores full list
- [ ] Anonymous users excluded from name search (or shown as "Anonymous")

### Navigation

- [ ] Tapping any row navigates to S-12 User Profile
- [ ] Back from S-12 returns to S-05 correctly

---

## 👤 User Profile (S-12)

- [ ] Correct name, avatar (or anonymous placeholder) displays
- [ ] Current streak and best streak are accurate
- [ ] Today's amal grid shows correct data for that user
- [ ] Weekly bar chart shows that user's real score data for last 7 days
- [ ] Average score is accurate
- [ ] "Send Dua 🤲" button creates a notification document in recipient's Firestore notifications
- [ ] Confirmation message shows after dua sent: "Dua sent ✓"
- [ ] Dua can be sent to any user — no friendship required
- [ ] Viewing own profile: edit display name works
- [ ] Viewing own profile: anonymous toggle works and updates community sheet display

---

## 🏆 Leaderboard (S-03)

- [ ] Users ranked correctly by weekly score (default)
- [ ] "Daily" tab shows today's scores
- [ ] "Streak" tab ranks by current streak
- [ ] Top 3 podium renders with correct names/avatars
- [ ] Anonymous users show anonymised on leaderboard
- [ ] Current user's rank is always visible (even if below top 3)
- [ ] "X pts behind 2nd" nudge calculates correctly
- [ ] Scores update in real-time (or near real-time)
- [ ] Tapping a user row navigates to S-12 User Profile

---

## 🔔 Notifications (S-07, S-09, S-17)

### Delivery

- [ ] Morning reminder fires at 6:00 AM
- [ ] Evening reminder fires at 6:30 PM
- [ ] Streak warning fires at 10:00 PM if no log today
- [ ] Friday special message fires Friday morning
- [ ] "X community members already completed" notification fires (FCM)
- [ ] Dua received notification fires when another user sends a dua
- [ ] Notifications do NOT fire during quiet hours
- [ ] Tapping any notification deep-links to correct screen

### Settings (S-09)

- [ ] Toggling morning reminder OFF cancels that scheduled notification
- [ ] Toggling back ON re-schedules the notification
- [ ] Same for evening, streak, and community activity toggles
- [ ] Privacy toggle (anonymous) updates Firestore `isAnonymousDisplay` immediately
- [ ] Sign out confirmation dialog appears before signing out

### Quiet Hours (S-17)

- [ ] +/- controls adjust time correctly (no overflow past 23:59 / 0:00)
- [ ] Preview text updates as time changes
- [ ] "Save quiet hours" persists to SharedPreferences
- [ ] After save, notifications are rescheduled to respect quiet hours
- [ ] Quiet hours span midnight correctly (e.g. 10 PM to 5 AM)

---

## 👤 Profile & Badges (S-08)

- [ ] Name, avatar (or initials) display correctly
- [ ] Current streak and best streak are accurate
- [ ] Average score calculates correctly (all-time)
- [ ] Weekly bar chart shows last 7 days of scores
- [ ] Today's bar is highlighted/distinct
- [ ] Unlocked badges show gold state
- [ ] Locked badges show greyed-out state with requirement hint
- [ ] Badges unlock automatically when condition is met:
  - [ ] 7-day streak badge
  - [ ] 14-day streak badge
  - [ ] 30-day streak badge
  - [ ] 100-day streak badge
  - [ ] Top of community badge (ranked #1 on global weekly leaderboard)
  - [ ] Perfect week badge (7 consecutive days with score ≥ 80)

---

## 🆕 Empty States (S-15)

- [ ] New user with no logs sees welcome empty state (not a broken screen)
- [ ] Empty leaderboard shows "Be the first to log today!" prompt
- [ ] Empty notifications list shows appropriate message
- [ ] Empty history (no past logs) shows prompt to start logging
- [ ] Community sheet for new user: their row shows ⏳ with "Log today to appear here" hint

---

## ⚡ Performance & Technical

### Offline

- [ ] App launches without internet
- [ ] Today's log persists across app restarts (Hive)
- [ ] No crashes when network drops mid-session
- [ ] Sync completes successfully when network restores

### Data accuracy

- [ ] Score never exceeds 100
- [ ] Score never goes below 0
- [ ] Hijri dates are correct for Bangladesh timezone (UTC+6)
- [ ] Midnight lock uses Hijri date, not Gregorian
- [ ] Streak calculation uses Hijri consecutive days

### Community sheet performance

- [ ] Grid does not freeze on 100+ users
- [ ] Pagination loads without visible lag
- [ ] Real-time Firestore listener does not cause excessive rebuilds
- [ ] Column headers stay frozen during vertical scroll

### UI / UX

- [ ] No screen has broken layout on small screen (360px width)
- [ ] No screen has broken layout on large screen (428px+ width)
- [ ] Community sheet horizontal scroll is smooth on all screen sizes
- [ ] Islamic geometric background renders on all screens
- [ ] Gold/emerald color palette is consistent throughout
- [ ] All animations are smooth (60fps) on mid-range Android
- [ ] Bottom nav highlights correct tab on every screen
- [ ] Back navigation works correctly on all screens
- [ ] Android hardware back button works on all screens

### Crash & Error handling

- [ ] App does not crash if Firestore write fails
- [ ] App does not crash if Firebase Auth token expires
- [ ] App does not crash with empty data (new user)
- [ ] Error messages are shown in Bengali or English (not raw exceptions)
- [ ] Loading states (shimmer) show while community sheet is fetching

---

## 🚀 Pre-Release Checklist

- [ ] App icon is set for Android and iOS
- [ ] Splash screen shows brand colors and logo
- [ ] App name shows "Amol Tracker" (not "amol_tracker")
- [ ] All debug prints are removed
- [ ] Firebase Analytics events are firing correctly
- [ ] Firestore security rules are deployed (users can only write their own `amal_logs`, read all)
- [ ] Cloud Functions are deployed
- [ ] ProGuard/R8 rules are set for Android release build
- [ ] App tested on Android 10, 12, 14
- [ ] App tested on iOS 16, 17
- [ ] Play Store internal testing track is configured
- [ ] TestFlight build is distributed

---

## 📊 Screen Completion Summary

| #     | Screen                | Designed | Built | Tested |
| ----- | --------------------- | -------- | ----- | ------ |
| S-00  | Sign In               | ✅       | ☐     | ☐      |
| S-01a | Onboarding 1          | ✅       | ☐     | ☐      |
| S-01b | Onboarding 2          | ✅       | ☐     | ☐      |
| S-01c | Onboarding 3          | ✅       | ☐     | ☐      |
| S-02  | Home / Daily Log      | ✅       | ☐     | ☐      |
| S-03  | Leaderboard           | ✅       | ☐     | ☐      |
| S-04  | History / Calendar    | ✅       | ☐     | ☐      |
| S-05  | Community Sheet       | ✅       | ☐     | ☐      |
| S-07  | Notifications         | ✅       | ☐     | ☐      |
| S-08  | Profile & Badges      | ✅       | ☐     | ☐      |
| S-09  | Settings              | ✅       | ☐     | ☐      |
| S-10  | Day Complete          | ✅       | ☐     | ☐      |
| S-12  | User Profile (public) | ✅       | ☐     | ☐      |
| S-13  | Day Detail            | ✅       | ☐     | ☐      |
| S-15  | Empty State           | ✅       | ☐     | ☐      |
| S-16  | Streak Freeze Modal   | ✅       | ☐     | ☐      |
| S-17  | Quiet Hours           | ✅       | ☐     | ☐      |

**Total: 17 screens designed. 0 built. 0 tested.**

> 3 screens removed from original (S-06 Invite, S-11 Group Sheet, S-14 Group Manage).
> S-05 repurposed: was Friends & Activity Feed → now Public Community Sheet.
> S-12 repurposed: was Friend Profile (required friendship) → now Public User Profile (no friendship needed).

---

## 🗑️ Screens Removed vs v1.0

| Screen | Was                 | Removed Because                         |
| ------ | ------------------- | --------------------------------------- |
| S-06   | Invite / Join Group | No groups, no invite codes              |
| S-11   | Group Sheet View    | Replaced by public S-05 Community Sheet |
| S-14   | Group Manage        | No groups to manage                     |
