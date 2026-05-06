import 'package:blue_leaf_guide/core/constants/daily_messages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
static final NotificationService \_instance = NotificationService.\_internal();
factory NotificationService() => \_instance;
NotificationService.\_internal();

final FlutterLocalNotificationsPlugin \_notifications =
FlutterLocalNotificationsPlugin();

// Notification ID for goal reminders
static const int \_goalReminderNotificationId = 1;

// SharedPreferences keys
static const String \_keyGoalReminderEnabled = 'goal_reminder_enabled';
static const String \_keyReminderHour = 'reminder_hour';
static const String \_keyReminderMinute = 'reminder_minute';

// Add these constants with the existing ones:
static const int \_buildBrandCompleteNotificationId = 2;
static const int \_dailyTaskCompleteNotificationId = 3;
static const int \_roadmapCompleteNotificationId = 4;
static const int \_allRoadmapsCompleteNotificationId = 5;
static const int \_dailyTaskReminderNotificationId =
100; // Base ID for morning
static const int \_dailyTaskReminderEveningNotificationId =
200; // Base ID for evening
static const int \_scheduledDaysCount = 7; // Number of days to pre-schedule
static const int \_newMonthGoalsNotificationId = 8;

static const String \_keyPushNotificationEnabled = 'push_notification_enabled';

Future<void> requestIOSPermissions() async {
final iosPlugin = \_notifications
.resolvePlatformSpecificImplementation<
IOSFlutterLocalNotificationsPlugin >();

    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

}

Future<void> initialize() async {
// Initialize timezone
tz.initializeTimeZones();

    final String timeZoneName = await _getLocalTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android init
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init (NO automatic permissions)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await requestIOSPermissions();

}

/// Get the device's local timezone name
Future<String> \_getLocalTimeZone() async {
// Default to UTC if unable to determine
try {
final now = DateTime.now();
final localOffset = now.timeZoneOffset;

      // Common timezone mappings based on offset
      final offsetHours = localOffset.inHours;

      // This is a simplified approach. For production, consider using
      // flutter_native_timezone package for accurate timezone detection
      final timezoneMap = {
        -5: 'America/New_York',
        -6: 'America/Chicago',
        -7: 'America/Denver',
        -8: 'America/Los_Angeles',
        0: 'Europe/London',
        1: 'Europe/Paris',
        6: 'Asia/Dhaka',
        5: 'Asia/Karachi',
        8: 'Asia/Shanghai',
        9: 'Asia/Tokyo',
      };

      return timezoneMap[offsetHours] ?? 'UTC';
    } catch (e) {
      return 'UTC';
    }

}

/// Handle notification tap
void \_onNotificationTapped(NotificationResponse response) {
// Handle notification tap - navigate to goals screen, etc.
print('Notification tapped: ${response.payload}');
}

/// Schedule daily goal reminder notification
Future<void> scheduleGoalReminder({
required int hour,
required int minute,
}) async {
// CRITICAL: Only schedule if user is authenticated
if (!await \_isUserAuthenticated()) {
print('⚠️ User not authenticated, skipping goal reminder scheduling');
return;
}

    await cancelGoalReminder(); // Cancel any existing notification

    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'goal_reminders',
          'Goal Reminders',
          channelDescription: 'Daily reminders to track your monthly goals',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      _goalReminderNotificationId,
      'Track Your Goals 🎯',
      'Don\'t forget to update your monthly goal progress today!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    print(
      '✅ Goal reminder scheduled for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );

}

/// Calculate the next instance of the specified time
tz.TZDateTime \_nextInstanceOfTime(int hour, int minute) {
final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
tz.TZDateTime scheduledDate = tz.TZDateTime(
tz.local,
now.year,
now.month,
now.day,
hour,
minute,
);

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;

}

/// Cancel goal reminder notification
Future<void> cancelGoalReminder() async {
await \_notifications.cancel(\_goalReminderNotificationId);
print('❌ Goal reminder cancelled');
}

/// Save reminder settings to SharedPreferences
Future<void> saveReminderSettings({
required bool enabled,
required int hour,
required int minute,
}) async {
final prefs = await SharedPreferences.getInstance();
await prefs.setBool(\_keyGoalReminderEnabled, enabled);
await prefs.setInt(\_keyReminderHour, hour);
await prefs.setInt(\_keyReminderMinute, minute);
}

/// Load reminder settings from SharedPreferences
Future<Map<String, dynamic>> loadReminderSettings() async {
final prefs = await SharedPreferences.getInstance();
return {
'enabled': prefs.getBool(\_keyGoalReminderEnabled) ?? false,
'hour': prefs.getInt(\_keyReminderHour) ?? 10,
'minute': prefs.getInt(\_keyReminderMinute) ?? 45,
};
}

/// Save reminder settings to Firestore
Future<void> saveReminderToFirestore({
required String uid,
required bool enabled,
required int hour,
required int minute,
}) async {
try {
await FirebaseFirestore.instance.collection('users').doc(uid).update({
'reminderEnabled': enabled,
'reminderHour': hour,
'reminderMinute': minute,
'reminderUpdatedAt': FieldValue.serverTimestamp(),
});
print('✅ Reminder settings saved to Firestore');
} catch (e) {
print('❌ Error saving to Firestore: $e');
}
}

/// Load reminder settings from Firestore
Future<Map<String, dynamic>?> loadReminderFromFirestore(String uid) async {
try {
final doc = await FirebaseFirestore.instance
.collection('users')
.doc(uid)
.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'enabled': data['reminderEnabled'] ?? false,
          'hour': data['reminderHour'] ?? 10,
          'minute': data['reminderMinute'] ?? 45,
        };
      }
    } catch (e) {
      print('❌ Error loading from Firestore: $e');
    }
    return null;

}

/// Sync reminder settings (Firestore -> Local -> Schedule)
Future<void> syncReminderSettings(String uid) async {
try {
// Load from Firestore
final firestoreSettings = await loadReminderFromFirestore(uid);

      if (firestoreSettings != null) {
        final enabled = firestoreSettings['enabled'] as bool;
        final hour = firestoreSettings['hour'] as int;
        final minute = firestoreSettings['minute'] as int;

        // Save to local storage
        await saveReminderSettings(
          enabled: enabled,
          hour: hour,
          minute: minute,
        );

        // Schedule notification if enabled
        if (enabled) {
          await scheduleGoalReminder(hour: hour, minute: minute);
        } else {
          await cancelGoalReminder();
        }

        print('✅ Reminder settings synced from Firestore');
      }
    } catch (e) {
      print('❌ Error syncing reminder settings: $e');
    }

}

/// Check if user is authenticated (logged in)
Future<bool> \_isUserAuthenticated() async {
return FirebaseAuth.instance.currentUser != null;
}

/// Check if push notifications are enabled
Future<bool> isPushNotificationEnabled() async {
final prefs = await SharedPreferences.getInstance();
return prefs.getBool(\_keyPushNotificationEnabled) ?? true;
}

/// Save push notification setting
Future<void> savePushNotificationEnabled(bool enabled) async {
final prefs = await SharedPreferences.getInstance();
await prefs.setBool(\_keyPushNotificationEnabled, enabled);
if (!enabled) {
\_notifications.cancelAll();
}
}

/// Show immediate notification for Build Brand completion
Future<void> showBuildBrandCompleteNotification(String uid) async {
// Check if push notifications are enabled
final pushEnabled = await isPushNotificationEnabled();
if (!pushEnabled) {
print('❌ Push notifications are disabled');
return;
}

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'build_brand_complete',
          'Build Brand Completion',
          channelDescription:
              'Notifications for Build Brand milestone completion',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _buildBrandCompleteNotificationId,
      'Congratulations! 🎉',
      'You\'ve completed all Build Brand steps. Great job!',
      details,
      payload: 'build_brand_complete',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      uid: uid,
      title: 'Congratulations! 🎉',
      subtitle: 'You\'ve completed all Build Brand steps. Great job!',
      icon: 'assets/icons/svg/bell.svg',
    );

    print('✅ Build Brand completion notification sent');

}

/// Save notification to Firestore
Future<void> \_saveNotificationToFirestore({
required String uid,
required String title,
required String subtitle,
required String icon,
}) async {
try {
await FirebaseFirestore.instance
.collection('users')
.doc(uid)
.collection('notifications')
.add({
'title': title,
'subtitle': subtitle,
'icon': icon,
'timestamp': FieldValue.serverTimestamp(),
'read': false,
});
print('✅ Notification saved to Firestore');
} catch (e) {
print('❌ Error saving notification to Firestore: $e');
}
}

/// Load notifications from Firestore
Future<List<Map<String, dynamic>>> loadNotificationsFromFirestore(
String uid,
) async {
try {
final snapshot = await FirebaseFirestore.instance
.collection('users')
.doc(uid)
.collection('notifications')
.orderBy('timestamp', descending: true)
.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'subtitle': data['subtitle'] ?? '',
          'icon': data['icon'] ?? 'assets/icons/svg/bell.svg',
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'read': data['read'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('❌ Error loading notifications from Firestore: $e');
      return [];
    }

}

/// Mark notification as read
Future<void> markNotificationAsRead(String uid, String notificationId) async {
try {
await FirebaseFirestore.instance
.collection('users')
.doc(uid)
.collection('notifications')
.doc(notificationId)
.update({'read': true});
} catch (e) {
print('❌ Error marking notification as read: $e');
}
}

/// Mark all notifications as read for a user
Future<void> markAllNotificationsAsRead(String uid) async {
try {
final batch = FirebaseFirestore.instance.batch();
final snapshot = await FirebaseFirestore.instance
.collection('users')
.doc(uid)
.collection('notifications')
.where('read', isEqualTo: false)
.get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }

}

/// Get stream of unread notifications count
Stream<int> getUnreadNotificationsCountStream(String uid) {
return FirebaseFirestore.instance
.collection('users')
.doc(uid)
.collection('notifications')
.where('read', isEqualTo: false)
.snapshots()
.map((snapshot) => snapshot.docs.length);
}

Future<void> showDailyTaskCompleteNotification(String uid) async {
// Check if push notifications are enabled
final pushEnabled = await isPushNotificationEnabled();
if (!pushEnabled) {
print('❌ Push notifications are disabled');
return;
}

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_task_complete',
          'Daily Task Completion',
          channelDescription: 'Notifications for daily task completion',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _dailyTaskCompleteNotificationId,
      'Great Job! 🎉',
      'You\'ve completed all your daily tasks today!',
      details,
      payload: 'daily_task_complete',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      uid: uid,
      title: 'Great Job! 🎉',
      subtitle: 'You\'ve completed all your daily tasks today!',
      icon: 'assets/icons/svg/bell.svg',
    );

    print('✅ Daily task completion notification sent');

}

/// Schedule automatic daily task reminders at 8 AM and 8 PM
/// Checks if push notifications are enabled before scheduling
Future<void> scheduleDailyTaskReminder() async {
// CRITICAL: Only schedule if user is authenticated
if (!await \_isUserAuthenticated()) {
print(
'⚠️ User not authenticated, skipping daily task reminder scheduling',
);
return;
}

    final prefs = await SharedPreferences.getInstance();

    // Check if push notifications are enabled
    final pushEnabled = await isPushNotificationEnabled();
    if (!pushEnabled) {
      print(
        '❌ Push notifications are disabled, skipping daily task reminder scheduling',
      );
      return;
    }

    // Cancel all previously scheduled multi-day reminders
    for (int i = 0; i < _scheduledDaysCount; i++) {
      await _notifications.cancel(_dailyTaskReminderNotificationId + i);
      await _notifications.cancel(_dailyTaskReminderEveningNotificationId + i);
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Schedule reminders and cache quotes for the next 7 days
    for (int i = 0; i < _scheduledDaysCount; i++) {
      // Morning (8:00 AM)
      final morningDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        8,
        0,
      ).add(Duration(days: i));
      final morningQuote = DailyMessages.getMessageForDateTime(morningDate);
      await prefs.setString(
        DailyMessages.getCacheKeyForDateTime(morningDate),
        morningQuote,
      );

      if (!morningDate.isBefore(now)) {
        await _scheduleSingleDailyReminder(
          notificationId: _dailyTaskReminderNotificationId + i,
          scheduledDate: morningDate,
          quote: morningQuote,
          timeLabel: 'morning (8:00 AM)',
        );
      }

      // Evening (8:00 PM)
      final eveningDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        20,
        0,
      ).add(Duration(days: i));
      final eveningQuote = DailyMessages.getMessageForDateTime(eveningDate);
      await prefs.setString(
        DailyMessages.getCacheKeyForDateTime(eveningDate),
        eveningQuote,
      );

      if (!eveningDate.isBefore(now)) {
        await _scheduleSingleDailyReminder(
          notificationId: _dailyTaskReminderEveningNotificationId + i,
          scheduledDate: eveningDate,
          quote: eveningQuote,
          timeLabel: 'evening (8:00 PM)',
        );
      }
    }

    print(
      '✅ Daily task reminders scheduled and cached for the next $_scheduledDaysCount days',
    );

}

/// Helper method to schedule a single daily reminder
Future<void> \_scheduleSingleDailyReminder({
required int notificationId,
required tz.TZDateTime scheduledDate,
required String quote,
required String timeLabel,
}) async {
const AndroidNotificationDetails androidDetails =
AndroidNotificationDetails(
'daily_task_reminders',
'Daily Task Reminders',
channelDescription: 'Daily reminders to complete your tasks',
importance: Importance.high,
priority: Priority.high,
icon: '@mipmap/ic_launcher',
);

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      'Daily Task Reminder ✨',
      quote,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // NOTE: matchDateTimeComponents is NOT used here because we schedule
      // individual unique notifications for each specific day.
    );

    print(
      '✅ Daily task reminder scheduled for $timeLabel on ${scheduledDate.toString()}',
    );

}

/// Cancel daily task reminders
Future<void> cancelDailyTaskReminders() async {
for (int i = 0; i < \_scheduledDaysCount; i++) {
await \_notifications.cancel(\_dailyTaskReminderNotificationId + i);
await \_notifications.cancel(\_dailyTaskReminderEveningNotificationId + i);
}
print('❌ Daily task reminders cancelled');
}

/// Show notification for Roadmap completion
Future<void> showRoadmapCompleteNotification(
String uid,
String roadmapTitle,
) async {
// Check if push notifications are enabled
final pushEnabled = await isPushNotificationEnabled();
if (!pushEnabled) {
print('❌ Push notifications are disabled');
return;
}

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'roadmap_complete',
          'Roadmap Completion',
          channelDescription: 'Notifications for roadmap completion',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _roadmapCompleteNotificationId,
      'Milestone Achieved! 🎯',
      'You\'ve completed "$roadmapTitle". Keep up the great work!',
      details,
      payload: 'roadmap_complete',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      uid: uid,
      title: 'Milestone Achieved! 🎯',
      subtitle: 'You\'ve completed "$roadmapTitle". Keep up the great work!',
      icon: 'assets/icons/svg/bell.svg',
    );

    print('✅ Roadmap completion notification sent for: $roadmapTitle');

}

Future<void> showAllRoadmapsCompleteNotification(String uid) async {
// Check if push notifications are enabled
final pushEnabled = await isPushNotificationEnabled();
if (!pushEnabled) {
print('❌ Push notifications are disabled');
return;
}

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'all_roadmaps_complete',
          'All Roadmaps Completion',
          channelDescription: 'Notification when all roadmaps are completed',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _allRoadmapsCompleteNotificationId,
      'Amazing Achievement! 🎉🎯',
      'You\'ve completed all roadmaps! Your dedication is truly inspiring!',
      details,
      payload: 'all_roadmaps_complete',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      uid: uid,
      title: 'Amazing Achievement! 🎉🎯',
      subtitle:
          'You\'ve completed all roadmaps! Your dedication is truly inspiring!',
      icon: 'assets/icons/svg/bell.svg',
    );

    print('✅ All roadmaps completion notification sent');

}

/// Show notification for New Month goal initialization
Future<void> showNewMonthGoalsNotification(String uid, String month) async {
// Check if push notifications are enabled
final pushEnabled = await isPushNotificationEnabled();
if (!pushEnabled) {
print('❌ Push notifications are disabled');
return;
}

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'month_reset',
          'Monthly Goal Resets',
          channelDescription:
              'Notifications for new monthly goal initialization',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final monthName = DateFormat(
      'MMMM',
    ).format(DateFormat('yyyy-MM').parse(month));

    await _notifications.show(
      _newMonthGoalsNotificationId,
      'New Month, New Goals! 🎯',
      'Your goals for $monthName have been set. Let\'s make this month count!',
      details,
      payload: 'month_reset',
    );

    // Save notification to Firestore
    await _saveNotificationToFirestore(
      uid: uid,
      title: 'New Month, New Goals! 🎯',
      subtitle:
          'Your goals for $monthName have been set. Let\'s make this month count!',
      icon: 'assets/icons/svg/bell.svg',
    );

    print('✅ New month notification sent for: $month');

}

/// Cleanup notifications on logout or account deletion
/// Cancels all scheduled notifications and clears notification preferences
Future<void> cleanupOnLogout() async {
try {
print('🧹 Starting notification cleanup...');

      // Cancel ALL scheduled local notifications
      await _notifications.cancelAll();
      print('✅ All scheduled notifications cancelled');

      // Clear notification schedule data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('reminder_enabled');
      await prefs.remove('reminder_hour');
      await prefs.remove('reminder_minute');
      await prefs.remove(_keyGoalReminderEnabled);
      await prefs.remove(_keyReminderHour);
      await prefs.remove(_keyReminderMinute);
      await prefs.remove(_keyPushNotificationEnabled);
      print('✅ Notification preferences cleared');

      print('✅ Notification cleanup completed on logout');
    } catch (e) {
      print('❌ Error during notification cleanup: $e');
    }

}
}
