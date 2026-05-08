class AppConstants {
  const AppConstants._();

  // Bangladesh is fixed UTC+6 (no DST).
  static const String bdTimezone = 'Asia/Dhaka';
  static const double bdLatitude = 23.8103;
  static const double bdLongitude = 90.4125;

  // Global Hijri day correction used app-wide.
  // -1 means show one Hijri day earlier than raw package conversion.
  static const int hijriDayAdjustment = -1;
}
