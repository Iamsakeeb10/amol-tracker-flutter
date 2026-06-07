import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../constants/prayer_adhan_constants.dart';
import '../utils/prayer_adhan_time_helper.dart';
import 'islamic_date_service.dart';
import 'local_storage_service.dart';

class PrayerAdhanScheduler {
  PrayerAdhanScheduler._();

  static final PrayerAdhanScheduler instance = PrayerAdhanScheduler._();

  static const String offsetKey = 'adhan_offset_minutes';

  static String enabledKey(String prayer) => 'adhan_${prayer}_enabled';
  static String hourKey(String prayer) => 'adhan_${prayer}_hour';
  static String minuteKey(String prayer) => 'adhan_${prayer}_min';

  bool isEnabled(String prayer) =>
      LocalStorageService.getPref<bool>(enabledKey(prayer), false);

  int get offsetMinutes =>
      LocalStorageService.getPref<int>(offsetKey, 0);

  bool hasCustomTime(String prayer) => getCustomTime(prayer) != null;

  TimeOfDay? getCustomTime(String prayer) {
    final hour = LocalStorageService.getPref<int?>(hourKey(prayer), null);
    final minute = LocalStorageService.getPref<int?>(minuteKey(prayer), null);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setEnabled(String prayer, bool value) async {
    await LocalStorageService.setPref(enabledKey(prayer), value);
  }

  Future<void> setOffsetMinutes(int minutes) async {
    await LocalStorageService.setPref(offsetKey, minutes);
  }

  Future<void> setCustomTime(String prayer, TimeOfDay value) async {
    await LocalStorageService.setPref(hourKey(prayer), value.hour);
    await LocalStorageService.setPref(minuteKey(prayer), value.minute);
  }

  Future<void> clearCustomTime(String prayer) async {
    await LocalStorageService.deletePref(hourKey(prayer));
    await LocalStorageService.deletePref(minuteKey(prayer));
  }

  Map<String, bool> get allEnabled {
    return {
      for (final key in PrayerAdhanConstants.prayerKeys)
        key: isEnabled(key),
    };
  }

  Map<String, bool> get allCustomTimeFlags {
    return {
      for (final key in PrayerAdhanConstants.prayerKeys)
        key: hasCustomTime(key),
    };
  }

  Future<void> cancelAll(FlutterLocalNotificationsPlugin plugin) async {
    for (final baseId in PrayerAdhanConstants.baseNotificationIds.values) {
      for (var i = 0; i < PrayerAdhanConstants.daysAhead; i++) {
        await plugin.cancel(baseId + i);
      }
    }
  }

  /*
  Purpose:
  Schedule per-prayer adhan local notifications for the next 7 days.

  Response:
  Void; OS alarm entries created for each enabled prayer/day pair.

  Business Rules:
  - Only enabled prayers are scheduled.
  - Base time is per-prayer custom (Hive) or calculated adhan for that day.
  - Global offset (0, -5, -10, -15 min) shifts the resolved base time.
  - Quiet hours suppress scheduling for that slot.
  - Past times and already-passed day offsets are skipped.
  - Uses custom azan sound on a dedicated Android/iOS channel.

  Flow:
  1. Cancel existing prayer adhan IDs.
  2. Read enabled prayers, custom times, and offset from Hive.
  3. For each of the next 7 Bangladesh calendar days resolve base + offset.
  4. Check quiet hours, skip past times.
  5. zonedSchedule each remaining slot with azan sound.

  Side Effects:
  - Writes nothing; only schedules OS notifications.

  Failure Cases:
  - Platform scheduling errors are swallowed per-slot so other prayers still schedule.
  */
  Future<void> scheduleAll({
    required FlutterLocalNotificationsPlugin localNotifications,
    required TimeOfDay quietFrom,
    required TimeOfDay quietTo,
  }) async {
    final offset = offsetMinutes;
    final now = tz.TZDateTime.now(tz.local);
    final bdNow = IslamicDateService.nowInBD();

    for (var dayOffset = 0;
        dayOffset < PrayerAdhanConstants.daysAhead;
        dayOffset++) {
      final targetDate = DateTime(
        bdNow.year,
        bdNow.month,
        bdNow.day,
      ).add(Duration(days: dayOffset));

      for (final prayer in PrayerAdhanConstants.prayerKeys) {
        if (!isEnabled(prayer)) continue;

        final reminder = PrayerAdhanTimeHelper.reminderTimeForDate(
          prayer: prayer,
          targetDate: targetDate,
          scheduler: this,
        );
        if (_isSuppressedByQuietHours(reminder, quietFrom, quietTo)) {
          continue;
        }

        final scheduledDate = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          reminder.hour,
          reminder.minute,
        );
        if (!scheduledDate.isAfter(now)) continue;

        final baseId = PrayerAdhanConstants.baseNotificationIds[prayer]!;
        final title = _titleFor(prayer, offset, hasCustomTime(prayer));
        const body = 'আযান শুনুন এবং নামাযের জন্য প্রস্তুত হন।';

        await _safeZonedSchedule(
          plugin: localNotifications,
          id: baseId + dayOffset,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
        );
      }
    }
  }

  String _titleFor(String prayer, int offset, bool isCustom) {
    const names = {
      'fajr': 'ফজর',
      'dhuhr': 'যোহর',
      'asr': 'আসর',
      'maghrib': 'মাগরিব',
      'isha': 'ইশা',
    };
    final name = names[prayer] ?? prayer;
    final customSuffix = isCustom ? ' (কাস্টম)' : '';
    if (offset == 0) return '$name নামাযের সময় হয়েছে$customSuffix';
    if (offset < 0) {
      return '$name নামাযের সময় (${offset.abs()} মিনিট আগে)$customSuffix';
    }
    return '$name নামাযের সময় ($offset মিনিট পরে)$customSuffix';
  }

  bool _isSuppressedByQuietHours(
    TimeOfDay scheduled,
    TimeOfDay from,
    TimeOfDay to,
  ) {
    final fromMin = from.hour * 60 + from.minute;
    final toMin = to.hour * 60 + to.minute;
    final value = scheduled.hour * 60 + scheduled.minute;
    if (fromMin == toMin) return false;
    if (fromMin < toMin) return value >= fromMin && value < toMin;
    return value >= fromMin || value < toMin;
  }

  Future<void> _safeZonedSchedule({
    required FlutterLocalNotificationsPlugin plugin,
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    final details = _adhanNotificationDetails(body: body);
    try {
      await plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Never block other prayer slots on a single failure.
    }
  }

  NotificationDetails _adhanNotificationDetails({required String body}) {
    const androidSound = RawResourceAndroidNotificationSound('azan_one');
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_adhan',
        'নামাযের আযান রিমাইন্ডার',
        channelDescription: 'প্রতিটি ওয়াক্তের আযানের রিমাইন্ডার',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: androidSound,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'azan_one.mp3',
        presentBanner: true,
        presentList: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }
}
