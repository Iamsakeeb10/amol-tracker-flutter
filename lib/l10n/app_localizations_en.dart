// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Amol Tracker';

  @override
  String get settings => 'Settings';

  @override
  String get notificationsSection => 'NOTIFICATIONS';

  @override
  String get privacySection => 'PRIVACY';

  @override
  String get appSection => 'APP';

  @override
  String get languageSection => 'LANGUAGE';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get bangla => 'বাংলা';

  @override
  String get morningNotification => 'Morning notification';

  @override
  String get morningNotificationTime => '06:00 each morning';

  @override
  String get eveningNotification => 'Evening notification';

  @override
  String get eveningNotificationTime => '06:30 each evening';

  @override
  String get streakWarning => 'Streak warning';

  @override
  String get streakWarningSubtitle => 'When you risk losing your streak';

  @override
  String get communityActivity => 'Community activity';

  @override
  String get communityActivitySubtitle => 'Push updates from community';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String get showOnLeaderboard => 'Show me on leaderboard';

  @override
  String get showAnonymous => 'Show as anonymous in community';

  @override
  String get showAnonymousSubtitle => 'Hide your real name and photo';

  @override
  String get calendarType => 'Calendar type';

  @override
  String get hijri => 'Hijri';

  @override
  String get ramadanMode => 'Ramadan mode';

  @override
  String get ramadanModeSubtitle => 'Adjust schedule and notifications';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get more => 'MORE';

  @override
  String get account => 'Account';

  @override
  String get devMenu => 'Dev menu';

  @override
  String get profile => 'Profile';

  @override
  String get viewProfile => 'View profile';

  @override
  String get exploreSection => 'EXPLORE';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get weekly => 'Weekly';

  @override
  String get notifications => 'Notifications';

  @override
  String get profileAndBadges => 'Profile & badges';

  @override
  String get preferencesSection => 'PREFERENCES';

  @override
  String get emptyDevSection => 'EMPTY / DEV';

  @override
  String get emptyStatePreview => 'Empty state preview';

  @override
  String get devMenuAllScreens => 'Dev menu (all screens)';

  @override
  String get quietHoursDescription =>
      'Notifications stay silent during these hours. Notification schedules still run.';

  @override
  String get from => 'FROM';

  @override
  String get to => 'TO';

  @override
  String silentFromTo(Object from, Object to) {
    return 'Silent from $from to $to';
  }

  @override
  String hoursSilence(Object hours) {
    return '$hours hours of silence';
  }

  @override
  String hoursMinutesSilence(Object hours, Object minutes) {
    return '$hours h $minutes m of silence';
  }

  @override
  String get save => 'Save';

  @override
  String get alerts => 'Alerts';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get failedLoadNotifications => 'Failed to load notifications.';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(Object hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(Object days) {
    return '${days}d ago';
  }

  @override
  String get welcome => 'Welcome';

  @override
  String get today => 'TODAY';

  @override
  String get noAmalLoggedYet => 'No amal logged yet';

  @override
  String get freshStartMessage =>
      'Today\'s a fresh start. Tick off your first amal - even one counts.';

  @override
  String get logTodayAmal => 'Log today\'s amal';

  @override
  String get joinCommunity => 'Join the community';

  @override
  String get joinCommunitySubtitle =>
      'See today\'s community sheet and stay motivated with everyone\'s progress.';

  @override
  String get openCommunity => 'Open community';

  @override
  String get signInTagline => 'Daily devotion, with brothers';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get continueTerms => 'By continuing you agree to our Terms & Privacy.';

  @override
  String googleSignInFailed(Object error) {
    return 'Google sign-in failed: $error';
  }

  @override
  String guestSignInFailed(Object error) {
    return 'Guest sign-in failed: $error';
  }

  @override
  String get skip => 'Skip';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get getStarted => 'Get started';

  @override
  String get next => 'Next';

  @override
  String get buildDailyHabitTitle => 'Build a daily habit';

  @override
  String get buildDailyHabitBody =>
      'Track 9 daily amal - fard, sunnah, azkar, Quran. Tiny, consistent steps.';

  @override
  String get streaksKeepYouGoingTitle => 'Streaks keep you going';

  @override
  String get streaksKeepYouGoingBody =>
      'Don\'t break the chain. Hit 7, 30, 100 days - earn your khair.';

  @override
  String get setupProfileTitle => 'Set up your profile';

  @override
  String get setupProfileBody =>
      'Set your name and privacy before joining the community.';

  @override
  String get starter => 'Starter';

  @override
  String get habit => 'Habit';

  @override
  String get devoted => 'Devoted';

  @override
  String get displayName => 'Display name';

  @override
  String get yourName => 'Your name';

  @override
  String get showAnonymousCommunity => 'Show as Anonymous in community';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String onboardingFailed(Object error) {
    return 'Could not complete onboarding: $error';
  }

  @override
  String get anonymous => 'Anonymous';

  @override
  String get user => 'User';

  @override
  String get daily => 'Daily';

  @override
  String get streak => 'Streak';

  @override
  String get historyDays => 'days';

  @override
  String get pointsAbbr => 'pts';

  @override
  String get you => 'you';

  @override
  String get leaderboardBeFirstToday => 'Be the first to log today!';

  @override
  String leaderboardYourRank(Object rank, Object score, Object stat) {
    return 'Your rank: #$rank · $score $stat';
  }

  @override
  String get leaderboardLoadFailed => 'Could not load leaderboard right now.';

  @override
  String get leaderboardNudgeKeepClimbing =>
      'Keep climbing - every amal counts.';

  @override
  String get leaderboardNudgeTop => 'You are on top - stay consistent.';

  @override
  String leaderboardNudgeBehindDays(Object behind) {
    return '$behind days behind 2nd place - keep your streak alive.';
  }

  @override
  String leaderboardNudgeBehindPoints(Object behind) {
    return '$behind pts behind 2nd place - log today to close the gap.';
  }

  @override
  String get history => 'HISTORY';

  @override
  String get historyLoadFailed => 'Could not load history.';

  @override
  String historyConsistency(Object value) {
    return '$value% consistency';
  }

  @override
  String get historyLoggedDays => 'Logged days';

  @override
  String historyOfDays(Object days) {
    return 'of $days days';
  }

  @override
  String get historyAvgScore => 'Avg score';

  @override
  String get historyNoLogsYet => 'no logs yet';

  @override
  String get historyThisMonth => 'this month';

  @override
  String get historyBestStreak => 'Best streak';

  @override
  String get historyStartLogging => 'Start logging to build your history';

  @override
  String get historyWeakestAmal => 'Weakest amal';

  @override
  String historyWeakestAmalDetail(Object label, Object days) {
    return '$label - missed $days days this month';
  }

  @override
  String get historyFull => 'Full';

  @override
  String get historyPartial => 'Partial';

  @override
  String get historyMiss => 'Miss';

  @override
  String get dayDetailTitle => 'Day detail';

  @override
  String get dayDetailLoadFailed => 'Could not load this day.';

  @override
  String get readOnly => 'READ-ONLY';

  @override
  String get score => 'Score';

  @override
  String get outOf100 => 'of 100';

  @override
  String get dayDetailStreakThatDay => 'Streak that day';

  @override
  String get dayDetailNotStored => 'not stored';

  @override
  String get amal => 'Amal';

  @override
  String get dayDetailNoLogForDay => 'No log was submitted for this Hijri day.';

  @override
  String get dayDetailLockedPastDays => 'Locked - past days cannot be edited.';

  @override
  String memberSince(Object year) {
    return 'Member since $year';
  }

  @override
  String get best => 'Best';

  @override
  String get avg => 'Avg';

  @override
  String get thisWeek => 'This week';

  @override
  String get anonymousEnabled => 'Anonymous enabled';

  @override
  String get realNameVisible => 'Real name visible';

  @override
  String get badges => 'Badges';

  @override
  String get communityUpper => 'COMMUNITY';

  @override
  String get community => 'Community';

  @override
  String get sheet => 'Sheet';

  @override
  String get feed => 'Feed';

  @override
  String get offlineShowingLatest => 'Offline - showing latest available data.';

  @override
  String get date => 'DATE';

  @override
  String get searchByName => 'Search by name';

  @override
  String get logTodayToAppear => 'Log today to appear here';

  @override
  String get noLogsForDay => 'No logs recorded for this day';

  @override
  String get noMoreRows => 'No more rows';

  @override
  String get unableLoadActivityFeed => 'Unable to load activity feed.';

  @override
  String get noActivityYet =>
      'No activity yet. Community updates will appear here.';

  @override
  String get userProfile => 'User Profile';

  @override
  String get profileUnavailable => 'This profile is unavailable.';

  @override
  String get communityMember => 'Community member';

  @override
  String get selected => 'Selected';

  @override
  String get todaysAmal => 'Today\'s amal';

  @override
  String amalOnDate(Object date) {
    return 'Amal on $date';
  }

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get profileSettings => 'Profile settings';

  @override
  String get saving => 'Saving...';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get sending => 'Sending...';

  @override
  String get sendDua => 'Send Dua';

  @override
  String get alreadySentDuaToday => 'You already sent a dua today';

  @override
  String get communityMemberSentDua => 'A community member sent you a dua 🤲';

  @override
  String duaFromSender(Object name) {
    return '$name sent you a dua 🤲';
  }

  @override
  String get duaSent => 'Dua sent ✓';

  @override
  String get noRecentLogs => 'No recent logs available.';

  @override
  String get friendsUpper => 'FRIENDS';

  @override
  String get together => 'Together';

  @override
  String get invite => 'Invite';

  @override
  String get activityFeed => 'ACTIVITY FEED';

  @override
  String get yourGroup => 'YOUR GROUP';

  @override
  String get manage => 'MANAGE';

  @override
  String groupMembersDesc(Object count, Object desc) {
    return '$count brothers · $desc';
  }

  @override
  String get viewSheetArrow => 'View sheet →';

  @override
  String get done => 'done';

  @override
  String get pending => 'pending';

  @override
  String get inviteAndJoin => 'Invite & Join';

  @override
  String get yourInviteCode => 'YOUR INVITE CODE';

  @override
  String get inviteCodeValid => 'Valid · 5 brothers can join';

  @override
  String get inviteCodeCopied => 'Invite code copied';

  @override
  String get copyCode => 'Copy code';

  @override
  String get shareLink => 'Share link';

  @override
  String get joinGroupUpper => 'JOIN A GROUP';

  @override
  String get enterInviteCode => 'Enter invite code';

  @override
  String get joinedMock => 'Joined (mock)';

  @override
  String get joinGroup => 'Join group';

  @override
  String get friend => 'Friend';

  @override
  String get topScorer => 'Top scorer';

  @override
  String get duaSentMock => 'Dua sent (mock)';

  @override
  String get remove => 'Remove';

  @override
  String get group => 'Group';

  @override
  String get admin => 'admin';

  @override
  String get inviteCodeUpper => 'INVITE CODE';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get refresh => 'Refresh';

  @override
  String get members => 'MEMBERS';

  @override
  String get groupSettings => 'GROUP SETTINGS';

  @override
  String get publicLeaderboard => 'Public leaderboard';

  @override
  String get publicLeaderboardSubtitle => 'Show ranks to all members';

  @override
  String get quietHoursActive => 'Quiet hours active';

  @override
  String get quietHoursActiveSubtitle => 'Mute notifications at night';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteThisGroup => 'Delete this group?';

  @override
  String get deleteGroupWarning =>
      'Members will lose access. This cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String dayStreak(Object days) {
    return '$days day streak';
  }

  @override
  String get groupSheet => 'Group Sheet';

  @override
  String allActiveToday(Object count) {
    return 'All $count active today';
  }

  @override
  String get groupStreak => 'group streak';

  @override
  String get groupAvg => 'Group avg';

  @override
  String get memberUpper => 'MEMBER';

  @override
  String get numericLegend => 'Numeric (Fard, Takbir)';

  @override
  String get homeOfflineSyncMessage =>
      'Offline - your log is saved on this device and will sync when you reconnect.';

  @override
  String get loggedToday => 'Logged today ✓';

  @override
  String get markAllDone => 'Mark all done';

  @override
  String get submitTodaysLog => 'Submit today\'s log';

  @override
  String get welcomeUpper => 'WELCOME';

  @override
  String get firstAmalStartsToday => 'Your first amal starts today.';

  @override
  String get onFire => 'on fire';

  @override
  String bestStreakKeepGoing(Object days) {
    return 'Best: $days days · keep it going';
  }

  @override
  String get todaysProgress => 'Today\'s progress';

  @override
  String scoreOutOfPoints(Object score, Object max) {
    return '$score / $max points';
  }

  @override
  String get outOf100Compact => '/100';

  @override
  String get weekdayMon => 'M';

  @override
  String get weekdayTue => 'T';

  @override
  String get weekdayWed => 'W';

  @override
  String get weekdayThu => 'T';

  @override
  String get weekdayFri => 'F';

  @override
  String get weekdaySat => 'S';

  @override
  String get weekdaySun => 'S';

  @override
  String get dayCompleteSubtitle => 'You completed today\'s amal.';

  @override
  String pointsEarned(Object points) {
    return '+$points pts earned';
  }

  @override
  String get hadithOfDay => 'HADITH OF THE DAY';

  @override
  String get todaysSummary => 'Today\'s summary';

  @override
  String get backToHome => 'Back to home';

  @override
  String pointsValue(Object points) {
    return '$points pts';
  }

  @override
  String get tapScreenToJump => 'Tap a screen to jump to it (UI testing)';

  @override
  String get badgeThreeDaysTitle => '3-Day Streak';

  @override
  String get badgeThreeDaysDesc => 'Complete amal for 3 consecutive days.';

  @override
  String get badgeSevenDaysTitle => '7-Day Streak';

  @override
  String get badgeSevenDaysDesc => 'Complete amal for 7 consecutive days.';

  @override
  String get badgeFourteenDaysTitle => '14-Day Streak';

  @override
  String get badgeFourteenDaysDesc => 'Complete amal for 14 consecutive days.';

  @override
  String get badgeThirtyDaysTitle => '30-Day Streak';

  @override
  String get badgeThirtyDaysDesc => 'Complete amal for 30 consecutive days.';

  @override
  String get badgeSixtyDaysTitle => '60-Day Streak';

  @override
  String get badgeSixtyDaysDesc => 'Complete amal for 60 consecutive days.';

  @override
  String get badgeHundredDaysTitle => '100-Day Streak';

  @override
  String get badgeHundredDaysDesc => 'Complete amal for 100 consecutive days.';

  @override
  String get badgeTopCommunityTitle => 'Top of Community';

  @override
  String get badgeTopCommunityDesc =>
      'Rank #1 on the global weekly leaderboard.';

  @override
  String get badgePerfectWeekTitle => 'Perfect Week';

  @override
  String get badgePerfectWeekDesc => 'Score 80+ for 7 consecutive days.';
}
