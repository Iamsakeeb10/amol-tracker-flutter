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
  String get morningNotificationTime => '6:00 AM each morning';

  @override
  String get morningNotificationTimeLabel => 'Morning time';

  @override
  String get eveningNotification => 'Evening notification';

  @override
  String get eveningNotificationTime => '6:30 PM each evening';

  @override
  String get eveningNotificationTimeLabel => 'Evening time';

  @override
  String get notificationTimeTapToChange => 'Tap to customize time';

  @override
  String get streakWarning => 'Streak warning';

  @override
  String get streakWarningSubtitle => 'When you risk losing your streak';

  @override
  String get communityActivity => 'Community activity';

  @override
  String get communityActivitySubtitle => 'Push updates from community';

  @override
  String get studyReviewReminder => 'Study review reminders';

  @override
  String get studyReviewReminderSubtitle =>
      'Spaced repetition nudges for enrolled lessons';

  @override
  String get notificationTypeStudyReview => 'Study review';

  @override
  String get reminderTimes => 'Reminder times';

  @override
  String get reminderTimesDescription =>
      'Set the exact reminder time for morning and evening notifications.';

  @override
  String get prayerAdhanReminder => 'Prayer adhan reminder';

  @override
  String get prayerAdhanReminderSubtitle => 'Per-prayer adhan alerts';

  @override
  String get prayerAdhanScreenTitle => 'Prayer adhan reminder';

  @override
  String get prayerAdhanDescription =>
      'Get adhan reminders for each prayer. Times are calculated for Bangladesh.';

  @override
  String get prayerAdhanTodayTimes => 'Today\'s prayer times';

  @override
  String get prayerAdhanReminderTimes => 'Reminder times';

  @override
  String get prayerAdhanReminderTimesDescription =>
      'Tap to set a custom reminder time. Reset to use calculated adhan time for each day.';

  @override
  String get prayerAdhanCalculatedTime => 'Adhan time';

  @override
  String get prayerAdhanCustomTimeLabel => 'Custom time';

  @override
  String get prayerAdhanResetToAdhan => 'Use adhan time';

  @override
  String get prayerAdhanOffsetTitle => 'When should the reminder appear?';

  @override
  String get prayerAdhanAtTime => 'At adhan time';

  @override
  String get prayerAdhanChipAtTime => 'On time';

  @override
  String prayerAdhanChipMinBefore(Object minutes) {
    return '${minutes}m before';
  }

  @override
  String prayerAdhanMinutesBefore(Object minutes) {
    return '$minutes min before';
  }

  @override
  String get prayerAdhanReliabilityTitle => 'Background reminders need setup';

  @override
  String get prayerAdhanReliabilityBody =>
      'Allow exact alarms so adhan reminders fire when the app is closed. Also disable battery optimization for reliable delivery.';

  @override
  String get prayerAdhanAllowExactAlarms => 'Allow exact alarms';

  @override
  String get prayerAdhanDisableBatteryOptimization =>
      'Disable battery optimization';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

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
  String get hijriCalendar => 'Hijri Calendar';

  @override
  String get todayLabel => 'Today';

  @override
  String get islamicEventsTitle => 'ISLAMIC EVENTS';

  @override
  String get eventIslamicNewYear => 'Islamic New Year';

  @override
  String get eventAshura => 'Day of Ashura';

  @override
  String get eventMawlid => 'Mawlid an-Nabi';

  @override
  String get eventIsraMiraj => 'Isra and Mi\'raj';

  @override
  String get eventShabeBarat => 'Shab-e-Barat';

  @override
  String get eventRamadanStart => 'Start of Ramadan';

  @override
  String get eventLaylatAlQadr => 'Laylat al-Qadr';

  @override
  String get eventEidAlFitr => 'Eid al-Fitr';

  @override
  String get eventArafat => 'Day of Arafat';

  @override
  String get eventEidAlAdha => 'Eid al-Adha';

  @override
  String get ramadanMode => 'Ramadan mode';

  @override
  String get ramadanModeSubtitle => 'Adjust schedule and notifications';

  @override
  String get homeWidgetSettingsTitle => 'Home screen widget';

  @override
  String get homeWidgetSettingsSubtitle => 'Add';

  @override
  String get homeWidgetSetupTitle => 'Add home screen widget';

  @override
  String get homeWidgetSetupBody =>
      'Keep today\'s amal progress visible from your home screen.';

  @override
  String get homeWidgetAddButton => 'Add widget';

  @override
  String get homeWidgetUnsupportedMessage =>
      'Direct add is not supported on this launcher.';

  @override
  String get homeWidgetPinRequested =>
      'Widget add request sent. Confirm on your home screen.';

  @override
  String get homeWidgetPinFailed =>
      'Could not start widget add right now. Use manual steps below.';

  @override
  String get homeWidgetIosGuide =>
      'On iPhone: long-press the home screen, tap +, then search \"Amol Tracker\" widget.';

  @override
  String get homeWidgetFallbackSteps =>
      'Manual steps: Long-press home screen -> Widgets -> Amol Tracker -> Add.';

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
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navCommunity => 'Community';

  @override
  String get navDua => 'Dua';

  @override
  String get navMore => 'More';

  @override
  String get quickNavSection => 'Quick Navigation';

  @override
  String get morningEveningDua => 'Morning & Evening Dua';

  @override
  String get duaTitle => 'Duas';

  @override
  String get duaFavoritesTab => 'Favourites';

  @override
  String get duaCategoriesTab => 'Topics';

  @override
  String get duaAllTab => 'All Duas';

  @override
  String get duaSearchHint => 'Search duas...';

  @override
  String get duaReference => 'Reference';

  @override
  String get duaTransliteration => 'Transliteration';

  @override
  String get duaTranslation => 'Translation';

  @override
  String get duaNoFavorites =>
      'No favourites yet.\nTap ★ on any dua to save it.';

  @override
  String get duaNoResults => 'No results found';

  @override
  String get duaFavAdded => 'Added to favourites';

  @override
  String get duaFavRemoved => 'Removed from favourites';

  @override
  String get duaFavAdd => 'Add to favourites';

  @override
  String get duaFavRemove => 'Remove from favourites';

  @override
  String get duaCopy => 'Copy';

  @override
  String get duaShare => 'Share';

  @override
  String get duaCopied => 'Copied to clipboard';

  @override
  String duaPageCounter(int current, int total) {
    return '$current / $total';
  }

  @override
  String get duaReaderOptions => 'Reading options';

  @override
  String get duaReaderTextSize => 'Text size';

  @override
  String get duaReaderTextSizeNormal => 'Normal';

  @override
  String get duaReaderTextSizeMedium => 'Medium';

  @override
  String get duaReaderTextSizeLarge => 'Large';

  @override
  String get duaReaderShowIntroduction => 'Introduction';

  @override
  String get duaReaderShowTransliteration => 'Transliteration';

  @override
  String get duaReaderShowTranslation => 'Translation';

  @override
  String get duaReaderShowReference => 'Reference';

  @override
  String get duaReaderFocusMode => 'Focus mode';

  @override
  String get duaReaderFocusModeExit => 'Exit focus mode';

  @override
  String get duaReaderPrevious => 'Previous dua';

  @override
  String get duaReaderNext => 'Next dua';

  @override
  String get duaReaderMore => 'More options';

  @override
  String get duaReaderTextSizeDecrease => 'Decrease text size';

  @override
  String get duaReaderTextSizeIncrease => 'Increase text size';

  @override
  String routeNotFound(String path) {
    return 'Route not found: $path';
  }

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
  String get monthly => 'Monthly';

  @override
  String get todayTop => 'Today\'s top';

  @override
  String get monthTop => 'Month\'s top';

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
  String get saveFabLabel => 'Save';

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
  String weeksAgo(Object weeks) {
    return '${weeks}w ago';
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
  String leaderboardYourRankNumber(int rank) {
    return 'Your rank: #$rank';
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
  String leaderboardNudgeBehindFirstDays(Object behind) {
    return '$behind days behind 1st place - keep your streak alive.';
  }

  @override
  String leaderboardNudgeBehindFirstPoints(Object behind) {
    return '$behind pts behind 1st place - log today to take the lead.';
  }

  @override
  String get leaderboardQuizTab => 'Quiz';

  @override
  String get leaderboardQuizBeFirst => 'Be the first to pass a quiz!';

  @override
  String leaderboardNudgeBehindQuizPoints(Object behind) {
    return '$behind pts behind 2nd place - pass more quizzes to climb.';
  }

  @override
  String leaderboardNudgeBehindFirstQuizPoints(Object behind) {
    return '$behind pts behind 1st place - pass more quizzes to take the lead.';
  }

  @override
  String get leaderboardQuizAttempts => 'attempts';

  @override
  String leaderboardQuizStat(int points, int attempts) {
    return '$points pts · $attempts attempts';
  }

  @override
  String leaderboardYourRankQuiz(int rank, String stat) {
    return 'Your rank: #$rank · $stat';
  }

  @override
  String get leaderboardQuizTiebreakerHint =>
      'Equal points? Fewer total attempts rank higher.';

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
  String get dayDetailLockedPastDays =>
      'Locked — days before you joined cannot be edited.';

  @override
  String get editDayAmal => 'Edit this day\'s amal';

  @override
  String get dayDetailTodayGoHome => 'Go to Home to log today\'s amal.';

  @override
  String get dayDetailGoToHome => 'Go to Home';

  @override
  String get editTodayAmal => 'Edit today\'s amal';

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
  String get communityMemberSentDua =>
      'কমিউনিটি থেকে কেউ আপনাকে দোয়া পাঠিয়েছে 🤲';

  @override
  String duaFromSender(Object name) {
    return '$name আপনাকে দোয়া পাঠিয়েছেন 🤲';
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
  String get deselectAll => 'Deselect all';

  @override
  String get submitTodaysLog => 'Submit today\'s log';

  @override
  String get saveTodaysAmal => 'Save today\'s amal';

  @override
  String draftSavedTapSaveToFinish(Object saveButton) {
    return 'Draft saved. Tap $saveButton to finish today.';
  }

  @override
  String get completeAllAmalAutoSave =>
      'Complete every amal above to save today.';

  @override
  String get amalAutoSaving => 'Saving today\'s amal…';

  @override
  String get progressAutosavedHint => 'Your progress is auto-saved as draft.';

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

  @override
  String get badgeCourseGraduateTitle => 'Course Graduate';

  @override
  String get badgeCourseGraduateDesc =>
      'Complete all lessons in a syllabus course.';

  @override
  String get exitAppTitle => 'Exit app?';

  @override
  String get exitAppConfirm => 'Have you logged today\'s amal?';

  @override
  String get exitAppStay => 'Stay';

  @override
  String get exitApp => 'Exit';

  @override
  String get dhikrCounter => 'Dhikr Counter';

  @override
  String get subhanAllah => 'SubhanAllah';

  @override
  String get alhamdulillah => 'Alhamdulillah';

  @override
  String get allahuAkbar => 'Allahu Akbar';

  @override
  String dhikrTarget(int count) {
    return 'Target: $count';
  }

  @override
  String get dhikrCount => 'Count';

  @override
  String get dhikrCompleted => 'Completed!';

  @override
  String get dhikrReset => 'Reset';

  @override
  String get dhikrCustom => 'Custom';

  @override
  String get dhikrAddCustom => 'Add custom dhikr';

  @override
  String get dhikrAdd => 'Add';

  @override
  String get dhikrCustomName => 'Dhikr name';

  @override
  String get dhikrCustomTarget => 'Target count';

  @override
  String get dhikrTodaySessions => 'Today\'s completions';

  @override
  String get dhikrNoSessions => 'No dhikr completed yet today.';

  @override
  String get dhikrSelectDhikr => 'Select dhikr';

  @override
  String get dhikrShortcutSubtitle => 'Count SubhanAllah, Alhamdulillah & more';

  @override
  String get dhikrTapToCount => 'Tap to count';

  @override
  String get dhikrNameRequired => 'Please enter a dhikr name.';

  @override
  String get dhikrTargetInvalid => 'Target must be at least 1.';

  @override
  String get dhikrDuplicateName => 'A dhikr with this name already exists.';

  @override
  String get asmaUlHusna => 'Asma ul Husna';

  @override
  String get husnaSubtitle => '99 Names of Allah';

  @override
  String husnaLearnedCount(int learned) {
    return '$learned of 99 learned';
  }

  @override
  String get husnaMarkLearned => 'Mark as Learned';

  @override
  String get husnaMarkNotLearned => 'Unmark';

  @override
  String get husnaQuiz => 'Quiz Mode';

  @override
  String get husnaQuizQuestion => 'Which name has this meaning?';

  @override
  String get husnaQuizCorrect => 'Correct!';

  @override
  String get husnaQuizWrong => 'Incorrect';

  @override
  String husnaQuizScore(int score, int total) {
    return 'Score: $score / $total';
  }

  @override
  String get husnaQuizFinished => 'Quiz Complete';

  @override
  String get husnaNoNamesLearned =>
      'Learn at least 4 names first to unlock quiz';

  @override
  String husnaNumber(int number) {
    return '#$number';
  }

  @override
  String get husnaBenefit => 'Reflection';

  @override
  String get husnaMeaning => 'Meaning';

  @override
  String get husnaNextQuestion => 'Next';

  @override
  String get husnaStartQuiz => 'Start Quiz';

  @override
  String get husnaRetryQuiz => 'Try Again';

  @override
  String get husnaSearch => 'Search names...';

  @override
  String get husnaFilterAll => 'All';

  @override
  String get husnaFilterLearned => 'Learned';

  @override
  String get husnaFilterNotLearned => 'Not Learned';

  @override
  String husnaQuizProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get husnaQuizExcellent => 'Excellent!';

  @override
  String get husnaQuizGoodEffort => 'Good effort!';

  @override
  String get husnaQuizKeepLearning => 'Keep learning!';

  @override
  String get husnaSwipeHint => 'Swipe to see next name';

  @override
  String get husnaPronunciation => 'Pronunciation';

  @override
  String husnaCorrectAnswer(String name) {
    return 'Correct answer: $name';
  }

  @override
  String get announcementDismiss => 'Understood';

  @override
  String get announcementTypeReminder => 'Reminder';

  @override
  String get announcementTypeAnnouncement => 'Announcement';

  @override
  String get announcementTypeDua => 'Dua';

  @override
  String get announcementTypeHadith => 'Hadith';

  @override
  String get adminSectionTitle => 'Admin';

  @override
  String get adminAnnouncementsTitle => 'Announcements';

  @override
  String get adminAmalFieldsTitle => 'Amal Fields';

  @override
  String get adminAmalFieldFormCreate => 'Create amal field';

  @override
  String get adminAmalFieldFormEdit => 'Edit amal field';

  @override
  String get adminAmalFieldId => 'Field ID';

  @override
  String get adminAmalFieldLabelEn => 'Label (English)';

  @override
  String get adminAmalFieldLabelBn => 'Label (Bengali, optional)';

  @override
  String get adminAmalFieldSublabelEn => 'Description (English)';

  @override
  String get adminAmalFieldSublabelBn => 'Description (Bengali, optional)';

  @override
  String get adminAmalFieldPoints => 'Points';

  @override
  String get adminAmalFieldMaxValue => 'Max value';

  @override
  String get adminAmalFieldOrder => 'Display order';

  @override
  String get adminAmalFieldTypeBoolean => 'Yes / No';

  @override
  String get adminAmalFieldTypeNumeric => 'Numeric';

  @override
  String get adminAmalFieldIdRequired => 'Field ID is required.';

  @override
  String get adminAmalFieldIdInvalid =>
      'Use lowercase letters, numbers, and underscores only.';

  @override
  String get adminAmalFieldLabelRequired => 'English label is required.';

  @override
  String get adminAmalFieldPointsInvalid => 'Points must be between 0 and 100.';

  @override
  String get adminAmalFieldMaxValueInvalid => 'Max value must be at least 1.';

  @override
  String get adminAmalFieldOrderInvalid => 'Order must be 0 or greater.';

  @override
  String get adminAmalFieldSaved => 'Amal field saved.';

  @override
  String get adminAmalFieldSaveFailed => 'Could not save amal field.';

  @override
  String get adminAmalFieldToggleFailed => 'Could not update amal field.';

  @override
  String get adminAmalFieldIdImmutable =>
      'Field ID cannot be changed after creation.';

  @override
  String get adminAmalFieldPreviewRequired =>
      'Add an English label to preview.';

  @override
  String get adminAmalFieldEmptyList =>
      'No amal fields yet. Tap + to create one.';

  @override
  String get adminAmalFieldsLoadFailed => 'Could not load amal fields.';

  @override
  String get adminAmalFieldIdentitySection => 'Identity';

  @override
  String get adminAmalFieldLabelsSection => 'Labels';

  @override
  String get adminAmalFieldScoringSection => 'Scoring';

  @override
  String get adminAmalFieldDisplaySection => 'Display';

  @override
  String adminAmalFieldTileSubtitle(
    String id,
    String type,
    String points,
    int order,
  ) {
    return '$id · $type · $points · #$order';
  }

  @override
  String get adminStatusLive => 'Live';

  @override
  String get adminStatusScheduled => 'Scheduled';

  @override
  String get adminStatusExpired => 'Expired';

  @override
  String get adminStatusOff => 'Off';

  @override
  String get adminFormType => 'Type';

  @override
  String get adminFormTitle => 'Title';

  @override
  String get adminFormMessage => 'Message';

  @override
  String get adminFormArabicText => 'Arabic text (optional)';

  @override
  String get adminFormImageUrl => 'Image URL (optional)';

  @override
  String get adminFormActive => 'Active';

  @override
  String get adminFormShowOnce => 'Show once per user';

  @override
  String get adminFormStartsAt => 'Starts at';

  @override
  String get adminFormExpiresAt => 'Expires at';

  @override
  String get adminFormPreview => 'Preview';

  @override
  String get adminFormSave => 'Save';

  @override
  String get adminFormClearDate => 'Clear';

  @override
  String get adminFormCreateTitle => 'Create announcement';

  @override
  String get adminFormEditTitle => 'Edit announcement';

  @override
  String get adminFormTitleRequired => 'Title is required.';

  @override
  String get adminFormMessageRequired => 'Message is required.';

  @override
  String get adminFormSaved => 'Announcement saved.';

  @override
  String get adminDeleteTitle => 'Delete announcement?';

  @override
  String get adminDeleteConfirm => 'This cannot be undone.';

  @override
  String get adminEmptyList => 'No announcements yet. Tap + to create one.';

  @override
  String get adminNotAuthorized => 'You do not have access to this screen.';

  @override
  String get adminLoadFailed => 'Could not load announcements.';

  @override
  String get adminSaveFailed => 'Could not save announcement.';

  @override
  String get adminDeleteFailed => 'Could not delete announcement.';

  @override
  String get adminToggleFailed => 'Could not update announcement.';

  @override
  String get adminDateRangeInvalid => 'Expires at must be after starts at.';

  @override
  String get adminPreviewRequired => 'Add a title and message to preview.';

  @override
  String get adminPushNotificationTitle => 'Push Notification';

  @override
  String get adminPushScreenTitle => 'Send Push';

  @override
  String get adminPushTitle => 'Title';

  @override
  String get adminPushMessage => 'Message';

  @override
  String get adminPushType => 'Type';

  @override
  String get adminPushTypeSyllabusCourse => 'Syllabus course';

  @override
  String get adminPushTypeSyllabusReview => 'Study review';

  @override
  String get adminPushTitleRequired => 'Title is required.';

  @override
  String get adminPushMessageRequired => 'Message is required.';

  @override
  String get adminPushSend => 'Send to all users';

  @override
  String get adminPushSent => 'Notification sent successfully.';

  @override
  String get adminPushFailed => 'Failed to send notification.';

  @override
  String get adminPushGatewayNotConfigured => 'Push gateway not configured.';

  @override
  String get adminPushGatewayKeyMissing =>
      'Gateway key missing. Run with --dart-define=DUA_PUSH_GATEWAY_KEY=your_key';

  @override
  String get adminCoursesTitle => 'Courses';

  @override
  String get adminCourseCreateTitle => 'Create course';

  @override
  String get adminCourseEditTitle => 'Edit course';

  @override
  String get adminCourseEmptyList => 'No courses yet. Tap + to create one.';

  @override
  String get adminCourseLoadFailed => 'Could not load courses.';

  @override
  String get adminCourseDeleteTitle => 'Delete course?';

  @override
  String get adminCourseDeleteFailed => 'Could not delete course.';

  @override
  String get adminCoursePublishFailed => 'Could not update course status.';

  @override
  String get adminCourseFormSaved => 'Course saved.';

  @override
  String get adminCoursePublishedPushTitle => 'New course available';

  @override
  String adminCoursePublishedPushMessage(String title) {
    return 'A new syllabus course is live: $title. Open Syllabus to enroll.';
  }

  @override
  String get adminCourseManageLessons => 'Manage lessons';

  @override
  String get adminCourseDescription => 'Description';

  @override
  String get adminCourseDescriptionRequired => 'Description is required.';

  @override
  String get adminCourseCoverUrl => 'Cover image URL (optional)';

  @override
  String get adminCourseTags => 'Tags (comma-separated)';

  @override
  String get adminCourseModerators => 'Moderator UIDs (comma-separated)';

  @override
  String get adminCourseDetailsSection => 'Course details';

  @override
  String get adminCourseModeratorsSection => 'Moderators';

  @override
  String get adminCourseStatusSection => 'Status';

  @override
  String get adminCourseStatusPublished => 'Published';

  @override
  String get adminCourseStatusDraft => 'Draft';

  @override
  String get adminLessonsTitle => 'Lessons';

  @override
  String get adminLessonsSubtitle =>
      'Drag to reorder lessons. Toggle publish when ready.';

  @override
  String get adminLessonCreateTitle => 'Add lesson';

  @override
  String get adminLessonEditTitle => 'Edit lesson';

  @override
  String get adminLessonEmptyList => 'No lessons yet. Tap + to add one.';

  @override
  String get adminLessonLoadFailed => 'Could not load lessons.';

  @override
  String get adminLessonDeleteTitle => 'Delete lesson?';

  @override
  String get adminLessonDeleteFailed => 'Could not delete lesson.';

  @override
  String get adminLessonReorderFailed => 'Could not save lesson order.';

  @override
  String get adminLessonFormSaved => 'Lesson saved.';

  @override
  String get adminLessonDetailsSection => 'Lesson details';

  @override
  String get adminLessonResourceType => 'Resource type';

  @override
  String get adminLessonTypeYoutube => 'YouTube';

  @override
  String get adminLessonTypePdf => 'PDF';

  @override
  String get adminLessonTypeLink => 'Link';

  @override
  String get adminLessonTypeText => 'Text';

  @override
  String get adminLessonTypeAudio => 'Audio';

  @override
  String get adminLessonAudioUrl => 'Audio file URL (MP3/M4A)';

  @override
  String get adminLessonAudioUrlInvalid =>
      'Enter a valid http(s) URL ending in .mp3 or .m4a.';

  @override
  String get adminLessonYoutubeUrl => 'YouTube URL';

  @override
  String get adminLessonPdfUrl => 'PDF URL';

  @override
  String get adminLessonLinkUrl => 'Link URL';

  @override
  String get adminLessonTextContent => 'Text content';

  @override
  String get adminLessonResourceUrlRequired =>
      'Resource URL or content is required.';

  @override
  String get adminLessonThumbnailUrl => 'Thumbnail URL (optional)';

  @override
  String get adminLessonDuration => 'Duration (minutes, optional)';

  @override
  String get adminLessonPublished => 'Published';

  @override
  String get adminQuizTitle => 'Quizzes';

  @override
  String get adminQuizCreateTitle => 'Create quiz';

  @override
  String get adminQuizEditTitle => 'Edit quiz';

  @override
  String get adminQuizFormSaved => 'Quiz saved.';

  @override
  String get adminQuizDetailsSection => 'Quiz settings';

  @override
  String get adminQuizLinkedLesson => 'Linked lesson (optional)';

  @override
  String get adminQuizScopeCourse => 'Course-level quiz';

  @override
  String get adminQuizTimeLimit => 'Time limit (seconds, 0 = none)';

  @override
  String get adminQuizPassingScore => 'Passing score (correct answers needed)';

  @override
  String get adminQuizQuestionsSection => 'Questions';

  @override
  String get adminQuizQuestionsEmpty =>
      'No questions yet. Add at least one before saving.';

  @override
  String get adminQuizEmptyList => 'No quizzes yet.';

  @override
  String get adminQuizQuestionsRequired => 'Add at least one question.';

  @override
  String get adminQuizPassingScoreTooHigh =>
      'Passing score cannot exceed question count.';

  @override
  String get adminQuizAddQuestion => 'Add question';

  @override
  String get adminQuizQuestionCreateTitle => 'Add question';

  @override
  String get adminQuizQuestionEditTitle => 'Edit question';

  @override
  String get adminQuizQuestionDeleteTitle => 'Delete question?';

  @override
  String get adminQuizQuestionTextSection => 'Question';

  @override
  String get adminQuizQuestionText => 'Question text';

  @override
  String get adminQuizQuestionTextRequired => 'Question text is required.';

  @override
  String get adminQuizOptionsSection => 'Answer options';

  @override
  String get adminQuizSelectCorrectHint =>
      'Select the radio button for the correct answer.';

  @override
  String adminQuizOptionLabel(int number) {
    return 'Option $number';
  }

  @override
  String get adminQuizOptionRequired => 'Option is required.';

  @override
  String get adminQuizOptionsMinRequired =>
      'At least two options are required.';

  @override
  String get adminQuizCorrectAnswerRequired =>
      'Select a correct answer with text.';

  @override
  String get adminQuizExplanationSection => 'Explanation';

  @override
  String get adminQuizExplanation => 'Explanation (shown after quiz)';

  @override
  String get adminQuizQuestionDone => 'Done';

  @override
  String adminQuizCorrectAnswer(String answer) {
    return 'Answer: $answer';
  }

  @override
  String adminQuizOptionCount(int count) {
    return '$count opts';
  }

  @override
  String get syllabusTitle => 'Syllabus';

  @override
  String get syllabusSearchHint => 'Search courses…';

  @override
  String get syllabusEmptyList => 'No published courses yet.';

  @override
  String get syllabusLoadFailed => 'Could not load courses.';

  @override
  String get syllabusNoSearchResults => 'No courses match your search.';

  @override
  String get syllabusAllTags => 'All';

  @override
  String get syllabusEnroll => 'Enroll';

  @override
  String get syllabusEnrolled => 'Enrolled';

  @override
  String get syllabusEnrollPrompt =>
      'Enroll to track your progress through this course.';

  @override
  String get syllabusEnrollSuccess => 'You\'re enrolled!';

  @override
  String syllabusProgressLabel(int completed, int total) {
    return '$completed of $total lessons';
  }

  @override
  String get syllabusCourseCompleted => 'Course completed';

  @override
  String get syllabusLessonsSection => 'Lessons';

  @override
  String get syllabusNoLessons => 'No lessons published yet.';

  @override
  String syllabusLessonCount(int count) {
    return '$count lessons';
  }

  @override
  String get syllabusCourseLoadFailed => 'Could not load course.';

  @override
  String get syllabusLessonLoadFailed => 'Could not load lesson.';

  @override
  String get syllabusMarkComplete => 'Mark as complete';

  @override
  String get syllabusLessonCompleted => 'Lesson completed';

  @override
  String get syllabusLessonCompleteSuccess => 'Progress saved!';

  @override
  String get syllabusEnrollToComplete =>
      'Enroll in this course to track lesson progress.';

  @override
  String get syllabusOpenPdf => 'Open PDF';

  @override
  String get syllabusOpenLink => 'Open link';

  @override
  String get syllabusInvalidYoutubeUrl =>
      'This lesson has an invalid YouTube URL.';

  @override
  String get syllabusVideoNowPlaying => 'Now playing';

  @override
  String get syllabusVideoRewind => 'Rewind 10s';

  @override
  String get syllabusVideoForward => 'Forward 10s';

  @override
  String get syllabusVideoRestart => 'Restart';

  @override
  String get syllabusVideoMute => 'Mute';

  @override
  String get syllabusVideoUnmute => 'Unmute';

  @override
  String get syllabusVideoOpenYoutube => 'Open in YouTube';

  @override
  String get syllabusLaunchUrlFailed => 'Could not open this resource.';

  @override
  String get syllabusQuizTitle => 'Quiz';

  @override
  String get syllabusQuizLoadFailed => 'Could not load this quiz.';

  @override
  String get syllabusQuizRulesTitle => 'Before you start';

  @override
  String syllabusQuizQuestionCount(int count) {
    return '$count questions';
  }

  @override
  String syllabusQuizTimeLimitLabel(String limit) {
    return 'Time limit: $limit';
  }

  @override
  String get syllabusQuizNoTimeLimit => 'No time limit';

  @override
  String syllabusQuizPassingScoreLabel(int score) {
    return 'Pass with $score correct answers';
  }

  @override
  String get syllabusQuizPreviousAttempts => 'Your attempts';

  @override
  String syllabusQuizAttemptCount(int count) {
    return '$count attempt(s)';
  }

  @override
  String syllabusQuizAttemptNumber(int number) {
    return 'Attempt #$number';
  }

  @override
  String syllabusQuizAttemptsLabel(int count, int score, int total) {
    return '$count attempt(s) · best $score/$total';
  }

  @override
  String syllabusQuizAttemptHistoryRow(int score, int total, String date) {
    return '$score/$total · $date';
  }

  @override
  String get syllabusQuizAttemptPassed => 'Passed';

  @override
  String get syllabusQuizAttemptFailed => 'Failed';

  @override
  String syllabusQuizBestScore(int score, int total) {
    return 'Best score: $score / $total';
  }

  @override
  String get syllabusQuizAlreadyPassed => 'You passed this quiz';

  @override
  String get syllabusQuizStart => 'Start quiz';

  @override
  String syllabusQuizProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get syllabusQuizQuestionLabel => 'Question';

  @override
  String get syllabusQuizNext => 'Next';

  @override
  String get syllabusQuizPrevious => 'Previous';

  @override
  String get syllabusQuizSubmit => 'Submit';

  @override
  String get syllabusQuizTimeRemaining => 'Time remaining';

  @override
  String get syllabusQuizTimeUp => 'Time is up — submitting your answers.';

  @override
  String get syllabusQuizConfirmExitTitle => 'Leave quiz?';

  @override
  String get syllabusQuizConfirmExitMessage =>
      'Your progress on this attempt will be lost.';

  @override
  String get syllabusQuizLeave => 'Leave';

  @override
  String get syllabusQuizResultTitle => 'Quiz result';

  @override
  String get syllabusQuizResultPassed => 'Passed!';

  @override
  String get syllabusQuizResultFailed => 'Not passed';

  @override
  String syllabusQuizYourScore(int score, int total) {
    return 'Score: $score / $total';
  }

  @override
  String syllabusQuizTimeTaken(String time) {
    return 'Time taken: $time';
  }

  @override
  String get syllabusQuizReviewSection => 'Answer review';

  @override
  String syllabusQuizReviewQuestion(int number) {
    return 'Question $number';
  }

  @override
  String get syllabusQuizYourAnswer => 'Your answer';

  @override
  String get syllabusQuizCorrectAnswer => 'Correct answer';

  @override
  String get syllabusQuizExplanation => 'Explanation';

  @override
  String get syllabusQuizRetry => 'Try again';

  @override
  String get syllabusQuizBackToCourse => 'Back to course';

  @override
  String get syllabusQuizExcellent => 'Excellent!';

  @override
  String get syllabusQuizGoodEffort => 'Good effort!';

  @override
  String get syllabusQuizKeepLearning => 'Keep learning!';

  @override
  String get syllabusQuizNotReady => 'This quiz is not ready yet.';

  @override
  String get syllabusQuizBismillahTitle => 'Begin with Bismillah';

  @override
  String get syllabusQuizBismillahArabic =>
      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  String get syllabusQuizBismillahTranslation =>
      'In the name of Allah, the Most Gracious, the Most Merciful.';

  @override
  String get syllabusQuizBismillahIntention =>
      'O Allah, grant me beneficial knowledge and a sound understanding.';

  @override
  String get syllabusQuizBismillahBegin => 'Begin quiz';

  @override
  String get lmsXpSectionTitle => 'Learning progress';

  @override
  String lmsXpLabel(int xp) {
    return '$xp XP';
  }

  @override
  String lmsXpToNextLevel(int xp) {
    return '$xp XP to next level';
  }

  @override
  String get lmsLevelUpTitle => 'Level up!';

  @override
  String get lmsLevelUpTapToContinue => 'Tap to continue';

  @override
  String get lessonDiscussionTitle => 'Discussion';

  @override
  String get lessonDiscussionEmpty =>
      'No comments yet. Start the conversation with your study group.';

  @override
  String get lessonDiscussionHint => 'Share your thoughts on this lesson…';

  @override
  String get lessonDiscussionPost => 'Post';

  @override
  String get lessonDiscussionPostFailed => 'Could not post comment. Try again.';

  @override
  String get lessonDiscussionLoadFailed => 'Could not load discussion.';

  @override
  String get lessonDiscussionEnrollPrompt =>
      'Enroll in this course to join the discussion.';

  @override
  String get lessonDiscussionEditTitle => 'Edit comment';

  @override
  String get lessonDiscussionEditFailed => 'Could not save comment. Try again.';

  @override
  String get lessonDiscussionEdited => 'Edited';

  @override
  String get courseCertificateTitle => 'Certificate of Completion';

  @override
  String get courseCertificateArabic => 'بارك الله فيك';

  @override
  String get courseCertificatePresentedTo => 'Presented to';

  @override
  String get courseCertificateForCourse => 'For completing the course';

  @override
  String courseCertificateDate(String date) {
    return 'Completed on $date';
  }

  @override
  String get courseCertificateShare => 'Share';

  @override
  String get courseCertificateView => 'View certificate';

  @override
  String get syllabusBookmarkedFilter => 'Bookmarked';

  @override
  String get syllabusBookmarksEmpty => 'No bookmarked lessons yet.';

  @override
  String get syllabusAudioLoadFailed => 'Could not load this audio lesson.';

  @override
  String get quranTitle => 'Quran';

  @override
  String get quranSurahList => 'Surahs';

  @override
  String get quranReader => 'Mushaf Reader';

  @override
  String get quranMeccan => 'Meccan';

  @override
  String get quranMedinan => 'Medinan';

  @override
  String quranAyahs(int count) {
    return '$count Ayahs';
  }

  @override
  String quranPage(int page) {
    return 'Page $page';
  }

  @override
  String quranJuz(int juz) {
    return 'Juz $juz';
  }

  @override
  String get quranTranslation => 'Translation';

  @override
  String get quranSelectTranslator => 'Select Translator';

  @override
  String get quranSelectQari => 'Select Qari';

  @override
  String get quranTranslatorKhan => 'Muhiuddin Khan';

  @override
  String get quranTranslatorSahih => 'Sahih International';

  @override
  String get quranSearchHint => 'Search surahs...';

  @override
  String quranContinueReading(int page) {
    return 'Continue from page $page';
  }

  @override
  String get quranOpenReader => 'Open';

  @override
  String get quranFontSize => 'Arabic text size';

  @override
  String get quranNoTranslation => 'Translation hidden or unavailable';

  @override
  String quranAyahLabel(int ayah) {
    return 'Ayah $ayah';
  }

  @override
  String get quranJumpToPage => 'Jump to page';

  @override
  String get quranJumpToSurah => 'Jump to surah';

  @override
  String get quranMushafMode => 'Mushaf view';

  @override
  String get quranSurahMode => 'Surah list';

  @override
  String quranPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get quranTranslationFontSize => 'Translation text size';

  @override
  String get quranPageTheme => 'Page theme';

  @override
  String get quranJumpToAyah => 'Jump to ayah';

  @override
  String get quranJumpToAyahHint => 'Enter ayah number';

  @override
  String get quranAyahCopied => 'Ayah copied to clipboard';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get qiblaGrantLocationPermission => 'Grant Location Permission';

  @override
  String get qiblaOpenSettings => 'Open Settings';

  @override
  String get qiblaNorth => 'N';

  @override
  String get qiblaEast => 'E';

  @override
  String get qiblaSouth => 'S';

  @override
  String get qiblaWest => 'W';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get historyLight => 'Light';

  @override
  String get historyMinimal => 'Minimal';

  @override
  String historyMotivationFull(int days) {
    return 'MashaAllah! You have completed full amal for $days days this month. May Allah accept it.';
  }

  @override
  String get historyMotivationPartial =>
      'You are trying regularly — that is the most important thing. It will gradually increase InshaAllah.';

  @override
  String get historyMotivationMinimal =>
      'Every small amal is valuable to Allah. Try to do a little more today.';

  @override
  String get historyMotivationNoData =>
      'No logs for a few days — no problem. Start again from today, Allah is Most Forgiving.';

  @override
  String get historyMotivationDefault =>
      'Log your amal daily — even small but regular amal is best.';
}
