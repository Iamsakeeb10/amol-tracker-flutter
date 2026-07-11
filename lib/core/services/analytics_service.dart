import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final _analytics = FirebaseAnalytics.instance;
  final _crashlytics = FirebaseCrashlytics.instance;

  /// In debug mode all analytics / crashlytics calls become no-ops so
  /// the Firebase console stays clean during development.
  bool get _enabled => kReleaseMode;

  // ---------------------------------------------------------------------------
  // Crashlytics setup
  // ---------------------------------------------------------------------------

  void setUserIdentifier(String uid) {
    if (!_enabled) return;
    unawaited(_crashlytics.setUserIdentifier(uid));
  }

  Future<void> setCustomKeys({
    required String appVersion,
    required String buildNumber,
    required String language,
    required String deviceLocale,
  }) async {
    if (!_enabled) return;
    await _crashlytics.setCustomKey('app_version', appVersion);
    await _crashlytics.setCustomKey('build_number', buildNumber);
    await _crashlytics.setCustomKey('language', language);
    await _crashlytics.setCustomKey('device_locale', deviceLocale);
  }

  Future<void> setAnonymousMode(bool enabled) async {
    if (!_enabled) return;
    await _crashlytics.setCustomKey('anonymous_mode', enabled);
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    if (!_enabled) return;
    await _crashlytics.setCustomKey('notification_enabled', enabled);
  }

  void setLastScreen(String screen) {
    if (!_enabled) return;
    unawaited(_crashlytics.setCustomKey('last_screen', screen));
  }

  void setLastFeature(String feature) {
    if (!_enabled) return;
    unawaited(_crashlytics.setCustomKey('last_feature', feature));
  }

  // ---------------------------------------------------------------------------
  // Generic event
  // ---------------------------------------------------------------------------

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: name, parameters: params);
  }

  // ---------------------------------------------------------------------------
  // Non-fatal error recording
  // ---------------------------------------------------------------------------

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    if (!_enabled) return;
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Named convenience events — only the important ones
  // ---------------------------------------------------------------------------

  // -- Onboarding --
  Future<void> logOnboardingCompleted({required int duration}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {'duration': duration},
    );
  }

  Future<void> logLanguageSelected({required String language}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'language_selected',
      parameters: {'language': language},
    );
  }

  // -- Daily Amal --
  Future<void> logAmalCompleted({required int score}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'amal_completed',
      parameters: {'score': score},
    );
  }

  Future<void> logDailyScoreCompleted({required int totalScore}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'daily_score_completed',
      parameters: {'total_score': totalScore},
    );
  }

  Future<void> logStreakExtended({required int streakDays}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'streak_extended',
      parameters: {'streak_days': streakDays},
    );
  }

  Future<void> logStreakLost({required int previousStreak}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'streak_lost',
      parameters: {'previous_streak': previousStreak},
    );
  }

  Future<void> logStreakFreezeUsed({required int streakDays}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'streak_freeze_used',
      parameters: {'streak_days': streakDays},
    );
  }

  // -- Quran --
  Future<void> logQuranOpened() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'quran_opened');
  }

  Future<void> logSurahOpened({required String name, required int page}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'surah_opened',
      parameters: {'surah_name': name, 'page': page},
    );
  }

  Future<void> logContinueReadingClicked({required String surahName}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'continue_reading_clicked',
      parameters: {'surah_name': surahName},
    );
  }

  Future<void> logReadingSessionCompleted({
    required int minutes,
    required int pages,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'reading_session_completed',
      parameters: {'minutes': minutes, 'pages': pages},
    );
  }

  // -- Dua & Zikr --
  Future<void> logDuaOpened({required String category}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'dua_opened',
      parameters: {'dua_category': category},
    );
  }

  Future<void> logDuaFavorited({required String name}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'dua_favorited',
      parameters: {'dua_name': name},
    );
  }

  Future<void> logZikrCompleted({required String name, required int count}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'zikr_completed',
      parameters: {'zikr_name': name, 'count': count},
    );
  }

  // -- Prayer --
  Future<void> logPrayerReminderOpened({required String prayerName}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'prayer_reminder_opened',
      parameters: {'prayer_name': prayerName},
    );
  }

  Future<void> logQiblaOpened() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'qibla_opened');
  }

  // -- Community --
  Future<void> logLeaderboardOpened() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'leaderboard_opened');
  }

  Future<void> logActivityFeedOpened() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'activity_feed_opened');
  }

  Future<void> logCommunityOpened() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'community_opened');
  }

  // -- Badges --
  Future<void> logBadgeUnlocked({required String name}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'badge_unlocked',
      parameters: {'badge_name': name},
    );
  }

  Future<void> logBadgeViewed({required String name}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'badge_viewed',
      parameters: {'badge_name': name},
    );
  }

  // -- Notifications --
  Future<void> logNotificationOpened({required String type}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'notification_opened',
      parameters: {'type': type},
    );
  }

  Future<void> logAnnouncementOpened({required String announcementId}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'announcement_opened',
      parameters: {'announcement_id': announcementId},
    );
  }

  // -- Settings --
  Future<void> logLanguageChanged({required String language}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {'language': language},
    );
  }

  Future<void> logAnonymousModeChanged({required bool enabled}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'anonymous_mode_changed',
      parameters: {'enabled': enabled},
    );
  }

  // -- Search --
  Future<void> logSearchUsed({required String section}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'search_used',
      parameters: {'section': section},
    );
  }

  // -- Reports --
  Future<void> logReportsOpened() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'reports_opened');
  }

  Future<void> logReportPeriodChanged({required String type}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'report_period_changed',
      parameters: {'type': type},
    );
  }

  Future<void> logReportShared({required String type}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'report_shared',
      parameters: {'type': type},
    );
  }
}
