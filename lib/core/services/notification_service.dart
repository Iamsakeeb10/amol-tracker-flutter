import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../constants/prayer_adhan_constants.dart';
import '../router/routes.dart';
import '../utils/fcm_notification_display.dart';
import '../utils/quiet_hours_helper.dart';
import 'analytics_service.dart';
import 'hadith_asset_service.dart';
import 'islamic_date_service.dart';
import 'local_storage_service.dart';
import 'notification_message_service.dart';
import 'prayer_adhan_scheduler.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String notifMorningKey = 'notif_morning';
  static const String notifMorningHourKey = 'notif_morning_hour';
  static const String notifMorningMinuteKey = 'notif_morning_min';
  static const String notifEveningKey = 'notif_evening';
  static const String notifEveningHourKey = 'notif_evening_hour';
  static const String notifEveningMinuteKey = 'notif_evening_min';
  static const String notifStreakKey = 'notif_streak';
  static const String notifCommunityKey = 'notif_community';
  static const String notifStudyReviewKey = 'notif_study_review';
  static const String quietFromHourKey = 'quiet_from_hour';
  static const String quietFromMinuteKey = 'quiet_from_min';
  static const String quietToHourKey = 'quiet_to_hour';
  static const String quietToMinuteKey = 'quiet_to_min';

  static const int _morningId = 600;
  static const int _eveningId = 630;
  static const int _streakId = 2200;
  static const int _midnightFallbackId = 2250;
  static const int _jumuahId = 800;
  static const int _ayyamBidId = 840;
  static const int _hadithMorningBaseId = 710;
  static const int _hadithEveningBaseId = 740;
  static const int _lessonReviewBaseId = 3000;
  static const int _lessonReviewIdRange = 500;
  static const int _lessonReviewLookaheadDays = 21;
  static const int _hadithDaysAhead = 7;
  static const int _notificationDaysAhead = 7;
  static const int _smartEveningId = 9001;
  static const int _smartUrgentId = 9002;
  static const TimeOfDay _hadithMorningTime = TimeOfDay(hour: 8, minute: 0);
  static const TimeOfDay _hadithEveningTime = TimeOfDay(hour: 21, minute: 0);
  static const String _lastSentKeyPrefix = 'notif_last_sent_';
  static const String _fcmOwnerUidKey = 'fcm_token_owner_uid';
  static final tz.Location _bdTz = tz.getLocation('Asia/Dhaka');

  static const List<String> _morningBodies = [
    'সকাল শুরু হোক আযকার দিয়ে। আজকের আমলের নিয়ত করো।',
    'আজকের দিনটা আল্লাহর নামে শুরু করো। একটু একটু করেই হয় বড় পরিবর্তন।',
  ];
  static const List<String> _eveningBodies = [
    'দিন শেষ হওয়ার আগে — আজ কি আল্লাহর জন্য কিছু করা হলো?',
    'যে দিন আমল করা হয়, সে দিন কখনো ব্যর্থ নয়। আজ কি করেছ?',
  ];
  static const List<String> _streakBodies = [
    'তোমার স্ট্রিক আজ রাতেই শেষ হয়ে যেতে পারে। এখনো সময় আছে — লগ করো।',
    'ধারাবাহিকতার এই পথটা থেমে যাক না। আজকের আমল এখনই লগ করো।',
  ];
  static const List<String> _midnightBodies = [
    'মাত্র কয়েক মিনিট বাকি। আজকের আমল জমা না দিলে স্ট্রিক যাবে।',
    'এখনো সুযোগ আছে। দ্রুত লগ করো — এক মিনিটও লাগবে না।',
  ];
  static const List<String> _jumuahBodies = [
    'সূরা কাহফ তিলাওয়াত করুন, রাসূল ﷺ-এর প্রতি বেশি বেশি দরূদ পাঠ করুন, দোয়া করুন এবং সময়মতো জুমুআহর সালাতের জন্য প্রস্তুতি নিন। আল্লাহ আপনার আমল কবুল করুন। 🤲',
  ];

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  List<String> _hadithList = const [];

  bool _initialized = false;
  bool _isRescheduling = false;
  bool _pendingReschedule = false;
  StreamSubscription<String>? _onTokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  void Function(String route)? _onDeepLink;

  /// Pending adhan alarms after the most recent [scheduleAll].
  int get lastAdhanPendingCount =>
      PrayerAdhanScheduler.instance.lastPendingCount;

  Future<bool> canScheduleExactAlarms() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.canScheduleExactNotifications() ?? false;
  }

  Future<void> requestExactAlarmsPermission() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestExactAlarmsPermission();
  }

  Future<void> initialize({void Function(String route)? onDeepLink}) async {
    _onDeepLink = onDeepLink;
    if (_initialized) {
      await _safeRescheduleAll();
      return;
    }

    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalResponse,
    );
    await _ensureLocalNotificationPermission();
    await _ensureAdhanNotificationChannel();
    await _loadHadith();

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final localPayload = launchDetails?.notificationResponse?.payload;
    if (localPayload != null && localPayload.isNotEmpty) {
      _dispatchDeepLink(localPayload);
    }

    try {
      await _setupFcm();
    } catch (_) {
      // FCM is network-dependent; adhan scheduling must still proceed.
    }
    await _safeRescheduleAll();
    _initialized = true;
  }

  Future<void> _setupFcm() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _syncFcmToken();
    try {
      await _messaging.subscribeToTopic('all_users');
    } catch (_) {
      // Ignore if topic subscription fails
    }
    
    _onTokenRefreshSub = _messaging.onTokenRefresh.listen(
      (_) => _syncFcmToken(),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _dispatchDeepLink(_routeFromMessage(initialMessage));
    }

    _onMessageSub = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _dispatchDeepLink(_routeFromMessage(message));
    });
  }

  Future<void> dispose() async {
    await _onTokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    _onTokenRefreshSub = null;
    _onMessageSub = null;
    _onMessageOpenedSub = null;
  }

  Future<void> syncFcmTokenNow() async {
    await _syncFcmToken();
  }

  /*
  Purpose:
  Detach this device's FCM token from the signed-in user on logout.

  Response:
  None.

  Business Rules:
  - Removes fcmToken from the current user's Firestore doc.
  - Deletes the local FCM token so pushes stop until next login.

  Flow:
  1. Resolve current Firebase uid.
  2. Delete fcmToken field on users/{uid}.
  3. Call FirebaseMessaging.deleteToken().
  4. Clear local owner tracking pref.

  Side Effects:
  - User doc no longer targets this device for remote push.

  Failure Cases:
  - No signed-in user: only local owner pref is cleared.
  */
  Future<void> clearFcmTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _clearFcmTokenOnUserDoc(user.uid);
    }
    try {
      await _messaging.deleteToken();
    } catch (_) {}
    await LocalStorageService.deletePref(_fcmOwnerUidKey);
  }

  Future<void> _clearFcmTokenOnUserDoc(String uid) async {
    if (uid.isEmpty) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userSnap = await userRef.get();
    if (!userSnap.exists) return;
    await userRef.set(
      <String, dynamic>{'fcmToken': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }

  /*
  Purpose:
  Register this device's FCM token for the active user only.

  Response:
  None.

  Business Rules:
  - One device token must not remain on a previous account doc.
  - Only writes when users/{uid} already exists.

  Flow:
  1. Read current uid + device token.
  2. If another uid owned this device locally, clear its fcmToken.
  3. Save token on the active user doc.
  4. Remember active uid locally for the next switch.

  Side Effects:
  - Updates users/{uid}.fcmToken in Firestore.

  Failure Cases:
  - No auth, missing token, or missing user doc: no-op.
  */
  Future<void> _syncFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final userSnap = await userRef.get();
      if (!userSnap.exists) return;

      final previousOwnerUid = LocalStorageService.getPref<String>(
        _fcmOwnerUidKey,
        '',
      );
      if (previousOwnerUid.isNotEmpty && previousOwnerUid != user.uid) {
        await _clearFcmTokenOnUserDoc(previousOwnerUid);
      }

      await userRef.set({'fcmToken': token}, SetOptions(merge: true));
      await LocalStorageService.setPref(_fcmOwnerUidKey, user.uid);
    } catch (e, st) {
      AnalyticsService.instance.recordError(e, st, reason: 'FCM token sync failed');
    }
  }

  Future<void> scheduleAll() async {
    await cancelLocalSchedules();
    await _cancelUrgencyIfLoggedToday();
    if (isMorningEnabled) {
      await _scheduleAyyamBid();
      await _scheduleMorning();
    }
    if (isEveningEnabled) await _scheduleEveningNoLog();
    if (isStreakEnabled) await _scheduleStreakWarning();
    await _scheduleJumuah();
    await _scheduleHadithNotifications();
    try {
      await PrayerAdhanScheduler.instance.scheduleAll(
        localNotifications: _localNotifications,
        quietFrom: quietFrom,
        quietTo: quietTo,
      );
    } catch (_) {
      // Never block other reminders if adhan scheduling fails.
    }
  }

  /// Smart Duolingo-style reminders that escalate emotionally based on
  /// how many days the user has missed. Call on app open, after submission,
  /// and when app resumes.
  Future<void> scheduleSmartReminders({
    required String uid,
    required int currentStreak,
    required String lastLogDate,
    required String locale,
  }) async {
    // Cancel previous smart reminders
    await _localNotifications.cancel(_smartEveningId);
    await _localNotifications.cancel(_smartUrgentId);

    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    final yesterday = IslamicDateService.shiftStorageByDays(today, -1);
    // After Maghrib the Islamic day rolls forward. A log made before Maghrib
    // sits under yesterday's Islamic date, so check both dates.
    final hasLoggedToday =
        lastLogDate == today || lastLogDate == yesterday;

    // Already logged today — cancel streak warnings too and bail.
    if (hasLoggedToday) {
      await _cancelUrgencyIfLoggedToday();
      return;
    }

    // Calculate days missed from lastLogDate
    int daysMissed = 0;
    if (lastLogDate.isNotEmpty &&
        lastLogDate != today &&
        lastLogDate != yesterday) {
      daysMissed = IslamicDateService.daysBetween(lastLogDate, today).abs();
    }

    // Verify against actual Firestore log entries to catch stale lastLogDate.
    if (daysMissed > 0) {
      final verified = await _countVerifiedMissedDays(
        today: today,
        maxDays: daysMissed,
      );
      if (verified < daysMissed) daysMissed = verified;
    }

    // Both smart reminders are Maghrib-relative so they always fire
    // BEFORE the Islamic day ends, regardless of season.
    final now = tz.TZDateTime.now(_bdTz);
    final todayGregorian = DateTime(now.year, now.month, now.day);
    final maghribTime =
        IslamicDateService.getMaghribTimeForDate(todayGregorian);

    // Smart evening: 30 min before Maghrib (gentle reminder)
    if (isEveningEnabled) {
      final eveningMsg = NotificationMessageService.getMessage(
        NotificationContext(
          currentStreak: currentStreak,
          daysMissed: daysMissed,
          isEveningCheck: true,
          isUrgent: false,
        ),
        locale,
      );
      final eveningTime = maghribTime.subtract(const Duration(minutes: 30));
      final eveningTOD = TimeOfDay(
        hour: eveningTime.hour,
        minute: eveningTime.minute,
      );
      if (!_isSuppressedByQuietHours(eveningTOD)) {
        final scheduled = tz.TZDateTime(
          _bdTz,
          todayGregorian.year,
          todayGregorian.month,
          todayGregorian.day,
          eveningTime.hour,
          eveningTime.minute,
        );
        if (scheduled.isAfter(now)) {
          await _safeZonedSchedule(
            id: _smartEveningId,
            title: eveningMsg.title,
            body: eveningMsg.body,
            scheduledDate: scheduled,
            payload: AppRoutes.home,
            matchDateTimeComponents: null,
          );
        }
      }
    }

    // Smart urgent: 10 min before Maghrib (last chance)
    if (isStreakEnabled) {
      final urgentMsg = NotificationMessageService.getMessage(
        NotificationContext(
          currentStreak: currentStreak,
          daysMissed: daysMissed,
          isEveningCheck: false,
          isUrgent: true,
        ),
        locale,
      );
      final urgentTime = maghribTime.subtract(const Duration(minutes: 10));
      final urgentTOD = TimeOfDay(
        hour: urgentTime.hour,
        minute: urgentTime.minute,
      );
      if (!_isSuppressedByQuietHours(urgentTOD)) {
        final scheduled = tz.TZDateTime(
          _bdTz,
          todayGregorian.year,
          todayGregorian.month,
          todayGregorian.day,
          urgentTime.hour,
          urgentTime.minute,
        );
        if (scheduled.isAfter(now)) {
          await _safeZonedSchedule(
            id: _smartUrgentId,
            title: urgentMsg.title,
            body: urgentMsg.body,
            scheduledDate: scheduled,
            payload: AppRoutes.home,
            matchDateTimeComponents: null,
          );
        }
      }
    }
  }

  Future<void> _cancelUrgencyIfLoggedToday() async {
    // After Maghrib the Hijri date rolls forward to "tomorrow". A log made
    // earlier today (before Maghrib) is stored under hijriPrev, so we must
    // check both dates to correctly suppress pending warnings.
    final hijriNow = IslamicDateService.getCurrentIslamicDateStringSafe();
    final hijriPrev = IslamicDateService.shiftStorageByDays(hijriNow, -1);

    final loggedNow = await _hasLoggedIslamicDate(hijriNow);
    final loggedPrev = await _hasLoggedIslamicDate(hijriPrev);
    if (!loggedNow && !loggedPrev) return;

    await _localNotifications.cancel(_streakId);
    await _localNotifications.cancel(_midnightFallbackId);
    for (var i = 1; i < _notificationDaysAhead; i++) {
      await _localNotifications.cancel(_streakId + i);
      await _localNotifications.cancel(_midnightFallbackId + i);
    }
  }

  Future<void> _safeRescheduleAll() async {
    try {
      await rescheduleAll();
    } catch (e, st) {
      AnalyticsService.instance.recordError(
        e,
        st,
        reason: 'Notification reschedule failed',
      );
    }
  }

  Future<void> _ensureLocalNotificationPermission() async {
    try {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (android != null) {
        await android.requestNotificationsPermission();
        await android.requestExactAlarmsPermission();
      }
      if (ios != null) {
        await ios.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (_) {
      // Permission request can fail during early init when platform context
      // is not yet available. Notifications still work via FCM.
    }
  }

  Future<void> _ensureAdhanNotificationChannel() async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    const androidSound = RawResourceAndroidNotificationSound('azan_one');
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        PrayerAdhanConstants.androidChannelId,
        PrayerAdhanConstants.androidChannelName,
        description: PrayerAdhanConstants.androidChannelDescription,
        importance: Importance.max,
        playSound: true,
        sound: androidSound,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  Future<void> rescheduleAll() async {
    if (_isRescheduling) {
      _pendingReschedule = true;
      return;
    }
    do {
      _pendingReschedule = false;
      _isRescheduling = true;
      try {
        await scheduleAll();
      } finally {
        _isRescheduling = false;
      }
    } while (_pendingReschedule);
  }

  Future<void> cancelLocalSchedules() async {
    await _localNotifications.cancel(_morningId);
    await _localNotifications.cancel(_eveningId);
    await _localNotifications.cancel(_streakId);
    // Cancel additional streak warning IDs for 7-day window
    for (var i = 1; i < 7; i++) {
      await _localNotifications.cancel(_streakId + i);
    }
    await _localNotifications.cancel(_midnightFallbackId);
    // Cancel urgent pre-Maghrib fallback IDs for 7-day window
    for (var i = 1; i < 7; i++) {
      await _localNotifications.cancel(_midnightFallbackId + i);
    }
    await _localNotifications.cancel(_jumuahId);
    await _localNotifications.cancel(_ayyamBidId);
    for (var i = 0; i < _hadithDaysAhead; i++) {
      await _localNotifications.cancel(_hadithMorningBaseId + i);
      await _localNotifications.cancel(_hadithEveningBaseId + i);
    }
    for (var i = 0; i < _lessonReviewIdRange; i++) {
      await _localNotifications.cancel(_lessonReviewBaseId + i);
    }
    await PrayerAdhanScheduler.instance.cancelAll(_localNotifications);
  }

  Future<void> setMorningEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifMorningKey, enabled);
    unawaited(_safeRescheduleAll());
  }

  Future<void> setMorningTime(TimeOfDay value) async {
    await LocalStorageService.setPref(notifMorningHourKey, value.hour);
    await LocalStorageService.setPref(notifMorningMinuteKey, value.minute);
    unawaited(_safeRescheduleAll());
  }

  Future<void> setEveningEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifEveningKey, enabled);
    unawaited(_safeRescheduleAll());
  }

  Future<void> setEveningTime(TimeOfDay value) async {
    await LocalStorageService.setPref(notifEveningHourKey, value.hour);
    await LocalStorageService.setPref(notifEveningMinuteKey, value.minute);
    unawaited(_safeRescheduleAll());
  }

  Future<void> setStreakEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifStreakKey, enabled);
    unawaited(_safeRescheduleAll());
  }

  Future<void> setCommunityEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifCommunityKey, enabled);
    if (enabled) {
      await _messaging.subscribeToTopic('community_activity');
    } else {
      await _messaging.unsubscribeFromTopic('community_activity');
    }
  }

  Future<void> setStudyReviewEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifStudyReviewKey, enabled);
    unawaited(_safeRescheduleAll());
  }

  bool get isMorningEnabled =>
      LocalStorageService.getPref<bool>(notifMorningKey, true);
  TimeOfDay get morningTime => TimeOfDay(
    hour: LocalStorageService.getPref<int>(notifMorningHourKey, 6),
    minute: LocalStorageService.getPref<int>(notifMorningMinuteKey, 30),
  );
  bool get isEveningEnabled =>
      LocalStorageService.getPref<bool>(notifEveningKey, true);
  TimeOfDay get eveningTime {
    final storedHour = LocalStorageService.getPref<int?>(
      notifEveningHourKey,
      null,
    );
    final storedMinute = LocalStorageService.getPref<int?>(
      notifEveningMinuteKey,
      null,
    );

    // If user has customized the time, use their preference
    if (storedHour != null && storedMinute != null) {
      return TimeOfDay(hour: storedHour, minute: storedMinute);
    }

    // Default: Use Maghrib prayer time
    try {
      final maghribTime = IslamicDateService.getMaghribTime();
      return TimeOfDay(hour: maghribTime.hour, minute: maghribTime.minute);
    } catch (_) {
      // Fallback to 5 PM if Maghrib calculation fails
      return const TimeOfDay(hour: 17, minute: 0);
    }
  }

  bool get isStreakEnabled =>
      LocalStorageService.getPref<bool>(notifStreakKey, true);
  bool get isCommunityEnabled =>
      LocalStorageService.getPref<bool>(notifCommunityKey, true);
  bool get isStudyReviewEnabled =>
      LocalStorageService.getPref<bool>(notifStudyReviewKey, true);

  TimeOfDay get quietFrom => TimeOfDay(
    hour: LocalStorageService.getPref<int>(quietFromHourKey, 22),
    minute: LocalStorageService.getPref<int>(quietFromMinuteKey, 30),
  );

  TimeOfDay get quietTo => TimeOfDay(
    hour: LocalStorageService.getPref<int>(quietToHourKey, 5),
    minute: LocalStorageService.getPref<int>(quietToMinuteKey, 0),
  );

  Future<void> setQuietHours({
    required TimeOfDay from,
    required TimeOfDay to,
  }) async {
    await LocalStorageService.setPref(quietFromHourKey, from.hour);
    await LocalStorageService.setPref(quietFromMinuteKey, from.minute);
    await LocalStorageService.setPref(quietToHourKey, to.hour);
    await LocalStorageService.setPref(quietToMinuteKey, to.minute);
    unawaited(_safeRescheduleAll());
  }

  bool _isSuppressedByQuietHours(TimeOfDay scheduled) {
    return QuietHoursHelper.isSuppressed(
      scheduled,
      from: quietFrom,
      to: quietTo,
    );
  }

  tz.TZDateTime _nextTimeOutsideQuietHours(tz.TZDateTime scheduled) {
    final time = TimeOfDay(hour: scheduled.hour, minute: scheduled.minute);
    if (!_isSuppressedByQuietHours(time)) return scheduled;

    var next = tz.TZDateTime(
      _bdTz,
      scheduled.year,
      scheduled.month,
      scheduled.day,
      quietTo.hour,
      quietTo.minute,
    );
    if (!next.isAfter(scheduled)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  int _lessonReviewNotificationId(String courseId, String lessonId) {
    final key = '${courseId}_$lessonId';
    return _lessonReviewBaseId + (key.hashCode.abs() % _lessonReviewIdRange);
  }

  String _categoryLastSentKey(String category) =>
      '$_lastSentKeyPrefix$category';

  String _pickMessage({required String category, required List<String> pool}) {
    final last = LocalStorageService.getPref<String>(
      _categoryLastSentKey(category),
      '',
    );
    for (final message in pool) {
      if (message != last) return message;
    }
    return pool.first;
  }

  Future<void> _markCategoryMessage(String category, String message) async {
    await LocalStorageService.setPref(_categoryLastSentKey(category), message);
  }

  Future<bool> _hasLoggedIslamicDate(String hijriDate) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final docId = '${user.uid}_$hijriDate';
      final doc = await FirebaseFirestore.instance
          .collection('amal_logs')
          .doc(docId)
          .get();
      return doc.exists;
    } catch (_) {
      // Firestore unavailable — assume not logged so we don't suppress
      // a needed reminder. Worst case: duplicate notification, not missed.
      return false;
    }
  }

  /// Walk backwards from yesterday, counting consecutive missing days
  /// by checking actual Firestore log documents. Caps at [maxDays] reads.
  Future<int> _countVerifiedMissedDays({
    required String today,
    required int maxDays,
  }) async {
    if (maxDays <= 0) return 0;
    final checkLimit = maxDays.clamp(0, 7);
    int verifiedMissed = 0;
    String checkDate = today;
    try {
      for (var i = 0; i < checkLimit; i++) {
        checkDate = IslamicDateService.shiftStorageByDays(checkDate, -1);
        if (await _hasLoggedIslamicDate(checkDate)) break;
        verifiedMissed++;
      }
    } catch (_) {
      // Firestore unavailable — return what we have so far
    }
    return verifiedMissed >= checkLimit && maxDays > checkLimit
        ? maxDays
        : verifiedMissed;
  }

  Future<void> _schedulePolicyAware({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    required String category,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
    await _markCategoryMessage(category, body);
  }

  Future<void> _scheduleMorning() async {
    final at = morningTime;
    if (_isSuppressedByQuietHours(at)) return;
    final selectedBody = _pickMessage(
      category: 'morning',
      pool: _morningBodies,
    );
    if (_isCurrentMinute(at)) {
      await _localNotifications.show(
        _morningId + 100000,
        'ফজরের পর — আমলের শুরু',
        selectedBody,
        _notificationDetails(payload: AppRoutes.home, body: selectedBody),
        payload: AppRoutes.home,
      );
    }
    await _schedulePolicyAware(
      id: _morningId,
      title: 'ফজরের পর — আমলের শুরু',
      body: selectedBody,
      scheduledDate: _nextInstanceForRecurring(at),
      payload: AppRoutes.home,
      category: 'morning',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleEveningNoLog() async {
    final hijriDate = IslamicDateService.getCurrentIslamicDateStringSafe();
    final hijriPrev = IslamicDateService.shiftStorageByDays(hijriDate, -1);
    // After Maghrib the Islamic day rolls forward. A log made before Maghrib
    // sits under hijriPrev, so check both dates.
    if (await _hasLoggedIslamicDate(hijriDate)) return;
    if (await _hasLoggedIslamicDate(hijriPrev)) return;
    final at = eveningTime;
    if (_isSuppressedByQuietHours(at)) return;
    final selectedBody = _pickMessage(
      category: 'evening',
      pool: _eveningBodies,
    );
    await _schedulePolicyAware(
      id: _eveningId,
      title: 'আসরের পর — সন্ধ্যার প্রস্তুতি',
      body: selectedBody,
      scheduledDate: _nextInstanceForRecurring(at),
      payload: AppRoutes.home,
      category: 'evening',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleStreakWarning() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // After Maghrib the Hijri date rolls forward. A log made before Maghrib
      // sits under hijriPrev, so check both dates before scheduling warnings.
      final hijriNow = IslamicDateService.getCurrentIslamicDateStringSafe();
      final hijriPrev = IslamicDateService.shiftStorageByDays(hijriNow, -1);
      if (await _hasLoggedIslamicDate(hijriNow)) return;
      if (await _hasLoggedIslamicDate(hijriPrev)) return;

      final now = tz.TZDateTime.now(_bdTz);

      final selectedBody = _pickMessage(
        category: 'streak',
        pool: _streakBodies,
      );
      // Urgent body reuses _midnightBodies — the copy still fits a 5-min warning.
      final urgentBody = _pickMessage(
        category: 'streak_urgent',
        pool: _midnightBodies,
      );

      for (int dayOffset = 0; dayOffset < _notificationDaysAhead; dayOffset++) {
        final targetDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: dayOffset));

        final maghribTime =
            IslamicDateService.getMaghribTimeForDate(targetDate);

        // — Primary warning: 15 min before Maghrib —
        final primaryTime = maghribTime.subtract(const Duration(minutes: 15));
        final primaryTOD = TimeOfDay(
          hour: primaryTime.hour,
          minute: primaryTime.minute,
        );
        if (!_isSuppressedByQuietHours(primaryTOD)) {
          final primaryScheduled = tz.TZDateTime(
            _bdTz,
            targetDate.year,
            targetDate.month,
            targetDate.day,
            primaryTime.hour,
            primaryTime.minute,
          );
          if (primaryScheduled.isAfter(now)) {
            await _schedulePolicyAware(
              id: _streakId + dayOffset,
              title: 'আজকের আমল বাকি আছে!',
              body: selectedBody,
              scheduledDate: primaryScheduled,
              payload: AppRoutes.home,
              category: 'streak',
              matchDateTimeComponents: null,
            );
          }
        }

        // — Urgent warning: 5 min before Maghrib (still within the same Islamic day) —
        // Replaces the old 11:30 PM midnight fallback which fired AFTER the
        // Islamic day had already ended at Maghrib.
        final urgentTime = maghribTime.subtract(const Duration(minutes: 5));
        final urgentTOD = TimeOfDay(
          hour: urgentTime.hour,
          minute: urgentTime.minute,
        );
        if (!_isSuppressedByQuietHours(urgentTOD)) {
          final urgentScheduled = tz.TZDateTime(
            _bdTz,
            targetDate.year,
            targetDate.month,
            targetDate.day,
            urgentTime.hour,
            urgentTime.minute,
          );
          if (urgentScheduled.isAfter(now)) {
            await _schedulePolicyAware(
              id: _midnightFallbackId + dayOffset,
              title: 'দিন শেষ হওয়ার আগে আমল লগ করুন',
              body: urgentBody,
              scheduledDate: urgentScheduled,
              payload: AppRoutes.home,
              category: 'streak_urgent',
              matchDateTimeComponents: null,
            );
          }
        }
      }
    } catch (_) {
      // Fallback to default time (6 PM) if Maghrib calculation fails
      const at = TimeOfDay(hour: 18, minute: 0);
      if (_isSuppressedByQuietHours(at)) return;
      final selectedBody = _pickMessage(
        category: 'streak',
        pool: _streakBodies,
      );
      await _schedulePolicyAware(
        id: _streakId,
        title: 'আজকের আমল বাকি আছে!',
        body: selectedBody,
        scheduledDate: _nextInstanceForRecurring(at),
        payload: AppRoutes.home,
        category: 'streak',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> _scheduleJumuah() async {
    const at = TimeOfDay(hour: 9, minute: 30);
    if (_isSuppressedByQuietHours(at)) return;
    final selectedBody = _pickMessage(category: 'jumuah', pool: _jumuahBodies);
    await _schedulePolicyAware(
      id: _jumuahId,
      title: '🕌 জুমুআহর বরকতময় সময় শুরু হয়েছে',
      body: selectedBody,
      scheduledDate: _nextWeeklyInstance(DateTime.friday, at),
      payload: AppRoutes.home,
      category: 'jumuah',
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }



  Future<void> _scheduleAyyamBid() async {
    final now = DateTime.now();
    final bdNow = IslamicDateService.bangladeshDateTimeFrom(now);
    if (!IslamicDateService.isHijriDay13_14_15(bdNow)) return;
    final at = morningTime;
    if (_isSuppressedByQuietHours(at)) return;
    await _schedulePolicyAware(
      id: _ayyamBidId,
      title: 'আইয়ামে বিয স্মরণ',
      body: 'আইয়ামে বিয — এই তিন দিনের রোযা সুন্নাত। আজকের আমলে যোগ করো।',
      scheduledDate: _nextInstanceForRecurring(at),
      payload: AppRoutes.home,
      category: 'ayyam_bid',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _loadHadith() async {
    _hadithList = await HadithAssetService.loadHadithTexts();
  }

  Future<void> _scheduleHadithNotifications() async {
    if (_hadithList.isEmpty) return;
    final now = tz.TZDateTime.now(_bdTz);
    for (var i = 0; i < _hadithDaysAhead; i++) {
      final day = now.add(Duration(days: i));
      final dayKey =
          DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay;
      final hadith = _hadithList[dayKey % _hadithList.length];
      await _scheduleHadithForTime(
        id: _hadithMorningBaseId + i,
        date: day,
        at: _hadithMorningTime,
        title: 'আজকের হাদীস ☀️',
        hadith: hadith,
        suffix: '— সকালের অনুপ্রেরণা নিন এবং আমলে লেগে থাকুন।',
      );
      await _scheduleHadithForTime(
        id: _hadithEveningBaseId + i,
        date: day,
        at: _hadithEveningTime,
        title: 'রাতের হাদীস 🌙',
        hadith: hadith,
        suffix: '— ঘুমানোর আগে হাদীসের কথা মনে নিয়ে শুন।',
      );
    }
  }

  Future<void> _scheduleHadithForTime({
    required int id,
    required tz.TZDateTime date,
    required TimeOfDay at,
    required String title,
    required String hadith,
    required String suffix,
  }) async {
    if (_isSuppressedByQuietHours(at)) return;
    final scheduledDate = tz.TZDateTime(
      _bdTz,
      date.year,
      date.month,
      date.day,
      at.hour,
      at.minute,
    );
    if (!scheduledDate.isAfter(tz.TZDateTime.now(_bdTz))) return;
    await _schedulePolicyAware(
      id: id,
      title: title,
      body: '$hadith\n$suffix',
      scheduledDate: scheduledDate,
      payload: AppRoutes.notifications,
      category: title.contains('☀️') ? 'hadith_morning' : 'hadith_evening',
      matchDateTimeComponents: null,
    );
  }

  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final details = _notificationDetails(payload: payload, body: body);
    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      // Fall back to inexact when the OS denies exact-alarm permission so
      // scheduling never fails outright.
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      return;
    } catch (_) {}
    try {
      tz.setLocalLocation(tz.getLocation(_offsetMapTimeZone()));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  String _offsetMapTimeZone() {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    const timezoneMap = <int, String>{
      -8: 'America/Los_Angeles',
      -7: 'America/Denver',
      -6: 'America/Chicago',
      -5: 'America/New_York',
      0: 'Europe/London',
      1: 'Europe/Paris',
      5: 'Asia/Karachi',
      6: 'Asia/Dhaka',
      8: 'Asia/Shanghai',
      9: 'Asia/Tokyo',
    };
    return timezoneMap[offsetHours] ?? 'UTC';
  }

  NotificationDetails _notificationDetails({
    required String payload,
    required String body,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'amal_tracker_daily',
        'দৈনিক নোটিফিকেশন',
        channelDescription: 'আমল লগ করার জন্য দৈনিক ও সাপ্তাহিক নোটিফিকেশন',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: DarwinNotificationDetails(
        threadIdentifier: payload,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  bool _isCurrentMinute(TimeOfDay time) {
    final now = tz.TZDateTime.now(_bdTz);
    return now.hour == time.hour && now.minute == time.minute;
  }

  tz.TZDateTime _nextInstance(TimeOfDay time) {
    final now = tz.TZDateTime.now(_bdTz);
    var scheduled = tz.TZDateTime(
      _bdTz,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    final lag = now.difference(scheduled);
    if (lag >= const Duration(minutes: 1)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceForRecurring(TimeOfDay time) {
    final now = tz.TZDateTime.now(_bdTz);
    var scheduled = tz.TZDateTime(
      _bdTz,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextWeeklyInstance(int targetWeekday, TimeOfDay time) {
    var date = _nextInstance(time);
    while (date.weekday != targetWeekday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  ({String title, String body}) _studyReviewNotificationCopy(String lessonTitle) {
    final locale = LocalStorageService.getPref<String>('app_locale', 'bn');
    final label = lessonTitle.trim().isEmpty
        ? (locale.startsWith('bn') ? 'আপনার পাঠ' : 'your lesson')
        : lessonTitle.trim();
    if (locale.startsWith('bn')) {
      return (title: 'অধ্যয়ন অনুস্মারক', body: 'পুনরায় দেখুন: $label');
    }
    return (title: 'Study reminder', body: 'Time to review: $label');
  }

  Future<void> _scheduleLessonReviewReminders() async {
    if (!isStudyReviewEnabled) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('userProgress')
          .doc(user.uid)
          .collection('lessonReviews')
          .get();
      final now = tz.TZDateTime.now(_bdTz);

      for (final doc in snap.docs) {
        final data = doc.data();
        final courseId = (data['courseId'] as String?) ?? '';
        final lessonId = doc.id;
        final nextReviewAt = data['nextReviewAt'];
        if (courseId.isEmpty || lessonId.isEmpty) continue;
        if (nextReviewAt is! Timestamp) continue;

        var scheduled = tz.TZDateTime.from(nextReviewAt.toDate(), _bdTz);
        if (!scheduled.isAfter(now)) {
          scheduled = now.add(const Duration(minutes: 5));
        }
        if (scheduled.isAfter(now.add(const Duration(days: _lessonReviewLookaheadDays)))) {
          continue;
        }
        if (_isSuppressedByQuietHours(
          TimeOfDay(hour: scheduled.hour, minute: scheduled.minute),
        )) {
          scheduled = _nextTimeOutsideQuietHours(scheduled);
          if (scheduled.isAfter(now.add(const Duration(days: _lessonReviewLookaheadDays)))) {
            continue;
          }
        }

        final lessonTitle = ((data['lessonTitle'] as String?) ?? '').trim();
        final copy = _studyReviewNotificationCopy(lessonTitle);
        final payload = AppRoutes.lessonViewerPath(courseId, lessonId);
        final id = _lessonReviewNotificationId(courseId, lessonId);

        await _localNotifications.zonedSchedule(
          id,
          copy.title,
          copy.body,
          scheduled,
          _notificationDetails(payload: payload, body: copy.body),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      }
    } catch (_) {
      // Firestore unavailable — skip lesson review scheduling this cycle.
      // Will be retried on next app resume.
    }
  }

  void _onLocalResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      // Prayer adhan notifications have no payload — check by ID range.
      final id = response.id;
      if (id != null &&
          id >= PrayerAdhanConstants.minNotificationId &&
          id <= PrayerAdhanConstants.maxNotificationId) {
        final prayerName = _prayerNameFromNotificationId(id);
        if (prayerName != null) {
          AnalyticsService.instance.logPrayerReminderOpened(
            prayerName: prayerName,
          );
        }
      }
      return;
    }
    _dispatchDeepLink(payload);
  }

  String? _prayerNameFromNotificationId(int id) {
    for (final entry in PrayerAdhanConstants.baseNotificationIds.entries) {
      if (id >= entry.value && id < entry.value + PrayerAdhanConstants.daysAhead) {
        return entry.key;
      }
    }
    return null;
  }

  String _routeFromMessage(RemoteMessage message) {
    final rawType =
        (message.data['type'] ?? message.data['notificationType'] ?? '')
            .toString();
    switch (rawType) {
      case 'leaderboard':
        return AppRoutes.leaderboard;
      case 'community':
        return AppRoutes.community;
      case 'dua':
        return AppRoutes.notifications;
      case 'badge':
        return AppRoutes.profile;
      case 'log_amal':
      case 'streak_warning':
        return AppRoutes.home;
      case 'syllabus_review':
        final courseId =
            (message.data['courseId'] ?? '').toString();
        final lessonId =
            (message.data['lessonId'] ?? '').toString();
        if (courseId.isNotEmpty && lessonId.isNotEmpty) {
          return AppRoutes.lessonViewerPath(courseId, lessonId);
        }
        return AppRoutes.syllabus;
      default:
        return AppRoutes.notifications;
    }
  }

  void _dispatchDeepLink(String route) {
    _onDeepLink?.call(route);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Data-only admin pushes: show once via shared helper (avoids FCM+local dupes).
    if (message.notification == null) {
      await FcmNotificationDisplay.show(message);
      return;
    }

    final rawType =
        (message.data['type'] ?? message.data['notificationType'] ?? '')
            .toString();
    final isDua = rawType == 'dua';
    final duaMessage = (message.data['message'] ?? '').toString().trim();
    final title = isDua
        ? 'নতুন দোয়া পেয়েছেন'
        : (message.notification?.title ?? 'নতুন নোটিফিকেশন');
    final body = isDua
        ? (duaMessage.isNotEmpty
              ? duaMessage
              : (message.notification?.body ?? ''))
        : (message.notification?.body ?? '');
    final route = _routeFromMessage(message);
    final id =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    await _localNotifications.show(
      id,
      title,
      body,
      _notificationDetails(payload: route, body: body),
      payload: route,
    );
  }
}
