import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../router/routes.dart';
import 'hadith_asset_service.dart';
import 'local_storage_service.dart';

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
  static const String quietFromHourKey = 'quiet_from_hour';
  static const String quietFromMinuteKey = 'quiet_from_min';
  static const String quietToHourKey = 'quiet_to_hour';
  static const String quietToMinuteKey = 'quiet_to_min';

  static const int _morningId = 600;
  static const int _eveningId = 630;
  static const int _streakId = 2200;
  static const int _jumuahId = 800;
  static const int _hadithMorningBaseId = 710;
  static const int _hadithEveningBaseId = 740;
  static const int _hadithDaysAhead = 7;
  static const TimeOfDay _hadithMorningTime = TimeOfDay(hour: 7, minute: 0);
  static const TimeOfDay _hadithEveningTime = TimeOfDay(hour: 20, minute: 0);

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  List<String> _hadithList = const [];

  bool _initialized = false;
  StreamSubscription<String>? _onTokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  void Function(String route)? _onDeepLink;

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
    await _loadHadith();

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final localPayload = launchDetails?.notificationResponse?.payload;
    if (localPayload != null && localPayload.isNotEmpty) {
      _dispatchDeepLink(localPayload);
    }

    await _setupFcm();
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

  Future<void> _syncFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log(
        'FCM sync skipped: no logged in user',
        name: 'NotificationService',
      );
      return;
    }
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      developer.log(
        'FCM sync failed: token is null/empty for uid=${user.uid}',
        name: 'NotificationService',
      );
      return;
    }
    final preview = token.substring(0, token.length > 14 ? 14 : token.length);
    developer.log(
      'FCM token fetched uid=${user.uid} tokenPrefix=$preview',
      name: 'NotificationService',
    );
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final userSnap = await userRef.get();
    if (!userSnap.exists) {
      developer.log(
        'FCM sync deferred: user doc not created yet for uid=${user.uid}',
        name: 'NotificationService',
      );
      return;
    }
    await userRef.set({'fcmToken': token}, SetOptions(merge: true));
    developer.log(
      'FCM token saved to Firestore for uid=${user.uid}',
      name: 'NotificationService',
    );
  }

  Future<void> scheduleAll() async {
    await cancelLocalSchedules();
    if (isMorningEnabled) await _scheduleMorning();
    if (isEveningEnabled) await _scheduleEvening();
    if (isStreakEnabled) await _scheduleStreakWarning();
    await _scheduleJumuah();
    await _scheduleHadithNotifications();
  }

  Future<void> _safeRescheduleAll() async {
    try {
      await scheduleAll();
    } catch (_) {
      // Never crash app startup due to platform scheduling quirks.
    }
  }

  Future<void> _ensureLocalNotificationPermission() async {
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
  }

  Future<void> rescheduleAll() async {
    await scheduleAll();
  }

  Future<void> cancelLocalSchedules() async {
    await _localNotifications.cancel(_morningId);
    await _localNotifications.cancel(_eveningId);
    await _localNotifications.cancel(_streakId);
    await _localNotifications.cancel(_jumuahId);
    for (var i = 0; i < _hadithDaysAhead; i++) {
      await _localNotifications.cancel(_hadithMorningBaseId + i);
      await _localNotifications.cancel(_hadithEveningBaseId + i);
    }
  }

  Future<void> setMorningEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifMorningKey, enabled);
    await scheduleAll();
  }

  Future<void> setMorningTime(TimeOfDay value) async {
    await LocalStorageService.setPref(notifMorningHourKey, value.hour);
    await LocalStorageService.setPref(notifMorningMinuteKey, value.minute);
    await scheduleAll();
  }

  Future<void> setEveningEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifEveningKey, enabled);
    await scheduleAll();
  }

  Future<void> setEveningTime(TimeOfDay value) async {
    await LocalStorageService.setPref(notifEveningHourKey, value.hour);
    await LocalStorageService.setPref(notifEveningMinuteKey, value.minute);
    await scheduleAll();
  }

  Future<void> setStreakEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifStreakKey, enabled);
    await scheduleAll();
  }

  Future<void> setCommunityEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifCommunityKey, enabled);
    if (enabled) {
      await _messaging.subscribeToTopic('community_activity');
    } else {
      await _messaging.unsubscribeFromTopic('community_activity');
    }
  }

  bool get isMorningEnabled =>
      LocalStorageService.getPref<bool>(notifMorningKey, true);
  TimeOfDay get morningTime => TimeOfDay(
    hour: LocalStorageService.getPref<int>(notifMorningHourKey, 6),
    minute: LocalStorageService.getPref<int>(notifMorningMinuteKey, 0),
  );
  bool get isEveningEnabled =>
      LocalStorageService.getPref<bool>(notifEveningKey, true);
  TimeOfDay get eveningTime => TimeOfDay(
    hour: LocalStorageService.getPref<int>(notifEveningHourKey, 18),
    minute: LocalStorageService.getPref<int>(notifEveningMinuteKey, 30),
  );
  bool get isStreakEnabled =>
      LocalStorageService.getPref<bool>(notifStreakKey, true);
  bool get isCommunityEnabled =>
      LocalStorageService.getPref<bool>(notifCommunityKey, true);

  TimeOfDay get quietFrom => TimeOfDay(
    hour: LocalStorageService.getPref<int>(quietFromHourKey, 21),
    minute: LocalStorageService.getPref<int>(quietFromMinuteKey, 0),
  );

  TimeOfDay get quietTo => TimeOfDay(
    hour: LocalStorageService.getPref<int>(quietToHourKey, 6),
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
    await scheduleAll();
  }

  bool _isSuppressedByQuietHours(TimeOfDay scheduled) {
    final from = quietFrom.hour * 60 + quietFrom.minute;
    final to = quietTo.hour * 60 + quietTo.minute;
    final value = scheduled.hour * 60 + scheduled.minute;
    if (from == to) return false;
    if (from < to) return value >= from && value < to;
    return value >= from || value < to;
  }

  Future<void> _scheduleMorning() async {
    final at = morningTime;
    if (_isSuppressedByQuietHours(at)) return;
    if (_isCurrentMinute(at)) {
      await _localNotifications.show(
        _morningId + 100000,
        'সকালের নোটিফিকেশন',
        'আজকের আমল দিয়ে দিন শুরু করুন।',
        _notificationDetails(payload: AppRoutes.home),
        payload: AppRoutes.home,
      );
    }
    await _safeZonedSchedule(
      id: _morningId,
      title: 'সকালের নোটিফিকেশন',
      body: 'আজকের আমল দিয়ে দিন শুরু করুন।',
      scheduledDate: _nextInstanceForRecurring(at),
      payload: AppRoutes.home,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleEvening() async {
    final at = eveningTime;
    if (_isSuppressedByQuietHours(at)) return;
    await _safeZonedSchedule(
      id: _eveningId,
      title: 'সন্ধ্যার নোটিফিকেশন',
      body: 'সন্ধ্যার আযকার ও কুরআন তিলাওয়াত মিস করবেন না।',
      scheduledDate: _nextInstanceForRecurring(at),
      payload: AppRoutes.home,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleStreakWarning() async {
    const at = TimeOfDay(hour: 22, minute: 0);
    if (_isSuppressedByQuietHours(at)) return;
    await _safeZonedSchedule(
      id: _streakId,
      title: 'স্ট্রিক সতর্কতা',
      body: 'আজকের লগ এখনো না দিলে এখনই সাবমিট করুন, স্ট্রিক ধরে রাখুন।',
      scheduledDate: _nextInstanceForRecurring(at),
      payload: AppRoutes.home,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleJumuah() async {
    const at = TimeOfDay(hour: 8, minute: 0);
    if (_isSuppressedByQuietHours(at)) return;
    await _safeZonedSchedule(
      id: _jumuahId,
      title: 'জুমআর অনুপ্রেরণা',
      body: 'মুবারক জুমআ। আজ আমলে দৃঢ় থাকুন।',
      scheduledDate: _nextWeeklyInstance(DateTime.friday, at),
      payload: AppRoutes.home,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> _loadHadith() async {
    _hadithList = await HadithAssetService.loadHadithTexts();
  }

  Future<void> _scheduleHadithNotifications() async {
    if (_hadithList.isEmpty) return;
    final now = tz.TZDateTime.now(tz.local);
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
        title: 'আজকের হাদীস (সকাল)',
        hadith: hadith,
      );
      await _scheduleHadithForTime(
        id: _hadithEveningBaseId + i,
        date: day,
        at: _hadithEveningTime,
        title: 'আজকের হাদীস (রাত)',
        hadith: hadith,
      );
    }
  }

  Future<void> _scheduleHadithForTime({
    required int id,
    required tz.TZDateTime date,
    required TimeOfDay at,
    required String title,
    required String hadith,
  }) async {
    if (_isSuppressedByQuietHours(at)) return;
    final scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      at.hour,
      at.minute,
    );
    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _safeZonedSchedule(
      id: id,
      title: title,
      body: hadith,
      scheduledDate: scheduledDate,
      payload: AppRoutes.notifications,
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
    final details = _notificationDetails(payload: payload);
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
    } catch (e) {
      developer.log(
        'FlutterTimezone failed.',
        name: 'NotificationService',
        error: e,
      );
    }
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

  NotificationDetails _notificationDetails({required String payload}) {
    return NotificationDetails(
      android: const AndroidNotificationDetails(
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
        fullScreenIntent: true,
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
    final now = tz.TZDateTime.now(tz.local);
    return now.hour == time.hour && now.minute == time.minute;
  }

  tz.TZDateTime _nextInstance(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
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
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
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

  void _onLocalResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _dispatchDeepLink(payload);
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
      default:
        return AppRoutes.notifications;
    }
  }

  void _dispatchDeepLink(String route) {
    _onDeepLink?.call(route);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'নতুন নোটিফিকেশন';
    final body = notification?.body ?? '';
    final route = _routeFromMessage(message);
    final id =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    await _localNotifications.show(
      id,
      title,
      body,
      _notificationDetails(payload: route),
      payload: route,
    );
  }
}
