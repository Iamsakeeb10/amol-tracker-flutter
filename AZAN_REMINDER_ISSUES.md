I am having a problem is that when app kill one first attempt the azan reminder working but in second time not working when I customize time13:44Claude responded: This is a classic Flutter local notifications bug.This is a classic Flutter local notifications bug. The problem is almost certainly notification ID collision — when you reschedule with a "customized time," you're generating the same ID as before but the old notification is still registered, or you're not properly cancelling before rescheduling.
Most Likely Causes

1. Not Cancelling Before Rescheduling
   dart// ❌ Wrong — just scheduling again with same ID
   await \_scheduleOne(id: sameId, ...);

// ✅ Correct — cancel first, then reschedule
await flutterLocalNotificationsPlugin.cancel(sameId);
await \_scheduleOne(id: sameId, ...); 2. ID Overflow / Collision
Android notification IDs are 32-bit integers. If your ID generation produces a number too large, it silently wraps and collides.
dart// ❌ Can overflow
int \_notifId(DateTime date, String prayer) {
return int.parse('${date.year}${date.month}${date.day}$prayerIndex');
// e.g. 2026609 0 = too large risk
}

// ✅ Safe compact ID
int \_notifId(DateTime date, String prayer) {
final dayOfYear = date.difference(DateTime(date.year)).inDays;
return (dayOfYear \* 5) + prayerIndex; // max ~1825, always safe
} 3. Custom Offset Not Being Persisted
If user sets "10 minutes before Fajr" but that offset isn't saved to Hive before app kill:
dart// Save offset to Hive immediately on change
await settingsBox.put('fajr_offset_minutes', offsetMinutes);

// Then read from Hive when scheduling
final offset = settingsBox.get('fajr_offset_minutes', defaultValue: 0);
final adjustedTime = prayerTime.add(Duration(minutes: offset));

Full Fix Pattern
dartFuture<void> rescheduleAllAzanNotifications() async {
// Step 1: Cancel ALL existing azan notifications
await cancelAllAzanNotifications();

// Step 2: Read fresh settings from Hive (survives app kill)
final settings = settingsBox.get('azan_settings');

// Step 3: Reschedule from scratch
await scheduleAzanNotifications(settings: settings);
}

Future<void> cancelAllAzanNotifications() async {
// Cancel by known ID range instead of cancelAll()
// (cancelAll removes ALL notifications including other types)
for (int day = 0; day < 30; day++) {
for (int prayer = 0; prayer < 5; prayer++) {
final id = (day \* 5) + prayer;
await flutterLocalNotificationsPlugin.cancel(id);
}
}
}

Debug Checklist
Add this to quickly verify what's actually scheduled:
dartFuture<void> debugPendingNotifications() async {
final pending = await flutterLocalNotificationsPlugin
.pendingNotificationRequests();
for (final n in pending) {
debugPrint('ID: ${n.id} | Title: ${n.title} | Payload: ${n.payload}');
}
debugPrint('Total pending: ${pending.length}');
}
Call this right after rescheduling — if you see 0 or the count doesn't match expected, you know scheduling itself is failing silently.

Most Likely Root Cause for Your Specific Bug
Since it works on first attempt but not second, the pattern is:

First launch → schedules correctly ✅
User customizes time → app saves offset but calls scheduleOne without cancelling old one
App killed → on relaunch, old notification (without offset) fires, new one with offset never gets scheduled because ID conflict was silently ignored

The fix: always cancel → then schedule, never just schedule again.

#ISSUE 2

I have added azan reminder in flutter app with flutter local notification but the problem is when user internet is offline the reminder not works. How to make it work offline also?

13:38
This is a common issue with azan reminders. The root cause is likely that your app is fetching prayer times from an API at notification scheduling time, and when offline, that fetch fails so nothing gets scheduled.

The fix is to calculate prayer times locally using the adhan package (which you're already using in Amol Tracker).

The Strategy
Pre-calculate and schedule all notifications for the next 7–30 days at once
Store the schedule locally (Hive) so you never need internet
Reschedule in background whenever internet becomes available
Implementation

1. Calculate & Schedule Locally
   dart
   import 'package:adhan/adhan.dart';
   import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> scheduleAzanNotifications({int daysAhead = 30}) async {
final prefs = await getStoredPrayerSettings(); // lat, lng, madhab, etc.
final coordinates = Coordinates(prefs.lat, prefs.lng);
final params = prefs.calculationMethod.getParameters();

for (int i = 0; i < daysAhead; i++) {
final date = DateTime.now().add(Duration(days: i));
final dateComponents = DateComponents.from(date);
final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    final prayers = {
      'Fajr': prayerTimes.fajr,
      'Dhuhr': prayerTimes.dhuhr,
      'Asr': prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
      'Isha': prayerTimes.isha,
    };

    for (final entry in prayers.entries) {
      await _scheduleOne(
        id: _notifId(date, entry.key),
        title: '${entry.key} Azan',
        scheduledTime: entry.value,
      );
    }

}
}

int \_notifId(DateTime date, String prayer) {
final prayerIndex = ['Fajr','Dhuhr','Asr','Maghrib','Isha'].indexOf(prayer);
// Unique ID: MMDDP format (e.g. 060901 = June 9, Fajr)
return int.parse(
'${date.month.toString().padLeft(2,'0')}'
    '${date.day.toString().padLeft(2,'0')}'
'$prayerIndex'
);
} 2. Schedule the Notification
dart
Future<void> \_scheduleOne({
required int id,
required String title,
required DateTime scheduledTime,
}) async {
if (scheduledTime.isBefore(DateTime.now())) return;

await flutterLocalNotificationsPlugin.zonedSchedule(
id,
title,
'Time for prayer 🕌',
tz.TZDateTime.from(scheduledTime, tz.local),
const NotificationDetails(
android: AndroidNotificationDetails(
'azan_channel',
'Azan Reminders',
sound: RawResourceAndroidNotificationSound('azan'), // your custom sound
importance: Importance.max,
),
),
androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
uiLocalNotificationDateInterpretation:
UILocalNotificationDateInterpretation.absoluteTime,
);
} 3. Trigger Rescheduling
Call scheduleAzanNotifications() in these places:

dart
// main.dart — on every app launch
await scheduleAzanNotifications();

// When user changes location or calculation method
onSettingsChanged(() => scheduleAzanNotifications());

// WorkManager background task (reschedule weekly)
Workmanager().registerPeriodicTask(
'reschedule-azan',
'rescheduleAzan',
frequency: const Duration(days: 7),
);
Key Points
adhan does pure math — no internet needed, ever
Schedule 30 days ahead to stay well within Android's 500-notification limit (5 prayers × 30 days = 150)
Always pass androidScheduleMode: exactAllowWhileIdle — this is what you already fixed for the AOT release bug, same principle
Store lat/lng in Hive locally so location is also available offline
Since you already use adhan in Amol Tracker, you can likely lift the prayer time logic directly from there.
