class AppRoutes {
  AppRoutes._();

  static const launch = '/launch';
  static const signIn = '/sign-in';
  static const onboarding = '/onboarding';

  static const home = '/home';
  static const dayComplete = '/home/day-complete';
  static const emptyState = '/home/empty';

  static const history = '/history';
  /// Path pattern for GoRouter: `/history/day-detail/:date` (`date` = Hijri `YYYY-MM-DD`).
  static const dayDetailPattern = '/history/day-detail/:date';

  static String dayDetailPath(String hijriYyyyMmDd) =>
      '/history/day-detail/$hijriYyyyMmDd';

  static const community = '/community';
  static const userProfile = '/community/user-profile';

  static const more = '/more';
  static const leaderboard = '/leaderboard';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const settings = '/settings';
  static const quietHours = '/settings/quiet-hours';
  static const reminderTimes = '/settings/reminder-times';

  static const dev = '/dev';
}
