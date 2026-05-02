# ✅ Amol Tracker — Verification Checklist

> Test every feature before shipping. Check each box only after manual testing on a real device.

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
- [ ] Invite code is generated and displayed on Slide 3
- [ ] User document is created in Firestore on first login
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
- [ ] Tapping "Submit today's log" saves data to Firestore
- [ ] Data is also saved to Hive for offline access
- [ ] After submit, app navigates to S-10 (Day Complete)
- [ ] Submitted log is locked — cannot be edited after submission
- [ ] Re-opening app after submit shows "Logged today ✓" locked state

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
- [ ] Hadith card on History screen rotates (not always the same)

---

## 👥 Friends & Groups

### Invite (S-06)

- [ ] Unique 6-char group code is generated per group
- [ ] "Copy code" copies code to clipboard
- [ ] "Share link" opens system share sheet
- [ ] Entering valid code and tapping "Join group" adds user to group
- [ ] Entering invalid code shows appropriate error
- [ ] User cannot join a group they're already in

### Friends screen (S-05)

- [ ] Activity feed updates in real-time
- [ ] Friend scores and status (done / pending) are accurate
- [ ] Group card shows correct group streak
- [ ] Group streak resets if any member misses a day
- [ ] "Send Dua" creates a notification for the recipient
- [ ] Recipient sees Dua notification in S-07

### Group Sheet (S-11)

- [ ] All group members appear as rows
- [ ] Day tabs scroll to show past dates
- [ ] Correct amal grid for each member on selected day
- [ ] Group average score calculates correctly
- [ ] Member's own row is highlighted or labelled "(you)"
- [ ] Pending member (not yet submitted today) shows pending state

### Friend Profile (S-12)

- [ ] Correct name, avatar, streak, stats for tapped friend
- [ ] Weekly chart shows that friend's real score data
- [ ] Today's amal grid is accurate for that friend
- [ ] "Send Dua" works
- [ ] "Remove" triggers confirmation dialog before removing
- [ ] After removal, friend disappears from group

### Group Manage (S-14)

- [ ] Only admin can access this screen
- [ ] Non-admin members do NOT see manage option
- [ ] Admin can rename group
- [ ] Admin can remove members (with confirmation)
- [ ] Admin can delete group (with confirmation)
- [ ] Deleting group clears `groupId` from all member user docs

---

## 🏆 Leaderboard (S-03)

- [ ] Members ranked correctly by weekly score (default)
- [ ] "Daily" tab shows today's scores
- [ ] "Streak" tab ranks by current streak
- [ ] Top 3 podium renders with correct names/avatars
- [ ] Current user's rank is always visible (even if below top 3)
- [ ] "X pts behind 2nd" nudge calculates correctly
- [ ] Scores update in real-time (or near real-time)
- [ ] Tapping a member row navigates to S-12 Friend Profile

---

## 🔔 Notifications (S-07, S-09, S-17)

### Delivery

- [ ] Morning reminder fires at 6:00 AM
- [ ] Evening reminder fires at 6:30 PM
- [ ] Streak warning fires at 10:00 PM if no log today
- [ ] Friday special message fires Friday morning
- [ ] Smart notification fires when friends complete (FCM)
- [ ] "3 friends already completed" notification fires correctly
- [ ] Notifications do NOT fire during quiet hours
- [ ] Tapping any notification deep-links to correct screen

### Settings (S-09)

- [ ] Toggling morning reminder OFF cancels that scheduled notification
- [ ] Toggling back ON re-schedules the notification
- [ ] Same for evening, streak, and friend activity toggles
- [ ] Privacy toggles update Firestore user doc immediately
- [ ] Ramadan mode toggle enables/disables correctly (Phase 3)
- [ ] Sign out confirmation dialog appears before signing out

### Quiet Hours (S-17)

- [ ] +/- controls adjust time correctly (no overflow past 23:59 / 0:00)
- [ ] Preview text updates as time changes
- [ ] "Save quiet hours" persists to SharedPreferences
- [ ] After save, notifications are rescheduled to respect quiet hours
- [ ] Quiet hours span midnight correctly (e.g. 10 PM to 5 AM)

---

## 👤 Profile & Badges (S-08)

- [ ] Name, avatar initials display correctly
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
  - [ ] Top of group badge (ranked 1st on weekly leaderboard)
  - [ ] Perfect week badge (7 consecutive days with score ≥ 80)

---

## 🆕 Empty States (S-15)

- [ ] New user with no logs sees welcome empty state (not a broken screen)
- [ ] New user with no friends sees friends empty state
- [ ] Empty leaderboard (no group) shows "invite friends" prompt
- [ ] Empty notifications list shows appropriate message
- [ ] Empty history (no past logs) shows prompt to start logging

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

### UI / UX

- [ ] No screen has broken layout on small screen (360px width)
- [ ] No screen has broken layout on large screen (428px+ width)
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
- [ ] Loading states (shimmer) show while data is fetching

---

## 🚀 Pre-Release Checklist

- [ ] App icon is set for Android and iOS
- [ ] Splash screen shows brand colors and logo
- [ ] App name shows "Amol Tracker" (not "amol_tracker")
- [ ] All debug prints are removed
- [ ] Firebase Analytics events are firing correctly
- [ ] Firestore security rules are deployed and tested
- [ ] Cloud Functions are deployed
- [ ] ProGuard/R8 rules are set for Android release build
- [ ] App tested on Android 10, 12, 14
- [ ] App tested on iOS 16, 17
- [ ] Play Store internal testing track is configured
- [ ] TestFlight build is distributed

---

## 📊 Screen Completion Summary

| #     | Screen              | Designed | Built | Tested |
| ----- | ------------------- | -------- | ----- | ------ |
| S-00  | Sign In             | ✅       | ☐     | ☐      |
| S-01a | Onboarding 1        | ✅       | ☐     | ☐      |
| S-01b | Onboarding 2        | ✅       | ☐     | ☐      |
| S-01c | Onboarding 3        | ✅       | ☐     | ☐      |
| S-02  | Home / Daily Log    | ✅       | ☐     | ☐      |
| S-03  | Leaderboard         | ✅       | ☐     | ☐      |
| S-04  | History / Calendar  | ✅       | ☐     | ☐      |
| S-05  | Friends & Feed      | ✅       | ☐     | ☐      |
| S-06  | Invite / Join       | ✅       | ☐     | ☐      |
| S-07  | Notifications       | ✅       | ☐     | ☐      |
| S-08  | Profile & Badges    | ✅       | ☐     | ☐      |
| S-09  | Settings            | ✅       | ☐     | ☐      |
| S-10  | Day Complete        | ✅       | ☐     | ☐      |
| S-11  | Group Sheet         | ✅       | ☐     | ☐      |
| S-12  | Friend Profile      | ✅       | ☐     | ☐      |
| S-13  | Day Detail          | ✅       | ☐     | ☐      |
| S-14  | Group Manage        | ✅       | ☐     | ☐      |
| S-15  | Empty State         | ✅       | ☐     | ☐      |
| S-16  | Streak Freeze Modal | ✅       | ☐     | ☐      |
| S-17  | Quiet Hours         | ✅       | ☐     | ☐      |

**Total: 20 screens designed. 0 built. 0 tested.**

> Update this table as you build and test each screen.
