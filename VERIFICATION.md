# ✅ Amol Tracker — Verification Checklist

> v2.0 — Public Community Model. Private groups and invite codes removed.
> Test every feature before shipping. Check only after manual testing on real device.

---

## 🔐 Authentication

### Sign In (S-00)

- [ ] Google Sign-In opens Google account picker
- [ ] After account selection, user is authenticated in Firebase
- [ ] Guest / anonymous login works as fallback
- [ ] New users → Onboarding S-01a
- [ ] Returning users → Home S-02 directly
- [ ] Sign-in screen NOT shown if already authenticated
- [ ] Google Sign-In cancellation handled gracefully (no crash)

### Onboarding (S-01a, S-01b, S-01c)

- [ ] Slide 1 → Slide 2 → Slide 3 navigation works
- [ ] "Skip" on any slide routes to Home
- [ ] Slide 3: user can set display name (pre-filled from Google)
- [ ] Slide 3: anonymous toggle works (saved to Firestore)
- [ ] Slide 3: notification permission is requested
- [ ] User document created in Firestore on completion
- [ ] User auto-joined to global community — no group join step
- [ ] Onboarding NOT shown again after first completion

### Sign Out

- [ ] Firebase Auth session cleared
- [ ] Hive local cache cleared on sign out
- [ ] App routes to S-00 after sign out

---

## 📋 Daily Logging (S-02)

### Amal toggles

- [ ] All 9 amal rows render with correct labels and point values
- [ ] Toggle switches ON (green) / OFF (grey) correctly
- [ ] Score updates live on every toggle tap
- [ ] Progress bar updates in real-time
- [ ] "7 / 9" counter updates correctly
- [ ] Fard and Takbir fields accept numeric input (not just toggle)

### Submit flow

- [ ] "Mark all done" sets all 9 toggles ON
- [ ] CTA label changes from "Mark all done" → "Submit today's log" after any toggle
- [ ] "Submit today's log" saves to Firestore `amal_logs/{uid}_{hijriDate}`
- [ ] Same data saved to Hive (offline backup)
- [ ] Navigate to S-10 Day Complete after save
- [ ] Submitted log is locked — cannot be re-edited
- [ ] Re-opening app after submit shows locked "Logged today ✓" state
- [ ] After submission, own row in Community Sheet updates from ⏳ → live data in real-time

### Offline behaviour

- [ ] Toggles work with no internet
- [ ] Data saved to Hive when offline
- [ ] Hive data syncs to Firestore when connection restored
- [ ] Offline banner shown when no connectivity detected
- [ ] Hijri date header correct regardless of internet

---

## 🎉 Day Complete (S-10)

- [ ] Score ring shows correct score matching submitted log
- [ ] Score ring animation plays on screen load
- [ ] Random hadith shown from hadiths.json (not always same one)
- [ ] All 9 fields show correct ✓ done or ✗ missed
- [ ] Points correct per field
- [ ] "Back to home" → Home locked state
- [ ] Cannot reach this screen without a submitted log

---

## 🔥 Streak System

- [ ] Streak increments on consecutive Hijri days
- [ ] Streak resets to 1 when a day is skipped
- [ ] Best streak never decreases
- [ ] Streak value updates on Home after submission
- [ ] Streak freeze modal (S-16) shows when:
  - [ ] Missed exactly 1 day
  - [ ] `streakFreezeUsed == false`
- [ ] "Use freeze" preserves streak, sets `streakFreezeUsed = true`
- [ ] "Reset my streak" sets currentStreak = 1
- [ ] Freeze resets every Monday (Cloud Function weeklyReset.js)
- [ ] Freeze modal NOT shown if already used this week
- [ ] Freeze modal NOT shown if missed more than 1 day

---

## 📅 History & Calendar (S-04, S-13)

- [ ] Hijri calendar grid renders correctly for current month
- [ ] Score ≥ 80 → green, 50–79 → amber, < 50 or no log → red, future → grey
- [ ] Today's cell distinctly highlighted
- [ ] Monthly consistency % correct
- [ ] Average daily score correct
- [ ] Weakest amal insight accurate (most-missed field this month)
- [ ] Tap past day → S-13 Day Detail
- [ ] Day Detail shows correct amal data for that date
- [ ] Day Detail shows "read-only — cannot edit" banner
- [ ] Back from Day Detail → History

---

## 🌐 Community Sheet (S-05 — Tab 1)

### Grid display

- [ ] Column headers render: Name | Fard | Takbir | M.Az | E.Az | Quran | Mulk | Miswak | Sunnah | P.Az | Score
- [ ] Column headers stay frozen/sticky during vertical scroll
- [ ] Own row pinned at position 0 with gold background
- [ ] All other users below, sorted by score descending
- [ ] ✅ = done (green), ❌ = missed (red), ⏳ = not submitted (grey, today only)
- [ ] Anonymous users show 🕌 and "Anonymous" (no real name or avatar)
- [ ] Score badge at end of each row is correct
- [ ] Own row shows ⏳ + "Log today to appear here" if not yet submitted

### Date tabs

- [ ] Today tab selected by default
- [ ] Scrolling left shows past Hijri dates
- [ ] Tapping past date reloads grid for that date (one-time fetch, not real-time)
- [ ] Past date view: no ⏳ — all rows ✅ or ❌ only
- [ ] Today view: real-time Firestore stream (snapshots())

### Real-time updates

- [ ] When user submits, their row updates ⏳ → live data without page refresh
- [ ] Score column updates live
- [ ] Row resorting after update is smooth (no jarring jump)

### Pagination

- [ ] First 20 rows load on screen open
- [ ] Scrolling to bottom loads next 20 rows
- [ ] Last page loads correctly even if fewer than 20 rows remain
- [ ] No duplicate rows across pages
- [ ] Loading indicator shown while fetching next page

### Search

- [ ] Search bar filters rows by displayName (client-side)
- [ ] Clearing search restores full list
- [ ] Anonymous users not findable by name search
- [ ] Search works on both today and past date views

### Navigation

- [ ] Tapping any row → S-12 User Profile
- [ ] Tapping anonymous row → minimal profile (🕌, "Anonymous", stats only)
- [ ] Back from User Profile → S-05 Community Sheet (correct tab preserved)

---

## 📣 Activity Feed (S-05 — Tab 2)

- [ ] Feed loads real-time from Firestore `activity_feed` collection
- [ ] "X completed all amal today 🌟" appears after user submits perfect log
- [ ] "X is on a Y-day streak 🔥" appears on streak milestone
- [ ] "N community members logged today" counter updates through day
- [ ] Islamic quote of the day shows (rotates daily, not randomly)
- [ ] "A community member sent you a dua 🤲" appears in own feed when dua received
- [ ] Feed items are in reverse chronological order (newest first)
- [ ] Switching between Sheet and Feed tabs preserves scroll position

---

## 👤 User Profile (S-12)

### Viewing another user

- [ ] Correct name/avatar (or 🕌/"Anonymous" if anonymous)
- [ ] Current streak and best streak accurate
- [ ] Today's amal grid shows correct data (read-only)
- [ ] Weekly bar chart shows last 7 days real score data
- [ ] Average score accurate
- [ ] "Send Dua 🤲" creates notification doc in recipient's Firestore
- [ ] After sending: "Dua sent ✓" confirmation shown
- [ ] Dua can be sent to any user — no friendship required
- [ ] **Rate limit enforced: only 1 dua per sender per recipient per day**
- [ ] Attempting second dua same day → "You already sent a dua today"

### Viewing own profile (via S-05 own row tap)

- [ ] Edit display name inline → saves to Firestore
- [ ] Anonymous toggle updates `isAnonymousDisplay` in Firestore
- [ ] Community sheet reflects name/anonymity change immediately

---

## 🏆 Leaderboard (S-03)

- [ ] Weekly tab: ranked by weekly cumulative score (default)
- [ ] Daily tab: ranked by today's score
- [ ] Streak tab: ranked by current streak
- [ ] Podium renders top 3 correctly
- [ ] Anonymous users show 🕌 / "Anonymous" on podium and list
- [ ] Own rank always visible even if outside top 3 (pinned or shown separately)
- [ ] "X pts behind 2nd place" nudge calculates correctly
- [ ] Tapping any user → S-12 User Profile
- [ ] Leaderboard updates near real-time as users submit

---

## 📋 More Screen

- [ ] "Leaderboard" → S-03
- [ ] "Notifications" → S-07
- [ ] "My Profile" → S-08
- [ ] "Settings" → S-09
- [ ] More screen accessible from bottom nav tab 4

---

## 🔔 Notifications (S-07, S-09, S-17)

### Delivery

- [ ] Morning reminder fires at 6:00 AM
- [ ] Evening reminder fires at 6:30 PM
- [ ] Streak warning fires at 10:00 PM if no log today
- [ ] Friday Jumu'ah special fires Friday morning
- [ ] "X community members already completed" FCM fires (via Cloud Function)
- [ ] Dua received FCM fires when another user sends dua
- [ ] Notifications NOT sent during quiet hours
- [ ] Each notification deep-links to correct screen

### Notification screen (S-07)

- [ ] Unread items show gold dot
- [ ] Read items dimmed
- [ ] "Mark all read" clears all gold dots
- [ ] Tapping item marks it read + follows deep link

### Settings (S-09)

- [ ] Morning toggle OFF → cancels scheduled notification
- [ ] Morning toggle ON → re-schedules notification
- [ ] Same for evening, streak warning, community activity toggles
- [ ] Anonymous toggle updates Firestore `isAnonymousDisplay` immediately
- [ ] Sign out confirmation dialog appears
- [ ] Sign out clears session + Hive + routes to S-00

### Quiet Hours (S-17)

- [ ] +/- controls adjust time without overflow (wraps at 23:59 / 0:00)
- [ ] Preview text updates as time changes: "X hours of silence"
- [ ] "Save" persists to SharedPreferences
- [ ] After save, all notifications rescheduled respecting quiet window
- [ ] Quiet hours spanning midnight work correctly (e.g. 10 PM to 5 AM)

---

## 👤 Own Profile & Badges (S-08)

- [ ] Name, avatar / initials correct
- [ ] Current + best streak accurate
- [ ] All-time average score correct
- [ ] Weekly bar chart (last 7 days) renders correctly
- [ ] Today's bar highlighted distinctly
- [ ] Badge unlocked → gold
- [ ] Badge locked → grey + tap shows "Complete X to unlock"
- [ ] Badges unlock automatically:
  - [ ] 3-day streak badge
  - [ ] 7-day streak badge
  - [ ] 14-day streak badge
  - [ ] 30-day streak badge
  - [ ] 60-day streak badge
  - [ ] 100-day streak badge
  - [ ] Top of community badge (ranked #1 global weekly)
  - [ ] Perfect week badge (7 days score ≥ 80)

---

## 🆕 Empty States (S-15)

- [ ] New user Home: welcome state + "Log today's amal" CTA (no broken screen)
- [ ] Community sheet own row: ⏳ + "Log today to appear here"
- [ ] Community sheet past date with no logs: "No logs recorded for this day"
- [ ] Leaderboard empty: "Be the first to log today! 🌟"
- [ ] Notifications empty: "No notifications yet"
- [ ] History no past logs: "Start logging to build your history"

---

## ⚡ Performance & Technical

### Offline

- [ ] App launches without internet
- [ ] Today's log persists across restarts (Hive)
- [ ] No crashes when network drops mid-session
- [ ] Sync completes when network restores
- [ ] Community sheet shows cached data offline with "offline" badge

### Data accuracy

- [ ] Score never exceeds 100 / never below 0
- [ ] Hijri dates correct for Bangladesh timezone (UTC+6)
- [ ] Midnight lock uses Hijri date, not Gregorian
- [ ] Streak uses Hijri consecutive days

### Community sheet performance

- [ ] Grid does not freeze on 100+ users
- [ ] Pagination loads without visible lag
- [ ] Real-time Firestore listener does not cause excessive widget rebuilds
- [ ] Column headers stay frozen during vertical scroll
- [ ] `RepaintBoundary` on each row prevents cascade rebuilds
- [ ] Horizontal scroll is smooth on all screen sizes

### Firestore security

- [ ] User cannot write another user's amal_log (security rules block it)
- [ ] User cannot edit/delete their own submitted log (rules block update/delete)
- [ ] User cannot write to activity_feed (Cloud Functions only)
- [ ] Unauthenticated user cannot read any data

### UI / UX

- [ ] No broken layout on 360px width (small Android)
- [ ] No broken layout on 428px+ width (large iPhone)
- [ ] Islamic geometric background on all screens
- [ ] Gold/emerald palette consistent throughout
- [ ] 60fps animations on mid-range Android
- [ ] Bottom nav highlights correct tab on every screen
- [ ] Android hardware back button works on all screens
- [ ] Shimmer loading shown while community sheet fetches

### Crash & Error

- [ ] No crash if Firestore write fails
- [ ] No crash if Firebase Auth token expires
- [ ] No crash with empty data (new user)
- [ ] Error messages shown in English/Bengali (not raw exceptions)

---

## 🚀 Pre-Release Checklist

- [ ] App icon set for Android and iOS
- [ ] Splash screen correct brand colors
- [ ] App name shows "Amol Tracker" (not "amol_tracker")
- [ ] All debug prints removed
- [ ] Firebase Analytics events firing
- [ ] Firestore security rules deployed and tested
- [ ] Cloud Functions deployed (onLogSubmit, onDuaSent, weeklyReset)
- [ ] ProGuard/R8 rules set for Android release
- [ ] Tested on Android 10, 12, 14
- [ ] Tested on iOS 16, 17
- [ ] Play Store internal testing track configured
- [ ] TestFlight build distributed

---

## 📊 Screen Completion Summary

| #     | Screen                          | Designed | Built | Tested |
| ----- | ------------------------------- | -------- | ----- | ------ |
| S-00  | Sign In                         | ✅       | ☐     | ☐      |
| S-01a | Onboarding 1                    | ✅       | ☐     | ☐      |
| S-01b | Onboarding 2 (streaks)          | ✅       | ☐     | ☐      |
| S-01c | Onboarding 3 (name + privacy)   | ✅       | ☐     | ☐      |
| S-02  | Home / Daily Log                | ✅       | ☐     | ☐      |
| S-03  | Leaderboard (global)            | ✅       | ☐     | ☐      |
| S-04  | History / Calendar              | ✅       | ☐     | ☐      |
| S-05  | Community Screen (Sheet + Feed) | ✅       | ☐     | ☐      |
| S-07  | Notifications                   | ✅       | ☐     | ☐      |
| S-08  | Profile & Badges                | ✅       | ☐     | ☐      |
| S-09  | Settings                        | ✅       | ☐     | ☐      |
| S-10  | Day Complete                    | ✅       | ☐     | ☐      |
| S-12  | User Profile (public)           | ✅       | ☐     | ☐      |
| S-13  | Day Detail                      | ✅       | ☐     | ☐      |
| S-15  | Empty State                     | ✅       | ☐     | ☐      |
| S-16  | Streak Freeze Modal             | ✅       | ☐     | ☐      |
| S-17  | Quiet Hours                     | ✅       | ☐     | ☐      |
| —     | More Screen                     | ✅       | ☐     | ☐      |

**Total: 18 screens designed. 0 built. 0 tested.**

> Removed from v1.0: S-06 (Invite), S-11 (Group Sheet), S-14 (Group Manage) — 3 screens.
> Added in v2.0: More Screen, Activity Feed tab inside S-05 — net screen count nearly same.

---

## 🗑️ Removed Screens vs v1.0

| Screen | Was                 | Why                                     |
| ------ | ------------------- | --------------------------------------- |
| S-06   | Invite / Join Group | No groups — everyone auto-joined        |
| S-11   | Private Group Sheet | Replaced by public S-05 Community Sheet |
| S-14   | Group Manage        | No groups to manage                     |
