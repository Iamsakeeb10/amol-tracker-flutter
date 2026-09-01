class AppConstants {
  const AppConstants._();

  // Bangladesh is fixed UTC+6 (no DST).
  static const String bdTimezone = 'Asia/Dhaka';
  static const double bdLatitude = 23.8103;
  static const double bdLongitude = 90.4125;

  // Global Hijri day correction used app-wide.
  // -1 means show one Hijri day earlier than raw package conversion.
  static const int hijriDayAdjustment = 0;

  /// Content version of the home logging-reminder card. Bump this whenever the
  /// reminder message changes so the card reappears once for every user,
  /// including those who dismissed an earlier version.
  /// 1 = original Maghrib-to-Maghrib notice, 2 = midnight-to-midnight change notice.
  static const int loggingReminderVersion = 2;
}
