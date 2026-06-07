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
}
