import 'package:flutter/material.dart';

class PrayerAdhanConstants {
  PrayerAdhanConstants._();

  static const List<String> prayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static const Map<String, int> baseNotificationIds = {
    'fajr': 100,
    'dhuhr': 110,
    'asr': 120,
    'maghrib': 130,
    'isha': 140,
  };

  static const Map<String, IconData> prayerIcons = {
    'fajr': Icons.wb_twilight,
    'dhuhr': Icons.wb_sunny_outlined,
    'asr': Icons.wb_cloudy_outlined,
    'maghrib': Icons.nights_stay_outlined,
    'isha': Icons.dark_mode_outlined,
  };

  static const List<int> offsetOptions = [0, -5, -10, -15];
  static const int daysAhead = 7;

  /// Lowest adhan notification id (fajr base).
  static const int minNotificationId = 100;

  /// Highest adhan notification id (isha base + daysAhead - 1).
  static const int maxNotificationId = 146;

  /// Android notification channel for adhan reminders (v2 resets stale channels).
  static const String androidChannelId = 'prayer_adhan_v2';

  static const String androidChannelName = 'নামাযের আযান রিমাইন্ডার';

  static const String androidChannelDescription =
      'প্রতিটি ওয়াক্তের আযানের রিমাইন্ডার';
}
