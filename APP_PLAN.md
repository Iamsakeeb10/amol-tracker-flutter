# 📱 Amol Tracker — Product Requirements Document

A habit-building, motivation, and accountability system for daily Islamic amal.
Built with Flutter + Firebase.

---

## 🧭 Vision

Replace a shared Google Sheet with a high-engagement mobile app that helps users:

- Log daily Islamic habits consistently
- Stay motivated through streaks and gamification
- Build accountability through a **public community feed** — visible to all app users
- Feel rewarded for doing good

**Core principle:** This is not just a tracker. It is a daily Islamic accountability system — designed to make doing good feel rewarding, visible, and consistent through open community transparency and gentle gamification. Like a living, public Google Sheet — everyone sees everyone.

---

## 🧱 Tech Stack

| Layer            | Technology                         |
| ---------------- | ---------------------------------- |
| Frontend         | Flutter                            |
| Authentication   | Firebase Auth                      |
| Database         | Firestore (with offline cache)     |
| Notifications    | Firebase Cloud Messaging (FCM)     |
| Automation       | Cloud Functions                    |
| Offline Support  | Hive / Firestore local persistence |
| State Management | Riverpod                           |
| Calendar         | Hijri calendar package             |

---

## 🚀 Phase 1 — MVP (Build First)

### 1. Authentication

- Google Sign-In (primary)
- Anonymous login (fallback)
- Display name + profile avatar
- 3-screen onboarding flow for new users

### 2. Daily Amal Logging

Users log daily activities using simple toggle buttons.

**Amal fields:**

| Field             | Description                     |
| ----------------- | ------------------------------- |
| Fard              | 5 daily prayers in congregation |
| Takbir            | With Takbir-e-Ula               |
| Morning Azkar     | Morning remembrance             |
| Evening Azkar     | Evening remembrance             |
| Quran Tilawat     | Quran recitation                |
| Surah Mulk        | Daily Mulk recitation           |
| Miswak            | Use of miswak                   |
| Sunnah + Witr     | Sunnah prayers and Witr         |
| Post-Prayer Azkar | Azkar after fard prayers        |

**UX requirements:**

- Toggle YES / NO per field
- "Mark All Done" one-tap button
- Hijri date shown in header
- Offline-first — works without internet, syncs when connected
- Day locks after midnight — no editing past days

### 3. Score System

Each amal has a point value. Maximum daily score = 100 points.

| Amal              | Points                    |
| ----------------- | ------------------------- |
| Each Fard prayer  | 20 pts (×1 if all 5 done) |
| Sunnah + Witr     | 10 pts                    |
| Morning Azkar     | 8 pts                     |
| Evening Azkar     | 8 pts                     |
| Quran Tilawat     | 10 pts                    |
| Surah Mulk        | 10 pts                    |
| Post-Prayer Azkar | 10 pts                    |
| Miswak            | 5 pts                     |
| Takbir            | 5 pts                     |
| **Total**         | **~100 pts**              |

**Output shown to user:**

- Today's score (e.g. 74/100)
- Yesterday's score for comparison
- Score color: green ≥ 80, amber ≥ 50, red < 50

### 4. Streak System

- Track consecutive active days
- Show current streak and personal best
- Streak resets if no log submitted by midnight
- Streak freeze — 1 free skip per week, does not break streak
- Milestone badges at: 3, 7, 14, 30, 60, 100 days

### 5. Calendar / History View

- Hijri calendar grid view
- Day color coding:
  - 🟢 Green = score ≥ 80
  - 🟡 Amber = score 50–79
  - 🔴 Red = score < 50 or missed
- Tap any day to see full detail
- Monthly consistency percentage shown at top

### 6. Push Notifications

- Basic reminders:
  - "You haven't logged today yet"
  - "Don't break your streak 🔥"
  - Morning / evening / night time-based reminders
  - Prayer time-based triggers (optional, uses location)
- Quiet hours setting — user can set do-not-disturb window
- Special Friday reminder

---

## ⚡ Phase 2 — Community & Motivation

### 7. Public Community Sheet (Replaces Private Group System)

**This is the core social feature.** Every user of the app is part of one shared, open community. No invites, no codes, no private groups.

- A scrollable, spreadsheet-style grid screen showing **all app users** and their daily amal logs
- Columns = each amal field (9 columns)
- Rows = each registered user (sorted by score descending by default)
- Each cell shows: ✅ done, ❌ missed, or ⏳ pending (not yet logged today)
- Date tabs at the top — scroll left/right to view past days
- The current user's row is **pinned at the top** or **highlighted in gold**
- A total score column on the right
- **Real-time updates** — when someone submits their log, their row updates live
- Privacy toggle: users can choose to hide their name (show as "Anonymous Brother/Sister") but their row is still visible
- Search/filter bar to find a specific user by name

**This screen replaces S-11 (Group Sheet View) and becomes a core tab in the bottom nav.**

### 8. Public Leaderboard

- Daily and weekly rankings across **all app users**
- Ranked by score or streak (user can toggle)
- Top 3 shown prominently with visual highlight
- User's own rank always visible even if outside top 3
- No group scoping — one global leaderboard

### 9. Activity Feed

- "X completed all amal today"
- "Y is on a 14-day streak 🔥"
- Streak milestones announced
- Islamic quote of the day
- Hadith shown upon completing all amal

### 10. Smart Notifications

Context-aware notifications:

- "3 community members already completed today 👀"
- "You're 2nd on the leaderboard — log now to reach 1st 🏆"
- "The community is active today 💪"
- Idle nudge — notify if you haven't logged in 2+ days
- Friday special motivation message

### 11. Dua Feature (Simplified)

- On any user's public profile, tap "Send Dua"
- Recipient sees a notification: "A community member sent you a dua 🤲"
- Sender identity is optional (can be anonymous)
- No friend/connection required — open to all users

---

## 🧠 Phase 3 — Advanced & Smart

### 12. Configurable Amal System

- Store amal fields in Firebase Remote Config
- Admin can enable/disable specific tasks
- Add new tasks without pushing an app update
- Ramadan Mode — extra fields unlock: Suhoor, Iftar, Taraweeh, Tahajjud
- Custom amal slots — users can add their own personal amal

### 13. Advanced Analytics

- Weekly performance graph
- Weakest amal insight — "You've missed Morning Azkar 10 out of 14 days"
- Best day of the week for consistency
- Missed vs completed ratio
- Export summary to PDF

### 14. Islamic Context Features

- Prayer times based on user location
- Alerts for Hijri special days (Ashura, first 10 of Dhul Hijja, Laylatul Qadr nights, etc.)
- Ramadan and Dhul Hijja mode auto-activates on correct dates
- Qibla direction widget

---

## ❌ Do Not Build in MVP

| Feature                         | Reason                             |
| ------------------------------- | ---------------------------------- |
| Private group creation          | Replaced by public community model |
| Invite codes / join links       | No longer needed                   |
| Group admin / member management | No longer needed                   |
| Group streak goal               | Replaced by global leaderboard     |
| Full admin panel UI             | Unnecessary complexity early       |
| Role management                 | Not needed                         |
| Dynamic column builder UI       | Overkill for MVP                   |
| Manual notification sending     | Automate instead                   |
| Complex settings screens        | Keep onboarding simple             |
| Prayer times / Qibla            | Phase 3 only                       |
| Custom amal slots               | Phase 3 only                       |

---

## 🎯 Success Metrics

| Metric                        | Goal              |
| ----------------------------- | ----------------- |
| Daily Active Users (DAU)      | Track from week 1 |
| 7-day streak retention        | > 40%             |
| 30-day streak retention       | > 20%             |
| Daily logging completion rate | > 60%             |
| Notification open rate        | > 25%             |
| Community sheet daily views   | > 70% of DAU      |

---

## 🗓️ Build Order (Recommended)

1. Firebase setup + Auth (Google + Anonymous)
2. Onboarding flow (3 screens)
3. Daily logging screen with 9 amal toggles
4. Score calculation engine
5. Streak logic + freeze mechanic
6. Hijri calendar history view
7. Basic push notifications
8. **Public Community Sheet screen** (all users, real-time grid)
9. Global leaderboard (daily + weekly)
10. Activity feed
11. Public user profile + Dua feature
12. Smart notifications
13. Configurable amal + Ramadan mode
14. Advanced analytics + PDF export
15. Islamic context features (prayer times, Hijri alerts)

---

_Document version: 2.0 — Public Community Model (replaces private group system)_
