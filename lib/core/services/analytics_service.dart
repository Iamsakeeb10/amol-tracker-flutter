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
  // Non-fatal error recording & custom logs
  // ---------------------------------------------------------------------------

  void logMessage(String message) {
    if (!_enabled) return;
    unawaited(_crashlytics.log(message));
  }

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

  Future<void> logSpecialTimeToggled({required bool enabled}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'special_time_toggled',
      parameters: {'enabled': enabled},
    );
  }

  Future<void> logGenderSettingsOpened() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'gender_settings_opened');
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

  // ---------------------------------------------------------------------------
  // Advanced analytics — field-level, timing, session, navigation
  // ---------------------------------------------------------------------------

  // -- Amal field-level tracking --
  Future<void> logAmalFieldSubmitted({
    required String fieldId,
    required dynamic value,
    required String dayOfWeek,
    required String hijriMonth,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'amal_field_submitted',
      parameters: {
        'field_id': fieldId,
        'value': value.toString(),
        'day_of_week': dayOfWeek,
        'hijri_month': hijriMonth,
      },
    );
  }

  // -- Submission timing --
  Future<void> logAmalSubmissionTiming({
    required int hourOfDay,
    required int score,
    required bool isLastMinute,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'amal_submission_timing',
      parameters: {
        'hour_of_day': hourOfDay,
        'score': score,
        'is_last_minute': isLastMinute,
      },
    );
  }

  // -- Session without submission --
  Future<void> logSessionWithoutSubmission({
    required int sessionDurationSeconds,
    required bool hadDraftProgress,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'session_without_submission',
      parameters: {
        'duration_seconds': sessionDurationSeconds,
        'had_draft': hadDraftProgress,
      },
    );
  }

  // -- Streak freeze modal --
  Future<void> logStreakFreezeModalAction({
    required int streakLength,
    required String action,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'streak_freeze_modal',
      parameters: {
        'streak_length': streakLength,
        'action': action,
      },
    );
  }

  // -- Community sheet interaction --
  Future<void> logCommunitySheetInteraction({
    required String action,
    required int dateOffset,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'community_sheet_interaction',
      parameters: {
        'action': action,
        'date_offset': dateOffset,
      },
    );
  }

  // -- Report action --
  Future<void> logReportAction({
    required String action,
    required String reportType,
    required int avgScore,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'report_action',
      parameters: {
        'action': action,
        'report_type': reportType,
        'avg_score': avgScore,
      },
    );
  }

  // -- Feature first use --
  Future<void> logFeatureFirstUse({
    required String feature,
    required int daysAfterInstall,
    required String entryPoint,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'feature_first_use',
      parameters: {
        'feature': feature,
        'days_after_install': daysAfterInstall,
        'entry_point': entryPoint,
      },
    );
  }

  // -- Onboarding step --
  Future<void> logOnboardingStep({
    required int step,
    required String action,
    required int timeOnStepSeconds,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'onboarding_step',
      parameters: {
        'step': step,
        'action': action,
        'time_on_step': timeOnStepSeconds,
      },
    );
  }

  // -- Amal edited --
  Future<void> logAmalEdited({
    required int hijriDaysAgo,
    required int fieldsChanged,
    required int scoreDelta,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'amal_edited',
      parameters: {
        'days_ago': hijriDaysAgo,
        'fields_changed': fieldsChanged,
        'score_delta': scoreDelta,
      },
    );
  }

  // -- Widget tapped --
  Future<void> logWidgetTapped({
    required String widgetState,
    required int hourOfDay,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'widget_tapped',
      parameters: {
        'widget_state': widgetState,
        'hour_of_day': hourOfDay,
      },
    );
  }

  // -- Dua sent --
  Future<void> logDuaSent({required bool isAnonymous}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'dua_sent',
      parameters: {'is_anonymous': isAnonymous},
    );
  }

  // -- Announcement action --
  Future<void> logAnnouncementAction({
    required String announcementId,
    required String action,
    required int timeVisibleSeconds,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'announcement_action',
      parameters: {
        'announcement_id': announcementId,
        'action': action,
        'time_visible': timeVisibleSeconds,
      },
    );
  }

  // -- Session end --
  Future<void> logSessionEnd({
    required int durationSeconds,
    required int screensVisited,
    required bool didSubmitAmal,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'session_end',
      parameters: {
        'duration_seconds': durationSeconds,
        'screens_visited': screensVisited,
        'did_submit_amal': didSubmitAmal,
      },
    );
  }

  // -- Screen / feature navigation tracking --
  Future<void> logScreenViewed(String screenName, {String? category}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'screen_viewed',
      parameters: {
        'screen_name': screenName,
        if (category != null) 'category': category,
      },
    );
  }

  Future<void> logFeatureTapped(String feature, {String? screen}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'feature_tapped',
      parameters: {
        'feature': feature,
        if (screen != null) 'screen': screen,
      },
    );
  }

  Future<void> logGenderSelected({required String gender}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'gender_selected',
      parameters: {'gender': gender},
    );
  }

  Future<void> logGenderSkipped() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'gender_skipped');
  }

  // -- Battle Teaser --
  Future<void> logBattleTeaserAction({
    required String action, // impression, yes, no, dismissed
    required String locale,
  }) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'battle_teaser_$action',
      parameters: {'locale': locale},
    );
  }

  // -- Knowledge Battle --
  Future<void> logBattleHomeOpened() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'battle_home_opened');
  }

  Future<void> logBattleCreated({required String topicId, required int maxPlayers}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'battle_created',
      parameters: {'topic_id': topicId, 'max_players': maxPlayers},
    );
  }

  Future<void> logBattleJoined({required String battleCode}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'battle_joined',
      parameters: {'battle_code': battleCode},
    );
  }

  Future<void> logBattleInviteShared({required String battleCode}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'battle_invite_shared',
      parameters: {'battle_code': battleCode},
    );
  }

  Future<void> logBattleStarted({required String battleCode, required int playerCount}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'battle_started',
      parameters: {'battle_code': battleCode, 'player_count': playerCount},
    );
  }

  Future<void> logBattleQuizCompleted({required String battleCode, required int score}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'battle_quiz_completed',
      parameters: {'battle_code': battleCode, 'score': score},
    );
  }

  Future<void> logBattleForfeited({required String battleCode}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'battle_forfeited',
      parameters: {'battle_code': battleCode},
    );
  }

  Future<void> logBattleResultsViewed({required String battleCode}) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'battle_results_viewed',
      parameters: {'battle_code': battleCode},
    );
  }

  // -- User properties --
  Future<void> updateUserProperties({
    required int currentStreak,
    required int totalSubmissions,
    required String locale,
  }) async {
    if (!_enabled) return;
    await _analytics.setUserProperty(
      name: 'streak_tier',
      value: _getStreakTier(currentStreak),
    );
    await _analytics.setUserProperty(
      name: 'total_submissions',
      value: totalSubmissions.toString(),
    );
    await _analytics.setUserProperty(
      name: 'language',
      value: locale,
    );
  }

  String _getStreakTier(int streak) {
    if (streak == 0) return 'none';
    if (streak <= 7) return '1_to_7';
    if (streak <= 14) return '8_to_14';
    if (streak <= 30) return '15_to_30';
    return '30_plus';
  }
}
