import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('bn'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Amol Tracker'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsSection;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get privacySection;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'APP'**
  String get appSection;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSection;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get bangla;

  /// No description provided for @morningNotification.
  ///
  /// In en, this message translates to:
  /// **'Morning notification'**
  String get morningNotification;

  /// No description provided for @morningNotificationTime.
  ///
  /// In en, this message translates to:
  /// **'6:00 AM each morning'**
  String get morningNotificationTime;

  /// No description provided for @morningNotificationTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning time'**
  String get morningNotificationTimeLabel;

  /// No description provided for @eveningNotification.
  ///
  /// In en, this message translates to:
  /// **'Evening notification'**
  String get eveningNotification;

  /// No description provided for @eveningNotificationTime.
  ///
  /// In en, this message translates to:
  /// **'6:30 PM each evening'**
  String get eveningNotificationTime;

  /// No description provided for @eveningNotificationTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Evening time'**
  String get eveningNotificationTimeLabel;

  /// No description provided for @notificationTimeTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to customize time'**
  String get notificationTimeTapToChange;

  /// No description provided for @streakWarning.
  ///
  /// In en, this message translates to:
  /// **'Streak warning'**
  String get streakWarning;

  /// No description provided for @streakWarningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you risk losing your streak'**
  String get streakWarningSubtitle;

  /// No description provided for @communityActivity.
  ///
  /// In en, this message translates to:
  /// **'Community activity'**
  String get communityActivity;

  /// No description provided for @communityActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push updates from community'**
  String get communityActivitySubtitle;

  /// No description provided for @reminderTimes.
  ///
  /// In en, this message translates to:
  /// **'Reminder times'**
  String get reminderTimes;

  /// No description provided for @reminderTimesDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the exact reminder time for morning and evening notifications.'**
  String get reminderTimesDescription;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHours;

  /// No description provided for @showOnLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Show me on leaderboard'**
  String get showOnLeaderboard;

  /// No description provided for @showAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Show as anonymous in community'**
  String get showAnonymous;

  /// No description provided for @showAnonymousSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide your real name and photo'**
  String get showAnonymousSubtitle;

  /// No description provided for @calendarType.
  ///
  /// In en, this message translates to:
  /// **'Calendar type'**
  String get calendarType;

  /// No description provided for @hijri.
  ///
  /// In en, this message translates to:
  /// **'Hijri'**
  String get hijri;

  /// No description provided for @ramadanMode.
  ///
  /// In en, this message translates to:
  /// **'Ramadan mode'**
  String get ramadanMode;

  /// No description provided for @ramadanModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust schedule and notifications'**
  String get ramadanModeSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutTitle;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'MORE'**
  String get more;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @devMenu.
  ///
  /// In en, this message translates to:
  /// **'Dev menu'**
  String get devMenu;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @exploreSection.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE'**
  String get exploreSection;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profileAndBadges.
  ///
  /// In en, this message translates to:
  /// **'Profile & badges'**
  String get profileAndBadges;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferencesSection;

  /// No description provided for @emptyDevSection.
  ///
  /// In en, this message translates to:
  /// **'EMPTY / DEV'**
  String get emptyDevSection;

  /// No description provided for @emptyStatePreview.
  ///
  /// In en, this message translates to:
  /// **'Empty state preview'**
  String get emptyStatePreview;

  /// No description provided for @devMenuAllScreens.
  ///
  /// In en, this message translates to:
  /// **'Dev menu (all screens)'**
  String get devMenuAllScreens;

  /// No description provided for @quietHoursDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications stay silent during these hours. Notification schedules still run.'**
  String get quietHoursDescription;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'TO'**
  String get to;

  /// No description provided for @silentFromTo.
  ///
  /// In en, this message translates to:
  /// **'Silent from {from} to {to}'**
  String silentFromTo(Object from, Object to);

  /// No description provided for @hoursSilence.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours of silence'**
  String hoursSilence(Object hours);

  /// No description provided for @hoursMinutesSilence.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} m of silence'**
  String hoursMinutesSilence(Object hours, Object minutes);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @failedLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications.'**
  String get failedLoadNotifications;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(Object hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(Object days);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String weeksAgo(Object weeks);

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get today;

  /// No description provided for @noAmalLoggedYet.
  ///
  /// In en, this message translates to:
  /// **'No amal logged yet'**
  String get noAmalLoggedYet;

  /// No description provided for @freshStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Today\'s a fresh start. Tick off your first amal - even one counts.'**
  String get freshStartMessage;

  /// No description provided for @logTodayAmal.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s amal'**
  String get logTodayAmal;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the community'**
  String get joinCommunity;

  /// No description provided for @joinCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'See today\'s community sheet and stay motivated with everyone\'s progress.'**
  String get joinCommunitySubtitle;

  /// No description provided for @openCommunity.
  ///
  /// In en, this message translates to:
  /// **'Open community'**
  String get openCommunity;

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'Daily devotion, with brothers'**
  String get signInTagline;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @continueTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Privacy.'**
  String get continueTerms;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {error}'**
  String googleSignInFailed(Object error);

  /// No description provided for @guestSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Guest sign-in failed: {error}'**
  String guestSignInFailed(Object error);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @buildDailyHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'Build a daily habit'**
  String get buildDailyHabitTitle;

  /// No description provided for @buildDailyHabitBody.
  ///
  /// In en, this message translates to:
  /// **'Track 9 daily amal - fard, sunnah, azkar, Quran. Tiny, consistent steps.'**
  String get buildDailyHabitBody;

  /// No description provided for @streaksKeepYouGoingTitle.
  ///
  /// In en, this message translates to:
  /// **'Streaks keep you going'**
  String get streaksKeepYouGoingTitle;

  /// No description provided for @streaksKeepYouGoingBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break the chain. Hit 7, 30, 100 days - earn your khair.'**
  String get streaksKeepYouGoingBody;

  /// No description provided for @setupProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get setupProfileTitle;

  /// No description provided for @setupProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Set your name and privacy before joining the community.'**
  String get setupProfileBody;

  /// No description provided for @starter.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get starter;

  /// No description provided for @habit.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get habit;

  /// No description provided for @devoted.
  ///
  /// In en, this message translates to:
  /// **'Devoted'**
  String get devoted;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @showAnonymousCommunity.
  ///
  /// In en, this message translates to:
  /// **'Show as Anonymous in community'**
  String get showAnonymousCommunity;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotifications;

  /// No description provided for @onboardingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete onboarding: {error}'**
  String onboardingFailed(Object error);

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @historyDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get historyDays;

  /// No description provided for @pointsAbbr.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pointsAbbr;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get you;

  /// No description provided for @leaderboardBeFirstToday.
  ///
  /// In en, this message translates to:
  /// **'Be the first to log today!'**
  String get leaderboardBeFirstToday;

  /// No description provided for @leaderboardYourRank.
  ///
  /// In en, this message translates to:
  /// **'Your rank: #{rank} · {score} {stat}'**
  String leaderboardYourRank(Object rank, Object score, Object stat);

  /// No description provided for @leaderboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load leaderboard right now.'**
  String get leaderboardLoadFailed;

  /// No description provided for @leaderboardNudgeKeepClimbing.
  ///
  /// In en, this message translates to:
  /// **'Keep climbing - every amal counts.'**
  String get leaderboardNudgeKeepClimbing;

  /// No description provided for @leaderboardNudgeTop.
  ///
  /// In en, this message translates to:
  /// **'You are on top - stay consistent.'**
  String get leaderboardNudgeTop;

  /// No description provided for @leaderboardNudgeBehindDays.
  ///
  /// In en, this message translates to:
  /// **'{behind} days behind 2nd place - keep your streak alive.'**
  String leaderboardNudgeBehindDays(Object behind);

  /// No description provided for @leaderboardNudgeBehindPoints.
  ///
  /// In en, this message translates to:
  /// **'{behind} pts behind 2nd place - log today to close the gap.'**
  String leaderboardNudgeBehindPoints(Object behind);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get history;

  /// No description provided for @historyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load history.'**
  String get historyLoadFailed;

  /// No description provided for @historyConsistency.
  ///
  /// In en, this message translates to:
  /// **'{value}% consistency'**
  String historyConsistency(Object value);

  /// No description provided for @historyLoggedDays.
  ///
  /// In en, this message translates to:
  /// **'Logged days'**
  String get historyLoggedDays;

  /// No description provided for @historyOfDays.
  ///
  /// In en, this message translates to:
  /// **'of {days} days'**
  String historyOfDays(Object days);

  /// No description provided for @historyAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg score'**
  String get historyAvgScore;

  /// No description provided for @historyNoLogsYet.
  ///
  /// In en, this message translates to:
  /// **'no logs yet'**
  String get historyNoLogsYet;

  /// No description provided for @historyThisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get historyThisMonth;

  /// No description provided for @historyBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get historyBestStreak;

  /// No description provided for @historyStartLogging.
  ///
  /// In en, this message translates to:
  /// **'Start logging to build your history'**
  String get historyStartLogging;

  /// No description provided for @historyWeakestAmal.
  ///
  /// In en, this message translates to:
  /// **'Weakest amal'**
  String get historyWeakestAmal;

  /// No description provided for @historyWeakestAmalDetail.
  ///
  /// In en, this message translates to:
  /// **'{label} - missed {days} days this month'**
  String historyWeakestAmalDetail(Object label, Object days);

  /// No description provided for @historyFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get historyFull;

  /// No description provided for @historyPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get historyPartial;

  /// No description provided for @historyMiss.
  ///
  /// In en, this message translates to:
  /// **'Miss'**
  String get historyMiss;

  /// No description provided for @dayDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Day detail'**
  String get dayDetailTitle;

  /// No description provided for @dayDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this day.'**
  String get dayDetailLoadFailed;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'READ-ONLY'**
  String get readOnly;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @outOf100.
  ///
  /// In en, this message translates to:
  /// **'of 100'**
  String get outOf100;

  /// No description provided for @dayDetailStreakThatDay.
  ///
  /// In en, this message translates to:
  /// **'Streak that day'**
  String get dayDetailStreakThatDay;

  /// No description provided for @dayDetailNotStored.
  ///
  /// In en, this message translates to:
  /// **'not stored'**
  String get dayDetailNotStored;

  /// No description provided for @amal.
  ///
  /// In en, this message translates to:
  /// **'Amal'**
  String get amal;

  /// No description provided for @dayDetailNoLogForDay.
  ///
  /// In en, this message translates to:
  /// **'No log was submitted for this Hijri day.'**
  String get dayDetailNoLogForDay;

  /// No description provided for @dayDetailLockedPastDays.
  ///
  /// In en, this message translates to:
  /// **'Locked - past days cannot be edited.'**
  String get dayDetailLockedPastDays;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {year}'**
  String memberSince(Object year);

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get best;

  /// No description provided for @avg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avg;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @anonymousEnabled.
  ///
  /// In en, this message translates to:
  /// **'Anonymous enabled'**
  String get anonymousEnabled;

  /// No description provided for @realNameVisible.
  ///
  /// In en, this message translates to:
  /// **'Real name visible'**
  String get realNameVisible;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @communityUpper.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY'**
  String get communityUpper;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @sheet.
  ///
  /// In en, this message translates to:
  /// **'Sheet'**
  String get sheet;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @offlineShowingLatest.
  ///
  /// In en, this message translates to:
  /// **'Offline - showing latest available data.'**
  String get offlineShowingLatest;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get date;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// No description provided for @logTodayToAppear.
  ///
  /// In en, this message translates to:
  /// **'Log today to appear here'**
  String get logTodayToAppear;

  /// No description provided for @noLogsForDay.
  ///
  /// In en, this message translates to:
  /// **'No logs recorded for this day'**
  String get noLogsForDay;

  /// No description provided for @noMoreRows.
  ///
  /// In en, this message translates to:
  /// **'No more rows'**
  String get noMoreRows;

  /// No description provided for @unableLoadActivityFeed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load activity feed.'**
  String get unableLoadActivityFeed;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet. Community updates will appear here.'**
  String get noActivityYet;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @profileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This profile is unavailable.'**
  String get profileUnavailable;

  /// No description provided for @communityMember.
  ///
  /// In en, this message translates to:
  /// **'Community member'**
  String get communityMember;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @todaysAmal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s amal'**
  String get todaysAmal;

  /// No description provided for @amalOnDate.
  ///
  /// In en, this message translates to:
  /// **'Amal on {date}'**
  String amalOnDate(Object date);

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile settings'**
  String get profileSettings;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @sendDua.
  ///
  /// In en, this message translates to:
  /// **'Send Dua'**
  String get sendDua;

  /// No description provided for @alreadySentDuaToday.
  ///
  /// In en, this message translates to:
  /// **'You already sent a dua today'**
  String get alreadySentDuaToday;

  /// No description provided for @communityMemberSentDua.
  ///
  /// In en, this message translates to:
  /// **'কমিউনিটি থেকে কেউ আপনাকে দোয়া পাঠিয়েছে 🤲'**
  String get communityMemberSentDua;

  /// No description provided for @duaFromSender.
  ///
  /// In en, this message translates to:
  /// **'{name} আপনাকে দোয়া পাঠিয়েছেন 🤲'**
  String duaFromSender(Object name);

  /// No description provided for @duaSent.
  ///
  /// In en, this message translates to:
  /// **'Dua sent ✓'**
  String get duaSent;

  /// No description provided for @noRecentLogs.
  ///
  /// In en, this message translates to:
  /// **'No recent logs available.'**
  String get noRecentLogs;

  /// No description provided for @friendsUpper.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS'**
  String get friendsUpper;

  /// No description provided for @together.
  ///
  /// In en, this message translates to:
  /// **'Together'**
  String get together;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @activityFeed.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY FEED'**
  String get activityFeed;

  /// No description provided for @yourGroup.
  ///
  /// In en, this message translates to:
  /// **'YOUR GROUP'**
  String get yourGroup;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get manage;

  /// No description provided for @groupMembersDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} brothers · {desc}'**
  String groupMembersDesc(Object count, Object desc);

  /// No description provided for @viewSheetArrow.
  ///
  /// In en, this message translates to:
  /// **'View sheet →'**
  String get viewSheetArrow;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get done;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get pending;

  /// No description provided for @inviteAndJoin.
  ///
  /// In en, this message translates to:
  /// **'Invite & Join'**
  String get inviteAndJoin;

  /// No description provided for @yourInviteCode.
  ///
  /// In en, this message translates to:
  /// **'YOUR INVITE CODE'**
  String get yourInviteCode;

  /// No description provided for @inviteCodeValid.
  ///
  /// In en, this message translates to:
  /// **'Valid · 5 brothers can join'**
  String get inviteCodeValid;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get inviteCodeCopied;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shareLink;

  /// No description provided for @joinGroupUpper.
  ///
  /// In en, this message translates to:
  /// **'JOIN A GROUP'**
  String get joinGroupUpper;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code'**
  String get enterInviteCode;

  /// No description provided for @joinedMock.
  ///
  /// In en, this message translates to:
  /// **'Joined (mock)'**
  String get joinedMock;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get joinGroup;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @topScorer.
  ///
  /// In en, this message translates to:
  /// **'Top scorer'**
  String get topScorer;

  /// No description provided for @duaSentMock.
  ///
  /// In en, this message translates to:
  /// **'Dua sent (mock)'**
  String get duaSentMock;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'admin'**
  String get admin;

  /// No description provided for @inviteCodeUpper.
  ///
  /// In en, this message translates to:
  /// **'INVITE CODE'**
  String get inviteCodeUpper;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'MEMBERS'**
  String get members;

  /// No description provided for @groupSettings.
  ///
  /// In en, this message translates to:
  /// **'GROUP SETTINGS'**
  String get groupSettings;

  /// No description provided for @publicLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Public leaderboard'**
  String get publicLeaderboard;

  /// No description provided for @publicLeaderboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show ranks to all members'**
  String get publicLeaderboardSubtitle;

  /// No description provided for @quietHoursActive.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours active'**
  String get quietHoursActive;

  /// No description provided for @quietHoursActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications at night'**
  String get quietHoursActiveSubtitle;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @deleteThisGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete this group?'**
  String get deleteThisGroup;

  /// No description provided for @deleteGroupWarning.
  ///
  /// In en, this message translates to:
  /// **'Members will lose access. This cannot be undone.'**
  String get deleteGroupWarning;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String dayStreak(Object days);

  /// No description provided for @groupSheet.
  ///
  /// In en, this message translates to:
  /// **'Group Sheet'**
  String get groupSheet;

  /// No description provided for @allActiveToday.
  ///
  /// In en, this message translates to:
  /// **'All {count} active today'**
  String allActiveToday(Object count);

  /// No description provided for @groupStreak.
  ///
  /// In en, this message translates to:
  /// **'group streak'**
  String get groupStreak;

  /// No description provided for @groupAvg.
  ///
  /// In en, this message translates to:
  /// **'Group avg'**
  String get groupAvg;

  /// No description provided for @memberUpper.
  ///
  /// In en, this message translates to:
  /// **'MEMBER'**
  String get memberUpper;

  /// No description provided for @numericLegend.
  ///
  /// In en, this message translates to:
  /// **'Numeric (Fard, Takbir)'**
  String get numericLegend;

  /// No description provided for @homeOfflineSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'Offline - your log is saved on this device and will sync when you reconnect.'**
  String get homeOfflineSyncMessage;

  /// No description provided for @loggedToday.
  ///
  /// In en, this message translates to:
  /// **'Logged today ✓'**
  String get loggedToday;

  /// No description provided for @markAllDone.
  ///
  /// In en, this message translates to:
  /// **'Mark all done'**
  String get markAllDone;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @submitTodaysLog.
  ///
  /// In en, this message translates to:
  /// **'Submit today\'s log'**
  String get submitTodaysLog;

  /// No description provided for @saveTodaysAmal.
  ///
  /// In en, this message translates to:
  /// **'Save today\'s amal'**
  String get saveTodaysAmal;

  /// No description provided for @draftSavedTapSaveToFinish.
  ///
  /// In en, this message translates to:
  /// **'Draft saved. Tap Save to finish today.'**
  String get draftSavedTapSaveToFinish;

  /// No description provided for @completeAllAmalAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Complete every amal above to save today.'**
  String get completeAllAmalAutoSave;

  /// No description provided for @amalAutoSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving today\'s amal…'**
  String get amalAutoSaving;

  /// No description provided for @progressAutosavedHint.
  ///
  /// In en, this message translates to:
  /// **'Your progress is auto-saved as draft.'**
  String get progressAutosavedHint;

  /// No description provided for @welcomeUpper.
  ///
  /// In en, this message translates to:
  /// **'WELCOME'**
  String get welcomeUpper;

  /// No description provided for @firstAmalStartsToday.
  ///
  /// In en, this message translates to:
  /// **'Your first amal starts today.'**
  String get firstAmalStartsToday;

  /// No description provided for @onFire.
  ///
  /// In en, this message translates to:
  /// **'on fire'**
  String get onFire;

  /// No description provided for @bestStreakKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Best: {days} days · keep it going'**
  String bestStreakKeepGoing(Object days);

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s progress'**
  String get todaysProgress;

  /// No description provided for @scoreOutOfPoints.
  ///
  /// In en, this message translates to:
  /// **'{score} / {max} points'**
  String scoreOutOfPoints(Object score, Object max);

  /// No description provided for @outOf100Compact.
  ///
  /// In en, this message translates to:
  /// **'/100'**
  String get outOf100Compact;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekdaySun;

  /// No description provided for @dayCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You completed today\'s amal.'**
  String get dayCompleteSubtitle;

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} pts earned'**
  String pointsEarned(Object points);

  /// No description provided for @hadithOfDay.
  ///
  /// In en, this message translates to:
  /// **'HADITH OF THE DAY'**
  String get hadithOfDay;

  /// No description provided for @todaysSummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s summary'**
  String get todaysSummary;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @pointsValue.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String pointsValue(Object points);

  /// No description provided for @tapScreenToJump.
  ///
  /// In en, this message translates to:
  /// **'Tap a screen to jump to it (UI testing)'**
  String get tapScreenToJump;

  /// No description provided for @badgeThreeDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'3-Day Streak'**
  String get badgeThreeDaysTitle;

  /// No description provided for @badgeThreeDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete amal for 3 consecutive days.'**
  String get badgeThreeDaysDesc;

  /// No description provided for @badgeSevenDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'7-Day Streak'**
  String get badgeSevenDaysTitle;

  /// No description provided for @badgeSevenDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete amal for 7 consecutive days.'**
  String get badgeSevenDaysDesc;

  /// No description provided for @badgeFourteenDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'14-Day Streak'**
  String get badgeFourteenDaysTitle;

  /// No description provided for @badgeFourteenDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete amal for 14 consecutive days.'**
  String get badgeFourteenDaysDesc;

  /// No description provided for @badgeThirtyDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'30-Day Streak'**
  String get badgeThirtyDaysTitle;

  /// No description provided for @badgeThirtyDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete amal for 30 consecutive days.'**
  String get badgeThirtyDaysDesc;

  /// No description provided for @badgeSixtyDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'60-Day Streak'**
  String get badgeSixtyDaysTitle;

  /// No description provided for @badgeSixtyDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete amal for 60 consecutive days.'**
  String get badgeSixtyDaysDesc;

  /// No description provided for @badgeHundredDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'100-Day Streak'**
  String get badgeHundredDaysTitle;

  /// No description provided for @badgeHundredDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete amal for 100 consecutive days.'**
  String get badgeHundredDaysDesc;

  /// No description provided for @badgeTopCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Top of Community'**
  String get badgeTopCommunityTitle;

  /// No description provided for @badgeTopCommunityDesc.
  ///
  /// In en, this message translates to:
  /// **'Rank #1 on the global weekly leaderboard.'**
  String get badgeTopCommunityDesc;

  /// No description provided for @badgePerfectWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Perfect Week'**
  String get badgePerfectWeekTitle;

  /// No description provided for @badgePerfectWeekDesc.
  ///
  /// In en, this message translates to:
  /// **'Score 80+ for 7 consecutive days.'**
  String get badgePerfectWeekDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
