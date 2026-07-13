# Analytics & Crashlytics Logs

All analytics and crashlytics instrumentation in the Amol Tracker app.

---

## Architecture

- **Service**: `lib/core/services/analytics_service.dart` — singleton `AnalyticsService.instance`
- **Backing**: Firebase Analytics + Firebase Crashlytics
- **Debug guard**: All calls are **no-ops in debug mode** (`kReleaseMode` check)
- **Route observer**: `FirebaseAnalyticsObserver` attached to `GoRouter` for automatic screen tracking (`lib/core/router/router.dart:69`)
- **Fatal error capture**: Flutter framework errors and Dart isolate errors routed to Crashlytics in release mode (`lib/main.dart:37-42`)

---

## Crashlytics Setup

### User Identity

| Method | Crashlytics Key | Called From |
|--------|----------------|-------------|
| `setUserIdentifier(uid)` | `_crashlytics.setUserIdentifier` | `app.dart:130` — on auth state change (set to uid) or sign-out (set to `''`) |

### Custom Keys

| Key | Value | Set In |
|-----|-------|--------|
| `app_version` | `PackageInfo.version` | `app.dart:54` |
| `build_number` | `PackageInfo.buildNumber` | `app.dart:55` |
| `language` | Current locale code (`en`/`bn`) | `app.dart:56` |
| `device_locale` | `Platform.localeName` | `app.dart:57` |
| `anonymous_mode` | `bool` | `settings_screen.dart:58` — toggled from settings |
| `notification_enabled` | `bool` | Not set in current code (method exists) |
| `last_screen` | Screen name string | `reports_screen.dart:55` — set on screen entry |
| `last_feature` | Feature name string | `reports_screen.dart:56` — set on screen entry |

---

## Analytics Events

### Onboarding

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `onboarding_completed` | `duration: int` | User completes onboarding — `onboarding_screen.dart:138` |
| `language_selected` | `language: String` (`'en'` / `'bn'`) | Language picked on sign-in — `sign_in_screen.dart:109,131` |

### Daily Amal

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `amal_completed` | `score: int` | User submits daily amal — `amal_provider.dart:441` |
| `daily_score_completed` | `total_score: int` | Same submission — `amal_provider.dart:442` |
| `streak_extended` | `streak_days: int` | Streak incremented after submission — `amal_provider.dart:449` |
| `streak_lost` | `previous_streak: int` | Streak reset after missed day — `amal_provider.dart:471` |
| `streak_freeze_used` | `streak_days: int` | Streak freeze consumed — `amal_provider.dart:390` |

### Quran

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `quran_opened` | *(none)* | Quran screen opened — `quran_screen.dart:57` |
| `surah_opened` | `surah_name: String`, `page: int` | Individual surah view opened — `quran_surah_scroll_screen.dart:60` |
| `continue_reading_clicked` | `surah_name: String` | "Continue reading" tapped — `quran_screen.dart:172` |
| `reading_session_completed` | `minutes: int`, `pages: int` | **Defined but not called** in current code |

### Dua & Zikr

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `dua_opened` | `dua_category: String` | Dua reader opened — `dua_reader_screen.dart:57` |
| `dua_favorited` | `dua_name: String` | Dua favorited — `dua_reader_screen.dart:74` |
| `zikr_completed` | `zikr_name: String`, `count: int` | Dhikr session completed — `dhikr_provider.dart:167` |

### Prayer

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `prayer_reminder_opened` | `prayer_name: String` | **Defined but not called** in current code |
| `qibla_opened` | *(none)* | Qibla screen opened — `qibla_screen.dart:33` |

### Community

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `leaderboard_opened` | *(none)* | Leaderboard screen opened — `leaderboard_screen.dart:48` |
| `activity_feed_opened` | *(none)* | **Defined but not called** in current code |
| `community_opened` | *(none)* | Community screen opened — `community_screen.dart:46` |

### Badges

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `badge_unlocked` | `badge_name: String` | New badge unlocked after submission — `amal_provider.dart:587` |
| `badge_viewed` | `badge_name: String` | Badge celebration overlay shown — `badge_celebration_overlay.dart:83` |

### Notifications

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `notification_opened` | `type: String` | Notification tapped — `notifications_screen.dart:320` |
| `announcement_opened` | `announcement_id: String` | Announcement modal displayed — `announcement_modal.dart:26` |

### Settings

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `language_changed` | `language: String` (`'en'` / `'bn'`) | Language switched in settings — `settings_screen.dart:505,526` |
| `anonymous_mode_changed` | `enabled: bool` | Anonymous mode toggled — `settings_screen.dart:57` |

### Search

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `search_used` | `section: String` (`'quran'` / `'dua'`) | Search text entered — `quran_screen.dart:139`, `dua_screen.dart:337` |

### Reports

| Event Name | Parameters | Trigger |
|------------|-----------|---------|
| `reports_opened` | *(none)* | Reports screen opened — `reports_screen.dart:54` |
| `report_period_changed` | `type: String` (`weekly` / `monthly` / `custom`) | Period tab changed — `reports_screen.dart:72,160` |
| `report_shared` | `type: String` | Report shared via share sheet — `reports_screen.dart:222` |

---

## Non-Fatal Error Recording (Crashlytics)

All via `AnalyticsService.instance.recordError(error, stackTrace, reason: ...)`.

| Reason | File | Line |
|--------|------|------|
| `GoRouter redirect failed — Firestore unavailable` | `app_redirect.dart` | 67 |
| `FCM token sync failed` | `notification_service.dart` | 289 |
| `Notification reschedule failed` | `notification_service.dart` | 465 |
| `Amal submit failed` | `amal_provider.dart` | 514 |
| `Report load failed` | `report_provider.dart` | 210 |
| `Report share failed` | `reports_screen.dart` | 224 |
| `Quran audio playback failed` | `quran_audio_provider.dart` | 103 |
| `Google signOut cleanup failed` | `auth_service.dart` | 22 |
| `Google disconnect cleanup failed` | `auth_service.dart` | 27 |
| `Hadith asset load failed` | `hadith_asset_service.dart` | 28 |

---

## Fatal Error Capture (main.dart)

| Handler | Target |
|---------|--------|
| `FlutterError.onError` | `FirebaseCrashlytics.instance.recordFlutterFatalError` — catches framework errors |
| `PlatformDispatcher.instance.onError` | `FirebaseCrashlytics.instance.recordError(error, stack, fatal: true)` — catches Dart isolate errors |

---

## Unused / Defined-But-Not-Still-Called Events

| Method | Status |
|--------|--------|
| `logReadingSessionCompleted(minutes, pages)` | Defined in `analytics_service.dart:171` — **no call sites** |
| `logPrayerReminderOpened(prayerName)` | Defined in `analytics_service.dart:208` — **no call sites** |
| `logActivityFeedOpened()` | Defined in `analytics_service.dart:227` — **no call sites** |
| `setNotificationEnabled(enabled)` | Defined in `analytics_service.dart:45` — **no call sites** |

---

*Generated from source code. Last audit: 2026-07-13*
