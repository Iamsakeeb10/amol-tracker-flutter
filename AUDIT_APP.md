# 🔍 Amol Tracker — Full Codebase Audit & Fix Prompt for Cursor

> Run this AFTER all 4 phases of amol_fix_tasks.md are complete.
> Purpose: Find and fix any remaining stale code, inconsistencies, or broken references.
> Do NOT add new features. Only fix what's broken or inconsistent.

---

## Instructions for Cursor

Read every file in the `lib/` directory. For each file, check against the rules below.
Fix issues in-place. Report what you fixed at the end.
Do not change anything that is already correct.
Do not break any working feature.

---

## 🔴 Category 1 — Stale Score & Amal Field References

Search every file for these and fix:

### 1.1 Hardcoded score denominators

```
FIND:   "/100" hardcoded as a string literal (not using kMaxDailyScore)
FIND:   "100 pts" hardcoded
FIND:   "out of 100" hardcoded
FIND:   maxScore = 100 hardcoded as int literal (not the constant)
FIX:    Replace all with kMaxDailyScore from amal_fields.dart
```

### 1.2 Old point values still hardcoded anywhere

```
FIND:   score += 20  (old fard points)
FIND:   score += 8   (old azkar points)
FIND:   score += 5   (standalone, not using field.points)
FIND:   Any score calculation not going through calculateScore()
FIX:    Route all score calculation through calculateScore() in score_calculator.dart
```

### 1.3 Old AmalField usage (isNumeric bool instead of AmalType enum)

```
FIND:   field.isNumeric (old bool property)
FIND:   AmalField( ... isNumeric: true ... ) (old constructor)
FIND:   if (field.isNumeric) (old check)
FIX:    Replace with field.type == AmalType.numeric
```

### 1.4 Old boolean-only amal state

```
FIND:   Map<String, bool> for amal state (should be Map<String, dynamic>)
FIND:   amalState[id] as bool (for fard or takbir — these are now int)
FIND:   log['fard'] == true (should handle both bool and int)
FIND:   log['takbir'] == true (same)
FIX:    Use getNumericValue() helper for fard/takbir
        Use == true only for boolean fields
```

### 1.5 "Mark all done" still setting fard/takbir to true

```
FIND:   'fard': true in markAll() or similar
FIND:   'takbir': true in markAll() or similar
FIX:    'fard': 5, 'takbir': 5 (int, not bool)
```

---

## 🕌 Category 2 — Stale Islamic Date / Time Code

Search every file for these and fix:

### 2.1 Old Hijri helper calls

```
FIND:   HijriCalendar.now()
FIND:   HijriHelper.todayString()
FIND:   HijriHelper.formatDisplay()
FIND:   HijriHelper.isConsecutive()
FIND:   import 'hijri_helper.dart'
FIX:    Replace with IslamicDateService equivalent methods
        IslamicDateService.getCurrentIslamicDateString()
        IslamicDateService.getDisplayIslamicDate()
        IslamicDateService.areConsecutiveIslamicDays()
```

### 2.2 DateTime.now() used for Islamic date logic

```
FIND:   DateTime.now() used to determine today's amal date/key
FIND:   DateTime.now() used in streak calculation
FIND:   DateTime.now() used for Firestore document ID generation
FIND:   DateTime.now() used for day-lock check
FIX:    Replace with IslamicDateService.getCurrentIslamicDateString()
        (DateTime.now() is still OK for timestamps like submittedAt, createdAt)
```

### 2.3 Midnight-based day change logic

```
FIND:   Any comment or code referencing "midnight" as day boundary
FIND:   TimeOfDay(hour: 0) or hour == 0 used for date change
FIND:   .isBefore(DateTime(y, m, d, 23, 59)) for day boundary
FIX:    Replace with Maghrib-based boundary from IslamicDateService
```

### 2.4 Non-BD timezone usage

```
FIND:   DateTime.now() converted with .toLocal() for date display
FIND:   DateTime.now().toUtc() for Islamic date
FIND:   Any hardcoded UTC offset like Duration(hours: 6) instead of tz package
FIX:    Use IslamicDateService._nowInBD() for BD-aware current time
```

### 2.5 Gregorian date shown as Islamic date

```
FIND:   DateFormat('dd/MM/yyyy') used in Islamic date display
FIND:   Gregorian month names (January, February...) in Islamic context
FIND:   intl DateFormat used for Hijri header display
FIX:    Use IslamicDateService.getDisplayIslamicDate() for all Hijri displays
```

---

## 🎛️ Category 3 — Stale UI Widget References

### 3.1 Numeric fields still rendering as switches/toggles

```
FIND:   AmalToggleRow used for field with id == 'fard'
FIND:   AmalToggleRow used for field with id == 'takbir'
FIND:   Switch( ... ) or CupertinoSwitch( ... ) for fard or takbir
FIND:   Any Toggle for AmalType.numeric fields
FIX:    Use AmalStepperRow for all AmalType.numeric fields
        Use AmalToggleRow only for AmalType.boolean fields
```

### 3.2 Community sheet numeric cells showing ✅/❌ for numeric fields

```
FIND:   _doneCell() or ✅ used for fard or takbir columns in community grid
FIND:   _missedCell() or ❌ used for fard or takbir columns in community grid
FIND:   Icons.check or Icons.close for numeric amal cells
FIX:    Show Bengali numeral text for numeric fields:
        val > 0 → gold text "৩" (or whatever the value is)
        val == 0 → grey text "০"
```

### 3.3 English-only labels

```
FIND:   Text(field.label) used as primary label in Home screen amal rows
        (should show field.labelBn as primary, field.label as secondary/tooltip)
FIND:   Any hardcoded English amal label strings not using field properties
FIX:    Primary label = field.labelBn (Bengali)
        Secondary/sublabel = field.sublabel (Bengali description)
        field.label (English) only for accessibility/semantics label
```

### 3.4 Day Complete screen showing bool for numeric

```
FIND:   In day_complete_screen.dart — fard/takbir showing ✓ or ✗
FIND:   Icon(Icons.check_circle) for fard regardless of value
FIX:    Show "৩/৫" format for numeric fields
        Show ✓/✗ only for boolean fields
```

### 3.5 Day Detail screen (read-only) showing bool for numeric

```
FIND:   In day_detail_screen.dart — same issue as Day Complete
FIX:    Same fix: show "X/5" or "X/৫" for fard and takbir
```

### 3.6 User profile amal grid showing bool for numeric

```
FIND:   In user_profile_screen.dart — today's amal grid
FIND:   Any cell rendering for fard/takbir using boolean display
FIX:    Show numeric value in Bengali for numeric fields
```

---

## 📦 Category 4 — Removed Features Still Referenced

### 4.1 Group system references

```
FIND:   groupId anywhere in code
FIND:   group_model.dart import
FIND:   GroupModel class usage
FIND:   groupProvider usage
FIND:   'groups' Firestore collection reference
FIND:   inviteCode anywhere in code
FIND:   InviteScreen navigation or import
FIND:   GroupSheetScreen navigation or import
FIND:   GroupManageScreen navigation or import
FIND:   context.go('/friends/invite') or similar old routes
FIND:   context.go('/friends/group-sheet') or similar
FIND:   context.go('/friends/group-manage') or similar
FIX:    Remove all references. If a navigation leads to a removed screen,
        redirect to '/community' instead.
```

### 4.2 Old friends system references

```
FIND:   friendsProvider or friends_provider.dart
FIND:   FriendsScreen import or navigation
FIND:   '/friends' route (not '/community')
FIND:   addFriend() method calls
FIND:   removeFriend() method calls
FIND:   friendsList in any state
FIX:    Remove. Friends concept no longer exists.
        Public community is the replacement.
```

### 4.3 Old bottom nav with Friends tab

```
FIND:   BottomNavigationBarItem with label 'Friends'
FIND:   index == 2 navigating to FriendsScreen
FIX:    Should be 'Community' navigating to CommunityScreen
        Bottom nav: Home | Community | History | More
```

### 4.4 Old notification text referencing groups/friends

```
FIND:   "3 friends already completed" in notification strings
FIND:   "Your group is active" in notification strings
FIND:   "Group streak" in any UI text
FIX:    Replace:
        "3 friends" → "3 community members"
        "Your group" → "The community"
        "Group streak" → remove or replace with personal streak
```

---

## 🔧 Category 5 — Provider & State Issues

### 5.1 Riverpod provider watching removed providers

```
FIND:   ref.watch(groupProvider)
FIND:   ref.watch(friendsProvider)
FIND:   ref.read(groupProvider.notifier)
FIX:    Remove. Replace with communityProvider where needed.
```

### 5.2 amalProvider state type mismatch

```
FIND:   State declared as Map<String, bool> (should be Map<String, dynamic>)
FIND:   Anywhere the provider returns bool for fard or takbir
FIX:    State = Map<String, dynamic> where fard/takbir are int, rest are bool
```

### 5.3 Community provider using wrong date

```
FIND:   communityProvider using DateTime.now() for Firestore query date
FIND:   communityProvider using HijriHelper (old)
FIND:   .where('hijriDate', isEqualTo: <non-IslamicDateService result>)
FIX:    All Firestore queries use IslamicDateService.getCurrentIslamicDateString()
```

### 5.4 Streak provider using wrong date logic

```
FIND:   streakProvider comparing Gregorian dates
FIND:   streakProvider using midnight as day boundary
FIND:   lastLogDate stored as Gregorian date string
FIX:    lastLogDate always stored as Hijri date string from IslamicDateService
        Consecutive check uses IslamicDateService.areConsecutiveIslamicDays()
```

---

## 🛣️ Category 6 — Router Issues

### 6.1 Old routes still registered

```
FIND:   GoRoute(path: '/friends/invite', ...)
FIND:   GoRoute(path: '/friends/group-sheet', ...)
FIND:   GoRoute(path: '/friends/group-manage', ...)
FIND:   GoRoute(path: '/friends/:uid', ...) (old pattern)
FIX:    Remove these routes entirely
        Ensure '/community' and '/community/profile/:uid' exist
```

### 6.2 Old route navigation calls

```
FIND:   context.go('/friends')
FIND:   context.push('/friends/...')
FIND:   context.go('/invite')
FIX:    Replace with context.go('/community')
```

### 6.3 Missing More screen route

```
FIND:   Is '/more' registered as a GoRoute? If not, add it.
FIND:   Is MoreScreen imported and connected?
FIX:    Ensure More screen is accessible from bottom nav tab index 3
```

### 6.4 Deep link routes match notification types

```
VERIFY: '/community' deep link works from notification tap
VERIFY: '/home' deep link works from notification tap
VERIFY: '/leaderboard' deep link works from notification tap
VERIFY: '/notifications' deep link works from notification tap
VERIFY: '/profile' deep link works from notification tap
FIX:    Any broken deep link route
```

---

## 🗄️ Category 7 — Firestore & Data Model Issues

### 7.1 Old Firestore collection references

```
FIND:   .collection('groups') anywhere
FIND:   .collection('users').doc(uid).collection('friends') anywhere
FIX:    Remove all group collection references
```

### 7.2 amal_log document ID format

```
FIND:   Any amal_log document created with Gregorian date in ID
FIND:   Document ID format not matching '{uid}_{hijriDate}'
FIND:   auto-generated IDs (doc()) for amal_logs (should be named)
FIX:    All amal_log IDs must be: '${uid}_${IslamicDateService.getCurrentIslamicDateString()}'
```

### 7.3 User document missing new fields

```
FIND:   User document creation missing isAnonymousDisplay field
FIND:   User document creation missing badges field
FIND:   User document creation still setting groupId
FIX:    User doc must include:
        isAnonymousDisplay: false (default)
        badges: []
        NO groupId field
```

### 7.4 amal_log document missing denormalized fields

```
FIND:   amal_log saved without displayName field
FIND:   amal_log saved without photoUrl field
FIND:   amal_log saved without isAnonymousDisplay field
FIX:    Every amal_log save must include:
        displayName: user.name (or 'Anonymous' if isAnonymousDisplay)
        photoUrl: user.photoUrl
        isAnonymousDisplay: user.isAnonymousDisplay
        (These are needed for community sheet rendering without extra user fetches)
```

### 7.5 Numeric values stored as bool in Firestore

```
FIND:   amal_log save where fard is stored as bool
FIND:   amal_log save where takbir is stored as bool
FIX:    Always store fard and takbir as int (0–5)
        Never store them as bool in new writes
```

---

## 🎨 Category 8 — UI Consistency Checks

### 8.1 Islamic geometric background missing on any screen

```
FIND:   Any Scaffold or screen Widget NOT using GeoBackground widget
        (or equivalent SVG background implementation)
CHECK:  All 18 screens must have the emerald background + geometric pattern
FIX:    Wrap screen content with GeoBackground or add to Scaffold background
```

### 8.2 AppColors not used — hardcoded colors

```
FIND:   Color(0xFF...) hardcoded anywhere outside colors.dart
FIND:   Colors.green used instead of AppColors.success
FIND:   Colors.red used instead of AppColors.danger
FIND:   Colors.amber used instead of AppColors.warning
FIND:   Color(0xFF0D3D2E) hardcoded instead of AppColors.emeraldDeep
FIND:   Color(0xFFC9A84C) hardcoded instead of AppColors.gold
FIX:    Replace all with AppColors constants
```

### 8.3 Font inconsistency

```
FIND:   TextStyle(fontFamily: 'serif') not using GoogleFonts.cormorantGaramond()
FIND:   Large title text not using Cormorant Garamond
FIND:   Body text not using DM Sans (GoogleFonts.dmSans())
FIND:   Hardcoded fontFamily strings instead of GoogleFonts calls
FIX:    All headlines → GoogleFonts.cormorantGaramond()
        All body → GoogleFonts.dmSans() or theme default (DM Sans)
```

### 8.4 Score display consistency

```
FIND:   Score shown without Bengali numeral formatting
FIND:   Score shown as "86" where correct value should be different
FIND:   Score bar width calculated using wrong max (86 instead of 100)
FIX:    All score bars: width = (score / kMaxDailyScore) * maxWidth
        Verify in: home_screen, community_row_card, leaderboard, profile
```

---

## 📋 Category 9 — Missing Null Safety & Error Handling

### 9.1 Unsafe casts after type change

```
FIND:   amalState['fard'] as bool (unsafe — now int)
FIND:   amalState['takbir'] as bool (unsafe — now int)
FIND:   log.fard as bool (unsafe after model update)
FIX:    Use safe cast: (amalState['fard'] as int?) ?? 0
```

### 9.2 Missing null checks on user profile loads

```
FIND:   user.name! (force unwrap)
FIND:   user.photoUrl! (force unwrap)
FIND:   data['displayName'] as String (no null fallback)
FIX:    user.name ?? 'Anonymous'
        user.photoUrl ?? ''
        data['displayName'] as String? ?? 'Anonymous'
```

### 9.3 IslamicDateService not wrapped in try-catch at call sites

```
FIND:   IslamicDateService.getCurrentIslamicDateString() called without try-catch
        in critical paths (submit log, streak check, community query)
FIX:    Wrap in try-catch with fallback to HijriCalendar.now() formatted string
```

---

## 🔤 Category 10 — Bengali Text & Localization Checks

### 10.1 Mixed language in same UI context

```
FIND:   English amal labels next to Bengali UI elements on same screen
FIND:   "Morning Azkar" shown where "সকালের আযকার" should be
FIND:   English month names in Hijri date display
FIX:    Primary labels = Bengali (labelBn)
        Sublabels = Bengali (sublabel)
        Hijri months = Bengali from IslamicDateService._hijriMonthBn()
```

### 10.2 Bengali numerals in Islamic date but Arabic numerals in score

```
FIND:   Score shown as "74" while date shown as "১ জিলকদ"
NOTE:   This is ACCEPTABLE — scores stay Arabic numerals (international)
        Only Hijri date uses Bengali numerals
        Do NOT change score numerals — leave as Arabic/Western
```

### 10.3 Notification strings using old group language

```
FIND:   In notification_service.dart — any string with "group"
FIND:   In Cloud Function strings — any reference to "group"
FIX:    "community" replaces "group" everywhere in user-facing strings
```

---

## ✅ Audit Completion Checklist

After fixing all categories, verify:

### Score

- [ ] All 9 amal maxed → score = 100 exactly
- [ ] kMaxDailyScore used everywhere, never hardcoded 100 or 86
- [ ] calculateScore() is the single source of truth

### Date

- [ ] IslamicDateService used everywhere for Islamic date
- [ ] No HijriCalendar.now() calls remain
- [ ] No DateTime.now() used for Islamic date logic
- [ ] Bengali Hijri date displays correctly

### UI

- [ ] Fard and Takbir show stepper widget in Home
- [ ] All 7 boolean amal show toggle switch
- [ ] Bengali labels on all amal rows
- [ ] Community sheet shows numerals for fard/takbir columns
- [ ] Day Complete shows "৩/৫" style for numeric amal

### Data

- [ ] No 'groups' Firestore collection referenced
- [ ] No groupId in any user document write
- [ ] amal_log IDs use Hijri date from IslamicDateService
- [ ] fard and takbir stored as int in Firestore
- [ ] Backward compat for old bool logs works

### Navigation

- [ ] '/friends' route removed
- [ ] '/community' route works
- [ ] Bottom nav tab 2 = Community (not Friends)
- [ ] More screen accessible from tab 4
- [ ] All deep links work

### General

- [ ] No hardcoded colors — all use AppColors
- [ ] No force unwraps (!) on nullable user fields
- [ ] All screens have Islamic geometric background
- [ ] No Dart analysis errors (run: flutter analyze)
- [ ] No debug print statements left in code
- [ ] App runs without crash: flutter run

---
