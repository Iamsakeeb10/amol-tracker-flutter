import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../router/routes.dart';
import 'local_storage_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String notifMorningKey = 'notif_morning';
  static const String notifEveningKey = 'notif_evening';
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
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;
  StreamSubscription<String>? _onTokenRefreshSub;
  void Function(String route)? _onDeepLink;

  Future<void> initialize({void Function(String route)? onDeepLink}) async {
    _onDeepLink = onDeepLink;
    if (_initialized) {
      await _safeRescheduleAll();
      return;
    }

    tz_data.initializeTimeZones();
    // Product docs target Bangladesh users; enforce Dhaka timezone for schedules.
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onLocalResponse,
    );
    await _ensureLocalNotificationPermission();

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

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _dispatchDeepLink(_routeFromMessage(message));
    });
  }

  Future<void> dispose() async {
    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = null;
  }

  Future<void> _syncFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    // Keep token synced on user doc for Cloud Function push targeting.
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  Future<void> scheduleAll() async {
    await cancelLocalSchedules();
    if (isMorningEnabled) await _scheduleMorning();
    if (isEveningEnabled) await _scheduleEvening();
    if (isStreakEnabled) await _scheduleStreakWarning();
    await _scheduleJumuah();
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
    }
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> rescheduleAll() async {
    await scheduleAll();
  }

  Future<void> cancelLocalSchedules() async {
    await _localNotifications.cancel(id: _morningId);
    await _localNotifications.cancel(id: _eveningId);
    await _localNotifications.cancel(id: _streakId);
    await _localNotifications.cancel(id: _jumuahId);
  }

  Future<void> setMorningEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifMorningKey, enabled);
    await scheduleAll();
  }

  Future<void> setEveningEnabled(bool enabled) async {
    await LocalStorageService.setPref(notifEveningKey, enabled);
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
  bool get isEveningEnabled =>
      LocalStorageService.getPref<bool>(notifEveningKey, true);
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

  String get quietHoursLabel =>
      '${_timeLabel(quietFrom)} — ${_timeLabel(quietTo)}';

  String _timeLabel(TimeOfDay value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
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
    const at = TimeOfDay(hour: 6, minute: 0);
    if (_isSuppressedByQuietHours(at)) return;
    await _safeZonedSchedule(
      id: _morningId,
      title: 'Morning notification',
      body: 'Start your day with today\'s amal.',
      scheduledDate: _nextInstance(at),
      payload: AppRoutes.home,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleEvening() async {
    const at = TimeOfDay(hour: 18, minute: 30);
    if (_isSuppressedByQuietHours(at)) return;
    await _safeZonedSchedule(
      id: _eveningId,
      title: 'Evening notification',
      body: 'Don\'t miss your evening azkar and Quran.',
      scheduledDate: _nextInstance(at),
      payload: AppRoutes.home,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleStreakWarning() async {
    const at = TimeOfDay(hour: 22, minute: 0);
    if (_isSuppressedByQuietHours(at)) return;
    await _safeZonedSchedule(
      id: _streakId,
      title: 'Streak warning',
      body:
          'If you have not logged today yet, submit now to keep your streak alive.',
      scheduledDate: _nextInstance(at),
      payload: AppRoutes.home,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleJumuah() async {
    const at = TimeOfDay(hour: 8, minute: 0);
    if (_isSuppressedByQuietHours(at)) return;
    await _safeZonedSchedule(
      id: _jumuahId,
      title: 'Jumu\'ah motivation',
      body: 'Blessed Friday. Keep your amal strong today.',
      scheduledDate: _nextWeeklyInstance(DateTime.friday, at),
      payload: AppRoutes.home,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    required DateTimeComponents matchDateTimeComponents,
  }) async {
    final details = _notificationDetails(payload: payload);
    await _localNotifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      matchDateTimeComponents: matchDateTimeComponents,
      // Use inexact mode for broad device compatibility without exact scheduling permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  NotificationDetails _notificationDetails({required String payload}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'amal_tracker_daily',
        'Daily Notifications',
        channelDescription: 'Daily and weekly notifications for amal logging',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(threadIdentifier: payload),
    );
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
}
