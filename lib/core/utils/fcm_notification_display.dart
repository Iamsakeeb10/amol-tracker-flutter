import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../router/routes.dart';

/// Shared FCM → local notification display (foreground + background isolate).
class FcmNotificationDisplay {
  FcmNotificationDisplay._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static final Map<String, int> _recentIds = <String, int>{};

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static bool shouldSkipDuplicate(RemoteMessage message) {
    final dedupeKey = _dedupeKey(message);
    if (dedupeKey.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _recentIds[dedupeKey];
    if (last != null && now - last < 10000) return true;
    _recentIds[dedupeKey] = now;
    if (_recentIds.length > 50) {
      _recentIds.removeWhere((_, at) => now - at > 10000);
    }
    return false;
  }

  static Future<void> show(RemoteMessage message) async {
    if (shouldSkipDuplicate(message)) return;
    await ensureInitialized();

    final content = _contentFor(message);
    if (content.body.isEmpty) return;

    await _plugin.show(
      _localIdFor(message),
      content.title,
      content.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'amal_tracker_daily',
          'দৈনিক নোটিফিকেশন',
          channelDescription:
              'আমল লগ করার জন্য দৈনিক ও সাপ্তাহিক নোটিফিকেশন',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(content.body),
        ),
        iOS: DarwinNotificationDetails(
          threadIdentifier: content.route,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: content.route,
    );
  }

  static _FcmContent _contentFor(RemoteMessage message) {
    final notification = message.notification;
    final rawType =
        (message.data['type'] ?? message.data['notificationType'] ?? '')
            .toString();
    final dataTitle = (message.data['title'] ?? '').toString().trim();
    final dataMessage = (message.data['message'] ?? '').toString().trim();
    final isDua = rawType == 'dua';

    final title = isDua
        ? 'নতুন দোয়া পেয়েছেন'
        : (dataTitle.isNotEmpty
              ? dataTitle
              : (notification?.title ?? 'নতুন নোটিফিকেশন'));
    final body = isDua
        ? (dataMessage.isNotEmpty ? dataMessage : (notification?.body ?? ''))
        : (dataMessage.isNotEmpty
              ? dataMessage
              : (notification?.body ?? ''));

    return _FcmContent(
      title: title,
      body: body,
      route: _routeFromMessage(message),
    );
  }

  static String _routeFromMessage(RemoteMessage message) {
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
        final courseId = (message.data['courseId'] ?? '').toString();
        final lessonId = (message.data['lessonId'] ?? '').toString();
        if (courseId.isNotEmpty && lessonId.isNotEmpty) {
          return AppRoutes.lessonViewerPath(courseId, lessonId);
        }
        return AppRoutes.syllabus;
      default:
        return AppRoutes.notifications;
    }
  }

  static String _dedupeKey(RemoteMessage message) {
    final notificationId = (message.data['notificationId'] ?? '').toString();
    if (notificationId.isNotEmpty) return notificationId;
    return message.messageId ?? '';
  }

  static int _localIdFor(RemoteMessage message) {
    final key = _dedupeKey(message);
    if (key.isNotEmpty) return key.hashCode;
    return DateTime.now().millisecondsSinceEpoch;
  }
}

class _FcmContent {
  const _FcmContent({
    required this.title,
    required this.body,
    required this.route,
  });

  final String title;
  final String body;
  final String route;
}
