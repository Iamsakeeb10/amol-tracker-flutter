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

  /// No description provided for @studyReviewReminder.
  ///
  /// In en, this message translates to:
  /// **'Study review reminders'**
  String get studyReviewReminder;

  /// No description provided for @studyReviewReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Spaced repetition nudges for enrolled lessons'**
  String get studyReviewReminderSubtitle;

  /// No description provided for @notificationTypeStudyReview.
  ///
  /// In en, this message translates to:
  /// **'Study review'**
  String get notificationTypeStudyReview;

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

  /// No description provided for @prayerAdhanReminder.
  ///
  /// In en, this message translates to:
  /// **'Prayer adhan reminder'**
  String get prayerAdhanReminder;

  /// No description provided for @prayerAdhanReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Per-prayer adhan alerts'**
  String get prayerAdhanReminderSubtitle;

  /// No description provided for @prayerAdhanScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer adhan reminder'**
  String get prayerAdhanScreenTitle;

  /// No description provided for @prayerAdhanDescription.
  ///
  /// In en, this message translates to:
  /// **'Get adhan reminders for each prayer. Times are calculated for Bangladesh.'**
  String get prayerAdhanDescription;

  /// No description provided for @prayerAdhanTodayTimes.
  ///
  /// In en, this message translates to:
  /// **'Today\'s prayer times'**
  String get prayerAdhanTodayTimes;

  /// No description provided for @prayerAdhanReminderTimes.
  ///
  /// In en, this message translates to:
  /// **'Reminder times'**
  String get prayerAdhanReminderTimes;

  /// No description provided for @prayerAdhanReminderTimesDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap to set a custom reminder time. Reset to use calculated adhan time for each day.'**
  String get prayerAdhanReminderTimesDescription;

  /// No description provided for @prayerAdhanCalculatedTime.
  ///
  /// In en, this message translates to:
  /// **'Adhan time'**
  String get prayerAdhanCalculatedTime;

  /// No description provided for @prayerAdhanCustomTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom time'**
  String get prayerAdhanCustomTimeLabel;

  /// No description provided for @prayerAdhanResetToAdhan.
  ///
  /// In en, this message translates to:
  /// **'Use adhan time'**
  String get prayerAdhanResetToAdhan;

  /// No description provided for @prayerAdhanOffsetTitle.
  ///
  /// In en, this message translates to:
  /// **'When should the reminder appear?'**
  String get prayerAdhanOffsetTitle;

  /// No description provided for @prayerAdhanAtTime.
  ///
  /// In en, this message translates to:
  /// **'At adhan time'**
  String get prayerAdhanAtTime;

  /// No description provided for @prayerAdhanChipAtTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get prayerAdhanChipAtTime;

  /// No description provided for @prayerAdhanChipMinBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m before'**
  String prayerAdhanChipMinBefore(Object minutes);

  /// No description provided for @prayerAdhanMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String prayerAdhanMinutesBefore(Object minutes);

  /// No description provided for @prayerAdhanReliabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Background reminders need setup'**
  String get prayerAdhanReliabilityTitle;

  /// No description provided for @prayerAdhanReliabilityBody.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms so adhan reminders fire when the app is closed. Also disable battery optimization for reliable delivery.'**
  String get prayerAdhanReliabilityBody;

  /// No description provided for @prayerAdhanAllowExactAlarms.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms'**
  String get prayerAdhanAllowExactAlarms;

  /// No description provided for @prayerAdhanDisableBatteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Disable battery optimization'**
  String get prayerAdhanDisableBatteryOptimization;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

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

  /// No description provided for @hijriCalendar.
  ///
  /// In en, this message translates to:
  /// **'Hijri Calendar'**
  String get hijriCalendar;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @islamicEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'ISLAMIC EVENTS'**
  String get islamicEventsTitle;

  /// No description provided for @eventIslamicNewYear.
  ///
  /// In en, this message translates to:
  /// **'Islamic New Year'**
  String get eventIslamicNewYear;

  /// No description provided for @eventAshura.
  ///
  /// In en, this message translates to:
  /// **'Day of Ashura'**
  String get eventAshura;

  /// No description provided for @eventMawlid.
  ///
  /// In en, this message translates to:
  /// **'Mawlid an-Nabi'**
  String get eventMawlid;

  /// No description provided for @eventIsraMiraj.
  ///
  /// In en, this message translates to:
  /// **'Isra and Mi\'raj'**
  String get eventIsraMiraj;

  /// No description provided for @eventShabeBarat.
  ///
  /// In en, this message translates to:
  /// **'Shab-e-Barat'**
  String get eventShabeBarat;

  /// No description provided for @eventRamadanStart.
  ///
  /// In en, this message translates to:
  /// **'Start of Ramadan'**
  String get eventRamadanStart;

  /// No description provided for @eventLaylatAlQadr.
  ///
  /// In en, this message translates to:
  /// **'Laylat al-Qadr'**
  String get eventLaylatAlQadr;

  /// No description provided for @eventEidAlFitr.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Fitr'**
  String get eventEidAlFitr;

  /// No description provided for @eventArafat.
  ///
  /// In en, this message translates to:
  /// **'Day of Arafat'**
  String get eventArafat;

  /// No description provided for @eventEidAlAdha.
  ///
  /// In en, this message translates to:
  /// **'Eid al-Adha'**
  String get eventEidAlAdha;

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

  /// No description provided for @homeWidgetSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get homeWidgetSettingsTitle;

  /// No description provided for @homeWidgetSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get homeWidgetSettingsSubtitle;

  /// No description provided for @homeWidgetSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Add home screen widget'**
  String get homeWidgetSetupTitle;

  /// No description provided for @homeWidgetSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Keep today\'s amal progress visible from your home screen.'**
  String get homeWidgetSetupBody;

  /// No description provided for @homeWidgetAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add widget'**
  String get homeWidgetAddButton;

  /// No description provided for @homeWidgetUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Direct add is not supported on this launcher.'**
  String get homeWidgetUnsupportedMessage;

  /// No description provided for @homeWidgetPinRequested.
  ///
  /// In en, this message translates to:
  /// **'Widget add request sent. Confirm on your home screen.'**
  String get homeWidgetPinRequested;

  /// No description provided for @homeWidgetPinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start widget add right now. Use manual steps below.'**
  String get homeWidgetPinFailed;

  /// No description provided for @homeWidgetIosGuide.
  ///
  /// In en, this message translates to:
  /// **'On iPhone: long-press the home screen, tap +, then search \"Amol Tracker\" widget.'**
  String get homeWidgetIosGuide;

  /// No description provided for @homeWidgetFallbackSteps.
  ///
  /// In en, this message translates to:
  /// **'Manual steps: Long-press home screen -> Widgets -> Amol Tracker -> Add.'**
  String get homeWidgetFallbackSteps;

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

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. You may need to sign in again.'**
  String get deleteAccountFailed;

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

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navDua.
  ///
  /// In en, this message translates to:
  /// **'Dua'**
  String get navDua;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @quickNavSection.
  ///
  /// In en, this message translates to:
  /// **'Quick Navigation'**
  String get quickNavSection;

  /// No description provided for @morningEveningDua.
  ///
  /// In en, this message translates to:
  /// **'Morning & Evening Dua'**
  String get morningEveningDua;

  /// No description provided for @duaTitle.
  ///
  /// In en, this message translates to:
  /// **'Duas'**
  String get duaTitle;

  /// No description provided for @duaFavoritesTab.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get duaFavoritesTab;

  /// No description provided for @duaCategoriesTab.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get duaCategoriesTab;

  /// No description provided for @duaAllTab.
  ///
  /// In en, this message translates to:
  /// **'All Duas'**
  String get duaAllTab;

  /// No description provided for @duaSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search duas...'**
  String get duaSearchHint;

  /// No description provided for @duaReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get duaReference;

  /// No description provided for @duaTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get duaTransliteration;

  /// No description provided for @duaTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get duaTranslation;

  /// No description provided for @duaNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet.\nTap ★ on any dua to save it.'**
  String get duaNoFavorites;

  /// No description provided for @duaNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get duaNoResults;

  /// No description provided for @duaFavAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favourites'**
  String get duaFavAdded;

  /// No description provided for @duaFavRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favourites'**
  String get duaFavRemoved;

  /// No description provided for @duaFavAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get duaFavAdd;

  /// No description provided for @duaFavRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get duaFavRemove;

  /// No description provided for @duaCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get duaCopy;

  /// No description provided for @duaShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get duaShare;

  /// No description provided for @duaCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get duaCopied;

  /// No description provided for @duaPageCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String duaPageCounter(int current, int total);

  /// No description provided for @duaReaderOptions.
  ///
  /// In en, this message translates to:
  /// **'Reading options'**
  String get duaReaderOptions;

  /// No description provided for @duaReaderTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get duaReaderTextSize;

  /// No description provided for @duaReaderTextSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get duaReaderTextSizeNormal;

  /// No description provided for @duaReaderTextSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get duaReaderTextSizeMedium;

  /// No description provided for @duaReaderTextSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get duaReaderTextSizeLarge;

  /// No description provided for @duaReaderShowIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get duaReaderShowIntroduction;

  /// No description provided for @duaReaderShowTransliteration.
  ///
  /// In en, this message translates to:
  /// **'Transliteration'**
  String get duaReaderShowTransliteration;

  /// No description provided for @duaReaderShowTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get duaReaderShowTranslation;

  /// No description provided for @duaReaderShowReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get duaReaderShowReference;

  /// No description provided for @duaReaderFocusMode.
  ///
  /// In en, this message translates to:
  /// **'Focus mode'**
  String get duaReaderFocusMode;

  /// No description provided for @duaReaderFocusModeExit.
  ///
  /// In en, this message translates to:
  /// **'Exit focus mode'**
  String get duaReaderFocusModeExit;

  /// No description provided for @duaReaderPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous dua'**
  String get duaReaderPrevious;

  /// No description provided for @duaReaderNext.
  ///
  /// In en, this message translates to:
  /// **'Next dua'**
  String get duaReaderNext;

  /// No description provided for @duaReaderMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get duaReaderMore;

  /// No description provided for @duaReaderTextSizeDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease text size'**
  String get duaReaderTextSizeDecrease;

  /// No description provided for @duaReaderTextSizeIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase text size'**
  String get duaReaderTextSizeIncrease;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found: {path}'**
  String routeNotFound(String path);

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

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @todayTop.
  ///
  /// In en, this message translates to:
  /// **'Today\'s top'**
  String get todayTop;

  /// No description provided for @monthTop.
  ///
  /// In en, this message translates to:
  /// **'Month\'s top'**
  String get monthTop;

  /// No description provided for @noOneYet.
  ///
  /// In en, this message translates to:
  /// **'No one yet'**
  String get noOneYet;

  /// No description provided for @meLabel.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get meLabel;

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

  /// No description provided for @saveFabLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveFabLabel;

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

  /// No description provided for @leaderboardYourRankNumber.
  ///
  /// In en, this message translates to:
  /// **'Your rank: #{rank}'**
  String leaderboardYourRankNumber(int rank);

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

  /// No description provided for @leaderboardNudgeBehindFirstDays.
  ///
  /// In en, this message translates to:
  /// **'{behind} days behind 1st place - keep your streak alive.'**
  String leaderboardNudgeBehindFirstDays(Object behind);

  /// No description provided for @leaderboardNudgeBehindFirstPoints.
  ///
  /// In en, this message translates to:
  /// **'{behind} pts behind 1st place - log today to take the lead.'**
  String leaderboardNudgeBehindFirstPoints(Object behind);

  /// No description provided for @leaderboardQuizTab.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get leaderboardQuizTab;

  /// No description provided for @leaderboardQuizBeFirst.
  ///
  /// In en, this message translates to:
  /// **'Be the first to pass a quiz!'**
  String get leaderboardQuizBeFirst;

  /// No description provided for @leaderboardNudgeBehindQuizPoints.
  ///
  /// In en, this message translates to:
  /// **'{behind} pts behind 2nd place - pass more quizzes to climb.'**
  String leaderboardNudgeBehindQuizPoints(Object behind);

  /// No description provided for @leaderboardNudgeBehindFirstQuizPoints.
  ///
  /// In en, this message translates to:
  /// **'{behind} pts behind 1st place - pass more quizzes to take the lead.'**
  String leaderboardNudgeBehindFirstQuizPoints(Object behind);

  /// No description provided for @leaderboardQuizAttempts.
  ///
  /// In en, this message translates to:
  /// **'attempts'**
  String get leaderboardQuizAttempts;

  /// No description provided for @leaderboardQuizStat.
  ///
  /// In en, this message translates to:
  /// **'{points} pts · {attempts} attempts'**
  String leaderboardQuizStat(int points, int attempts);

  /// No description provided for @leaderboardYourRankQuiz.
  ///
  /// In en, this message translates to:
  /// **'Your rank: #{rank} · {stat}'**
  String leaderboardYourRankQuiz(int rank, String stat);

  /// No description provided for @leaderboardQuizTiebreakerHint.
  ///
  /// In en, this message translates to:
  /// **'Equal points? Fewer total attempts rank higher.'**
  String get leaderboardQuizTiebreakerHint;

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
  /// **'Locked — days before you joined cannot be edited.'**
  String get dayDetailLockedPastDays;

  /// No description provided for @editDayAmal.
  ///
  /// In en, this message translates to:
  /// **'Edit this day\'s amal'**
  String get editDayAmal;

  /// No description provided for @dayDetailTodayGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home to log today\'s amal.'**
  String get dayDetailTodayGoHome;

  /// No description provided for @dayDetailGoToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get dayDetailGoToHome;

  /// No description provided for @editTodayAmal.
  ///
  /// In en, this message translates to:
  /// **'Edit today\'s amal'**
  String get editTodayAmal;

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
  /// **'Draft saved. Tap {saveButton} to finish today.'**
  String draftSavedTapSaveToFinish(Object saveButton);

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

  /// No description provided for @badgeCourseGraduateTitle.
  ///
  /// In en, this message translates to:
  /// **'Course Graduate'**
  String get badgeCourseGraduateTitle;

  /// No description provided for @badgeCourseGraduateDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete all lessons in a syllabus course.'**
  String get badgeCourseGraduateDesc;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit app?'**
  String get exitAppTitle;

  /// No description provided for @exitAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'Have you logged today\'s amal?'**
  String get exitAppConfirm;

  /// No description provided for @exitAppStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get exitAppStay;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitApp;

  /// No description provided for @dhikrCounter.
  ///
  /// In en, this message translates to:
  /// **'Dhikr Counter'**
  String get dhikrCounter;

  /// No description provided for @subhanAllah.
  ///
  /// In en, this message translates to:
  /// **'SubhanAllah'**
  String get subhanAllah;

  /// No description provided for @alhamdulillah.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah'**
  String get alhamdulillah;

  /// No description provided for @allahuAkbar.
  ///
  /// In en, this message translates to:
  /// **'Allahu Akbar'**
  String get allahuAkbar;

  /// No description provided for @dhikrTarget.
  ///
  /// In en, this message translates to:
  /// **'Target: {count}'**
  String dhikrTarget(int count);

  /// No description provided for @dhikrCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get dhikrCount;

  /// No description provided for @dhikrCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed!'**
  String get dhikrCompleted;

  /// No description provided for @dhikrReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get dhikrReset;

  /// No description provided for @dhikrCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dhikrCustom;

  /// No description provided for @dhikrAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add custom dhikr'**
  String get dhikrAddCustom;

  /// No description provided for @dhikrAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get dhikrAdd;

  /// No description provided for @dhikrCustomName.
  ///
  /// In en, this message translates to:
  /// **'Dhikr name'**
  String get dhikrCustomName;

  /// No description provided for @dhikrCustomTarget.
  ///
  /// In en, this message translates to:
  /// **'Target count'**
  String get dhikrCustomTarget;

  /// No description provided for @dhikrTodaySessions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s completions'**
  String get dhikrTodaySessions;

  /// No description provided for @dhikrNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No dhikr completed yet today.'**
  String get dhikrNoSessions;

  /// No description provided for @dhikrSelectDhikr.
  ///
  /// In en, this message translates to:
  /// **'Select dhikr'**
  String get dhikrSelectDhikr;

  /// No description provided for @dhikrShortcutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Count SubhanAllah, Alhamdulillah & more'**
  String get dhikrShortcutSubtitle;

  /// No description provided for @dhikrTapToCount.
  ///
  /// In en, this message translates to:
  /// **'Tap to count'**
  String get dhikrTapToCount;

  /// No description provided for @dhikrNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a dhikr name.'**
  String get dhikrNameRequired;

  /// No description provided for @dhikrTargetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Target must be at least 1.'**
  String get dhikrTargetInvalid;

  /// No description provided for @dhikrDuplicateName.
  ///
  /// In en, this message translates to:
  /// **'A dhikr with this name already exists.'**
  String get dhikrDuplicateName;

  /// No description provided for @asmaUlHusna.
  ///
  /// In en, this message translates to:
  /// **'Asma ul Husna'**
  String get asmaUlHusna;

  /// No description provided for @husnaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'99 Names of Allah'**
  String get husnaSubtitle;

  /// No description provided for @husnaLearnedCount.
  ///
  /// In en, this message translates to:
  /// **'{learned} of 99 learned'**
  String husnaLearnedCount(int learned);

  /// No description provided for @husnaMarkLearned.
  ///
  /// In en, this message translates to:
  /// **'Mark as Learned'**
  String get husnaMarkLearned;

  /// No description provided for @husnaMarkNotLearned.
  ///
  /// In en, this message translates to:
  /// **'Unmark'**
  String get husnaMarkNotLearned;

  /// No description provided for @husnaQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz Mode'**
  String get husnaQuiz;

  /// No description provided for @husnaQuizQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which name has this meaning?'**
  String get husnaQuizQuestion;

  /// No description provided for @husnaQuizCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get husnaQuizCorrect;

  /// No description provided for @husnaQuizWrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get husnaQuizWrong;

  /// No description provided for @husnaQuizScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} / {total}'**
  String husnaQuizScore(int score, int total);

  /// No description provided for @husnaQuizFinished.
  ///
  /// In en, this message translates to:
  /// **'Quiz Complete'**
  String get husnaQuizFinished;

  /// No description provided for @husnaNoNamesLearned.
  ///
  /// In en, this message translates to:
  /// **'Learn at least 4 names first to unlock quiz'**
  String get husnaNoNamesLearned;

  /// No description provided for @husnaNumber.
  ///
  /// In en, this message translates to:
  /// **'#{number}'**
  String husnaNumber(int number);

  /// No description provided for @husnaBenefit.
  ///
  /// In en, this message translates to:
  /// **'Reflection'**
  String get husnaBenefit;

  /// No description provided for @husnaMeaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get husnaMeaning;

  /// No description provided for @husnaNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get husnaNextQuestion;

  /// No description provided for @husnaStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get husnaStartQuiz;

  /// No description provided for @husnaRetryQuiz.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get husnaRetryQuiz;

  /// No description provided for @husnaSearch.
  ///
  /// In en, this message translates to:
  /// **'Search names...'**
  String get husnaSearch;

  /// No description provided for @husnaFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get husnaFilterAll;

  /// No description provided for @husnaFilterLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get husnaFilterLearned;

  /// No description provided for @husnaFilterNotLearned.
  ///
  /// In en, this message translates to:
  /// **'Not Learned'**
  String get husnaFilterNotLearned;

  /// No description provided for @husnaQuizProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String husnaQuizProgress(int current, int total);

  /// No description provided for @husnaQuizExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get husnaQuizExcellent;

  /// No description provided for @husnaQuizGoodEffort.
  ///
  /// In en, this message translates to:
  /// **'Good effort!'**
  String get husnaQuizGoodEffort;

  /// No description provided for @husnaQuizKeepLearning.
  ///
  /// In en, this message translates to:
  /// **'Keep learning!'**
  String get husnaQuizKeepLearning;

  /// No description provided for @husnaSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe to see next name'**
  String get husnaSwipeHint;

  /// No description provided for @husnaPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get husnaPronunciation;

  /// No description provided for @husnaCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {name}'**
  String husnaCorrectAnswer(String name);

  /// No description provided for @announcementDismiss.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get announcementDismiss;

  /// No description provided for @announcementTypeReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get announcementTypeReminder;

  /// No description provided for @announcementTypeAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcementTypeAnnouncement;

  /// No description provided for @announcementTypeDua.
  ///
  /// In en, this message translates to:
  /// **'Dua'**
  String get announcementTypeDua;

  /// No description provided for @announcementTypeHadith.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get announcementTypeHadith;

  /// No description provided for @adminSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminSectionTitle;

  /// No description provided for @adminAnnouncementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get adminAnnouncementsTitle;

  /// No description provided for @adminAmalFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Amal Fields'**
  String get adminAmalFieldsTitle;

  /// No description provided for @adminAmalFieldFormCreate.
  ///
  /// In en, this message translates to:
  /// **'Create amal field'**
  String get adminAmalFieldFormCreate;

  /// No description provided for @adminAmalFieldFormEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit amal field'**
  String get adminAmalFieldFormEdit;

  /// No description provided for @adminAmalFieldId.
  ///
  /// In en, this message translates to:
  /// **'Field ID'**
  String get adminAmalFieldId;

  /// No description provided for @adminAmalFieldLabelEn.
  ///
  /// In en, this message translates to:
  /// **'Label (English)'**
  String get adminAmalFieldLabelEn;

  /// No description provided for @adminAmalFieldLabelBn.
  ///
  /// In en, this message translates to:
  /// **'Label (Bengali, optional)'**
  String get adminAmalFieldLabelBn;

  /// No description provided for @adminAmalFieldSublabelEn.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get adminAmalFieldSublabelEn;

  /// No description provided for @adminAmalFieldSublabelBn.
  ///
  /// In en, this message translates to:
  /// **'Description (Bengali, optional)'**
  String get adminAmalFieldSublabelBn;

  /// No description provided for @adminAmalFieldPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get adminAmalFieldPoints;

  /// No description provided for @adminAmalFieldMaxValue.
  ///
  /// In en, this message translates to:
  /// **'Max value'**
  String get adminAmalFieldMaxValue;

  /// No description provided for @adminAmalFieldOrder.
  ///
  /// In en, this message translates to:
  /// **'Display order'**
  String get adminAmalFieldOrder;

  /// No description provided for @adminAmalFieldTypeBoolean.
  ///
  /// In en, this message translates to:
  /// **'Yes / No'**
  String get adminAmalFieldTypeBoolean;

  /// No description provided for @adminAmalFieldTypeNumeric.
  ///
  /// In en, this message translates to:
  /// **'Numeric'**
  String get adminAmalFieldTypeNumeric;

  /// No description provided for @adminAmalFieldIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Field ID is required.'**
  String get adminAmalFieldIdRequired;

  /// No description provided for @adminAmalFieldIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use lowercase letters, numbers, and underscores only.'**
  String get adminAmalFieldIdInvalid;

  /// No description provided for @adminAmalFieldLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'English label is required.'**
  String get adminAmalFieldLabelRequired;

  /// No description provided for @adminAmalFieldPointsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Points must be between 0 and 100.'**
  String get adminAmalFieldPointsInvalid;

  /// No description provided for @adminAmalFieldMaxValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Max value must be at least 1.'**
  String get adminAmalFieldMaxValueInvalid;

  /// No description provided for @adminAmalFieldOrderInvalid.
  ///
  /// In en, this message translates to:
  /// **'Order must be 0 or greater.'**
  String get adminAmalFieldOrderInvalid;

  /// No description provided for @adminAmalFieldSaved.
  ///
  /// In en, this message translates to:
  /// **'Amal field saved.'**
  String get adminAmalFieldSaved;

  /// No description provided for @adminAmalFieldSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save amal field.'**
  String get adminAmalFieldSaveFailed;

  /// No description provided for @adminAmalFieldToggleFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update amal field.'**
  String get adminAmalFieldToggleFailed;

  /// No description provided for @adminAmalFieldIdImmutable.
  ///
  /// In en, this message translates to:
  /// **'Field ID cannot be changed after creation.'**
  String get adminAmalFieldIdImmutable;

  /// No description provided for @adminAmalFieldPreviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Add an English label to preview.'**
  String get adminAmalFieldPreviewRequired;

  /// No description provided for @adminAmalFieldEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No amal fields yet. Tap + to create one.'**
  String get adminAmalFieldEmptyList;

  /// No description provided for @adminAmalFieldsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load amal fields.'**
  String get adminAmalFieldsLoadFailed;

  /// No description provided for @adminAmalFieldIdentitySection.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get adminAmalFieldIdentitySection;

  /// No description provided for @adminAmalFieldLabelsSection.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get adminAmalFieldLabelsSection;

  /// No description provided for @adminAmalFieldScoringSection.
  ///
  /// In en, this message translates to:
  /// **'Scoring'**
  String get adminAmalFieldScoringSection;

  /// No description provided for @adminAmalFieldDisplaySection.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get adminAmalFieldDisplaySection;

  /// No description provided for @adminAmalFieldIconSection.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get adminAmalFieldIconSection;

  /// No description provided for @adminAmalFieldIconSourceFa.
  ///
  /// In en, this message translates to:
  /// **'Font Awesome'**
  String get adminAmalFieldIconSourceFa;

  /// No description provided for @adminAmalFieldIconSourceMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get adminAmalFieldIconSourceMaterial;

  /// No description provided for @adminAmalFieldIconClear.
  ///
  /// In en, this message translates to:
  /// **'Clear icon'**
  String get adminAmalFieldIconClear;

  /// No description provided for @adminAmalFieldTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{id} · {type} · {points} · #{order}'**
  String adminAmalFieldTileSubtitle(
    String id,
    String type,
    String points,
    int order,
  );

  /// No description provided for @adminStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get adminStatusLive;

  /// No description provided for @adminStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get adminStatusScheduled;

  /// No description provided for @adminStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get adminStatusExpired;

  /// No description provided for @adminStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get adminStatusOff;

  /// No description provided for @adminFormType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminFormType;

  /// No description provided for @adminFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminFormTitle;

  /// No description provided for @adminFormMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get adminFormMessage;

  /// No description provided for @adminFormArabicText.
  ///
  /// In en, this message translates to:
  /// **'Arabic text (optional)'**
  String get adminFormArabicText;

  /// No description provided for @adminFormImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL (optional)'**
  String get adminFormImageUrl;

  /// No description provided for @adminFormActionUrl.
  ///
  /// In en, this message translates to:
  /// **'Action URL (optional)'**
  String get adminFormActionUrl;

  /// No description provided for @adminFormActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Button Text (optional)'**
  String get adminFormActionLabel;

  /// No description provided for @announcementActionDefault.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get announcementActionDefault;

  /// No description provided for @adminFormActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminFormActive;

  /// No description provided for @adminFormShowOnce.
  ///
  /// In en, this message translates to:
  /// **'Show once per user'**
  String get adminFormShowOnce;

  /// No description provided for @adminFormStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get adminFormStartsAt;

  /// No description provided for @adminFormExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires at'**
  String get adminFormExpiresAt;

  /// No description provided for @adminFormPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get adminFormPreview;

  /// No description provided for @adminFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminFormSave;

  /// No description provided for @adminFormClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get adminFormClearDate;

  /// No description provided for @adminFormCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create announcement'**
  String get adminFormCreateTitle;

  /// No description provided for @adminFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit announcement'**
  String get adminFormEditTitle;

  /// No description provided for @adminFormTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required.'**
  String get adminFormTitleRequired;

  /// No description provided for @adminFormMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message is required.'**
  String get adminFormMessageRequired;

  /// No description provided for @adminFormSaved.
  ///
  /// In en, this message translates to:
  /// **'Announcement saved.'**
  String get adminFormSaved;

  /// No description provided for @adminDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete announcement?'**
  String get adminDeleteTitle;

  /// No description provided for @adminDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get adminDeleteConfirm;

  /// No description provided for @adminEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet. Tap + to create one.'**
  String get adminEmptyList;

  /// No description provided for @adminNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this screen.'**
  String get adminNotAuthorized;

  /// No description provided for @adminLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load announcements.'**
  String get adminLoadFailed;

  /// No description provided for @adminSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save announcement.'**
  String get adminSaveFailed;

  /// No description provided for @adminDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete announcement.'**
  String get adminDeleteFailed;

  /// No description provided for @adminToggleFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update announcement.'**
  String get adminToggleFailed;

  /// No description provided for @adminDateRangeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Expires at must be after starts at.'**
  String get adminDateRangeInvalid;

  /// No description provided for @adminPreviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a title and message to preview.'**
  String get adminPreviewRequired;

  /// No description provided for @adminPushNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notification'**
  String get adminPushNotificationTitle;

  /// No description provided for @adminPushScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Push'**
  String get adminPushScreenTitle;

  /// No description provided for @adminPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminPushTitle;

  /// No description provided for @adminPushMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get adminPushMessage;

  /// No description provided for @adminPushType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminPushType;

  /// No description provided for @adminPushTypeSyllabusCourse.
  ///
  /// In en, this message translates to:
  /// **'Syllabus course'**
  String get adminPushTypeSyllabusCourse;

  /// No description provided for @adminPushTypeSyllabusReview.
  ///
  /// In en, this message translates to:
  /// **'Study review'**
  String get adminPushTypeSyllabusReview;

  /// No description provided for @adminPushTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required.'**
  String get adminPushTitleRequired;

  /// No description provided for @adminPushMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message is required.'**
  String get adminPushMessageRequired;

  /// No description provided for @adminPushSend.
  ///
  /// In en, this message translates to:
  /// **'Send to all users'**
  String get adminPushSend;

  /// No description provided for @adminPushSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent successfully.'**
  String get adminPushSent;

  /// No description provided for @adminPushFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification.'**
  String get adminPushFailed;

  /// No description provided for @adminPushGatewayNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Push gateway not configured.'**
  String get adminPushGatewayNotConfigured;

  /// No description provided for @adminPushGatewayKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Gateway key missing. Run with --dart-define=DUA_PUSH_GATEWAY_KEY=your_key'**
  String get adminPushGatewayKeyMissing;

  /// No description provided for @adminPushAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get adminPushAudience;

  /// No description provided for @adminPushBroadcast.
  ///
  /// In en, this message translates to:
  /// **'All users'**
  String get adminPushBroadcast;

  /// No description provided for @adminPushSingleUser.
  ///
  /// In en, this message translates to:
  /// **'Specific user'**
  String get adminPushSingleUser;

  /// No description provided for @adminPushSearchUser.
  ///
  /// In en, this message translates to:
  /// **'Search by email or name…'**
  String get adminPushSearchUser;

  /// No description provided for @adminPushNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminPushNoUsersFound;

  /// No description provided for @adminPushUserSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected user'**
  String get adminPushUserSelected;

  /// No description provided for @adminPushSendToUser.
  ///
  /// In en, this message translates to:
  /// **'Send to {name}'**
  String adminPushSendToUser(String name);

  /// No description provided for @adminPushSelectUser.
  ///
  /// In en, this message translates to:
  /// **'Select a user to target'**
  String get adminPushSelectUser;

  /// No description provided for @adminCoursesTitle.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get adminCoursesTitle;

  /// No description provided for @adminCourseCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create course'**
  String get adminCourseCreateTitle;

  /// No description provided for @adminCourseEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit course'**
  String get adminCourseEditTitle;

  /// No description provided for @adminCourseEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No courses yet. Tap + to create one.'**
  String get adminCourseEmptyList;

  /// No description provided for @adminCourseLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load courses.'**
  String get adminCourseLoadFailed;

  /// No description provided for @adminCourseDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete course?'**
  String get adminCourseDeleteTitle;

  /// No description provided for @adminCourseDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete course.'**
  String get adminCourseDeleteFailed;

  /// No description provided for @adminCoursePublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update course status.'**
  String get adminCoursePublishFailed;

  /// No description provided for @adminCourseFormSaved.
  ///
  /// In en, this message translates to:
  /// **'Course saved.'**
  String get adminCourseFormSaved;

  /// No description provided for @adminCoursePublishedPushTitle.
  ///
  /// In en, this message translates to:
  /// **'New course available'**
  String get adminCoursePublishedPushTitle;

  /// No description provided for @adminCoursePublishedPushMessage.
  ///
  /// In en, this message translates to:
  /// **'A new syllabus course is live: {title}. Open Syllabus to enroll.'**
  String adminCoursePublishedPushMessage(String title);

  /// No description provided for @adminCourseManageLessons.
  ///
  /// In en, this message translates to:
  /// **'Manage lessons'**
  String get adminCourseManageLessons;

  /// No description provided for @adminCourseDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminCourseDescription;

  /// No description provided for @adminCourseDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required.'**
  String get adminCourseDescriptionRequired;

  /// No description provided for @adminCourseCoverUrl.
  ///
  /// In en, this message translates to:
  /// **'Cover image URL (optional)'**
  String get adminCourseCoverUrl;

  /// No description provided for @adminCourseTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma-separated)'**
  String get adminCourseTags;

  /// No description provided for @adminCourseModerators.
  ///
  /// In en, this message translates to:
  /// **'Moderator emails (comma-separated)'**
  String get adminCourseModerators;

  /// No description provided for @adminCourseDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Course details'**
  String get adminCourseDetailsSection;

  /// No description provided for @adminCourseModeratorsSection.
  ///
  /// In en, this message translates to:
  /// **'Moderators'**
  String get adminCourseModeratorsSection;

  /// No description provided for @adminCourseStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminCourseStatusSection;

  /// No description provided for @adminCourseStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminCourseStatusPublished;

  /// No description provided for @adminCourseStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get adminCourseStatusDraft;

  /// No description provided for @adminLessonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get adminLessonsTitle;

  /// No description provided for @adminLessonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder lessons. Toggle publish when ready.'**
  String get adminLessonsSubtitle;

  /// No description provided for @adminLessonCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add lesson'**
  String get adminLessonCreateTitle;

  /// No description provided for @adminLessonEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit lesson'**
  String get adminLessonEditTitle;

  /// No description provided for @adminLessonEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No lessons yet. Tap + to add one.'**
  String get adminLessonEmptyList;

  /// No description provided for @adminLessonLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load lessons.'**
  String get adminLessonLoadFailed;

  /// No description provided for @adminLessonDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete lesson?'**
  String get adminLessonDeleteTitle;

  /// No description provided for @adminLessonDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete lesson.'**
  String get adminLessonDeleteFailed;

  /// No description provided for @adminLessonReorderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save lesson order.'**
  String get adminLessonReorderFailed;

  /// No description provided for @adminLessonFormSaved.
  ///
  /// In en, this message translates to:
  /// **'Lesson saved.'**
  String get adminLessonFormSaved;

  /// No description provided for @adminLessonDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Lesson details'**
  String get adminLessonDetailsSection;

  /// No description provided for @adminLessonResourceType.
  ///
  /// In en, this message translates to:
  /// **'Resource type'**
  String get adminLessonResourceType;

  /// No description provided for @adminLessonTypeYoutube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get adminLessonTypeYoutube;

  /// No description provided for @adminLessonTypePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get adminLessonTypePdf;

  /// No description provided for @adminLessonTypeLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get adminLessonTypeLink;

  /// No description provided for @adminLessonTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get adminLessonTypeText;

  /// No description provided for @adminLessonTypeAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get adminLessonTypeAudio;

  /// No description provided for @adminLessonAudioUrl.
  ///
  /// In en, this message translates to:
  /// **'Audio file URL (MP3/M4A)'**
  String get adminLessonAudioUrl;

  /// No description provided for @adminLessonAudioUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http(s) URL ending in .mp3 or .m4a.'**
  String get adminLessonAudioUrlInvalid;

  /// No description provided for @adminLessonYoutubeUrl.
  ///
  /// In en, this message translates to:
  /// **'YouTube URL'**
  String get adminLessonYoutubeUrl;

  /// No description provided for @adminLessonPdfUrl.
  ///
  /// In en, this message translates to:
  /// **'PDF URL'**
  String get adminLessonPdfUrl;

  /// No description provided for @adminLessonLinkUrl.
  ///
  /// In en, this message translates to:
  /// **'Link URL'**
  String get adminLessonLinkUrl;

  /// No description provided for @adminLessonTextContent.
  ///
  /// In en, this message translates to:
  /// **'Text content'**
  String get adminLessonTextContent;

  /// No description provided for @adminLessonResourceUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Resource URL or content is required.'**
  String get adminLessonResourceUrlRequired;

  /// No description provided for @adminLessonThumbnailUrl.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail URL (optional)'**
  String get adminLessonThumbnailUrl;

  /// No description provided for @adminLessonDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes, optional)'**
  String get adminLessonDuration;

  /// No description provided for @adminLessonPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminLessonPublished;

  /// No description provided for @adminQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get adminQuizTitle;

  /// No description provided for @adminQuizCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create quiz'**
  String get adminQuizCreateTitle;

  /// No description provided for @adminQuizEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit quiz'**
  String get adminQuizEditTitle;

  /// No description provided for @adminQuizFormSaved.
  ///
  /// In en, this message translates to:
  /// **'Quiz saved.'**
  String get adminQuizFormSaved;

  /// No description provided for @adminQuizDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Quiz settings'**
  String get adminQuizDetailsSection;

  /// No description provided for @adminQuizLinkedLesson.
  ///
  /// In en, this message translates to:
  /// **'Linked lesson (optional)'**
  String get adminQuizLinkedLesson;

  /// No description provided for @adminQuizScopeCourse.
  ///
  /// In en, this message translates to:
  /// **'Course-level quiz'**
  String get adminQuizScopeCourse;

  /// No description provided for @adminQuizTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time limit (seconds, 0 = none)'**
  String get adminQuizTimeLimit;

  /// No description provided for @adminQuizPassingScore.
  ///
  /// In en, this message translates to:
  /// **'Passing score (correct answers needed)'**
  String get adminQuizPassingScore;

  /// No description provided for @adminQuizQuestionsSection.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get adminQuizQuestionsSection;

  /// No description provided for @adminQuizQuestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No questions yet. Add at least one before saving.'**
  String get adminQuizQuestionsEmpty;

  /// No description provided for @adminQuizEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet.'**
  String get adminQuizEmptyList;

  /// No description provided for @adminQuizQuestionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one question.'**
  String get adminQuizQuestionsRequired;

  /// No description provided for @adminQuizPassingScoreTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Passing score cannot exceed question count.'**
  String get adminQuizPassingScoreTooHigh;

  /// No description provided for @adminQuizAddQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get adminQuizAddQuestion;

  /// No description provided for @adminQuizQuestionCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get adminQuizQuestionCreateTitle;

  /// No description provided for @adminQuizQuestionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit question'**
  String get adminQuizQuestionEditTitle;

  /// No description provided for @adminQuizQuestionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete question?'**
  String get adminQuizQuestionDeleteTitle;

  /// No description provided for @adminQuizQuestionTextSection.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get adminQuizQuestionTextSection;

  /// No description provided for @adminQuizQuestionText.
  ///
  /// In en, this message translates to:
  /// **'Question text'**
  String get adminQuizQuestionText;

  /// No description provided for @adminQuizQuestionTextRequired.
  ///
  /// In en, this message translates to:
  /// **'Question text is required.'**
  String get adminQuizQuestionTextRequired;

  /// No description provided for @adminQuizOptionsSection.
  ///
  /// In en, this message translates to:
  /// **'Answer options'**
  String get adminQuizOptionsSection;

  /// No description provided for @adminQuizSelectCorrectHint.
  ///
  /// In en, this message translates to:
  /// **'Select the radio button for the correct answer.'**
  String get adminQuizSelectCorrectHint;

  /// No description provided for @adminQuizOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String adminQuizOptionLabel(int number);

  /// No description provided for @adminQuizOptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Option is required.'**
  String get adminQuizOptionRequired;

  /// No description provided for @adminQuizOptionsMinRequired.
  ///
  /// In en, this message translates to:
  /// **'At least two options are required.'**
  String get adminQuizOptionsMinRequired;

  /// No description provided for @adminQuizCorrectAnswerRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a correct answer with text.'**
  String get adminQuizCorrectAnswerRequired;

  /// No description provided for @adminQuizExplanationSection.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get adminQuizExplanationSection;

  /// No description provided for @adminQuizExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation (shown after quiz)'**
  String get adminQuizExplanation;

  /// No description provided for @adminQuizQuestionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminQuizQuestionDone;

  /// No description provided for @adminQuizCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String adminQuizCorrectAnswer(String answer);

  /// No description provided for @adminQuizOptionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} opts'**
  String adminQuizOptionCount(int count);

  /// No description provided for @syllabusTitle.
  ///
  /// In en, this message translates to:
  /// **'Syllabus'**
  String get syllabusTitle;

  /// No description provided for @syllabusSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search courses…'**
  String get syllabusSearchHint;

  /// No description provided for @syllabusEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No published courses yet.'**
  String get syllabusEmptyList;

  /// No description provided for @syllabusLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load courses.'**
  String get syllabusLoadFailed;

  /// No description provided for @syllabusNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No courses match your search.'**
  String get syllabusNoSearchResults;

  /// No description provided for @syllabusAllTags.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get syllabusAllTags;

  /// No description provided for @syllabusEnroll.
  ///
  /// In en, this message translates to:
  /// **'Enroll'**
  String get syllabusEnroll;

  /// No description provided for @syllabusEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get syllabusEnrolled;

  /// No description provided for @syllabusEnrollPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enroll to track your progress through this course.'**
  String get syllabusEnrollPrompt;

  /// No description provided for @syllabusEnrollSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re enrolled!'**
  String get syllabusEnrollSuccess;

  /// No description provided for @syllabusProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} lessons'**
  String syllabusProgressLabel(int completed, int total);

  /// No description provided for @syllabusCourseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Course completed'**
  String get syllabusCourseCompleted;

  /// No description provided for @syllabusLessonsSection.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get syllabusLessonsSection;

  /// No description provided for @syllabusNoLessons.
  ///
  /// In en, this message translates to:
  /// **'No lessons published yet.'**
  String get syllabusNoLessons;

  /// No description provided for @syllabusLessonCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons'**
  String syllabusLessonCount(int count);

  /// No description provided for @syllabusCourseLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load course.'**
  String get syllabusCourseLoadFailed;

  /// No description provided for @syllabusLessonLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load lesson.'**
  String get syllabusLessonLoadFailed;

  /// No description provided for @syllabusMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as complete'**
  String get syllabusMarkComplete;

  /// No description provided for @syllabusLessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lesson completed'**
  String get syllabusLessonCompleted;

  /// No description provided for @syllabusLessonCompleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Progress saved!'**
  String get syllabusLessonCompleteSuccess;

  /// No description provided for @syllabusEnrollToComplete.
  ///
  /// In en, this message translates to:
  /// **'Enroll in this course to track lesson progress.'**
  String get syllabusEnrollToComplete;

  /// No description provided for @syllabusOpenPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get syllabusOpenPdf;

  /// No description provided for @syllabusOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get syllabusOpenLink;

  /// No description provided for @syllabusInvalidYoutubeUrl.
  ///
  /// In en, this message translates to:
  /// **'This lesson has an invalid YouTube URL.'**
  String get syllabusInvalidYoutubeUrl;

  /// No description provided for @syllabusVideoNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get syllabusVideoNowPlaying;

  /// No description provided for @syllabusVideoRewind.
  ///
  /// In en, this message translates to:
  /// **'Rewind 10s'**
  String get syllabusVideoRewind;

  /// No description provided for @syllabusVideoForward.
  ///
  /// In en, this message translates to:
  /// **'Forward 10s'**
  String get syllabusVideoForward;

  /// No description provided for @syllabusVideoRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get syllabusVideoRestart;

  /// No description provided for @syllabusVideoMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get syllabusVideoMute;

  /// No description provided for @syllabusVideoUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get syllabusVideoUnmute;

  /// No description provided for @syllabusVideoOpenYoutube.
  ///
  /// In en, this message translates to:
  /// **'Open in YouTube'**
  String get syllabusVideoOpenYoutube;

  /// No description provided for @syllabusLaunchUrlFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this resource.'**
  String get syllabusLaunchUrlFailed;

  /// No description provided for @syllabusQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get syllabusQuizTitle;

  /// No description provided for @syllabusQuizLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this quiz.'**
  String get syllabusQuizLoadFailed;

  /// No description provided for @syllabusQuizRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get syllabusQuizRulesTitle;

  /// No description provided for @syllabusQuizQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String syllabusQuizQuestionCount(int count);

  /// No description provided for @syllabusQuizTimeLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Time limit: {limit}'**
  String syllabusQuizTimeLimitLabel(String limit);

  /// No description provided for @syllabusQuizNoTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get syllabusQuizNoTimeLimit;

  /// No description provided for @syllabusQuizPassingScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Pass with {score} correct answers'**
  String syllabusQuizPassingScoreLabel(int score);

  /// No description provided for @syllabusQuizPreviousAttempts.
  ///
  /// In en, this message translates to:
  /// **'Your attempts'**
  String get syllabusQuizPreviousAttempts;

  /// No description provided for @syllabusQuizAttemptCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attempt(s)'**
  String syllabusQuizAttemptCount(int count);

  /// No description provided for @syllabusQuizAttemptNumber.
  ///
  /// In en, this message translates to:
  /// **'Attempt #{number}'**
  String syllabusQuizAttemptNumber(int number);

  /// No description provided for @syllabusQuizAttemptsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} attempt(s) · best {score}/{total}'**
  String syllabusQuizAttemptsLabel(int count, int score, int total);

  /// No description provided for @syllabusQuizAttemptHistoryRow.
  ///
  /// In en, this message translates to:
  /// **'{score}/{total} · {date}'**
  String syllabusQuizAttemptHistoryRow(int score, int total, String date);

  /// No description provided for @syllabusQuizAttemptPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get syllabusQuizAttemptPassed;

  /// No description provided for @syllabusQuizAttemptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get syllabusQuizAttemptFailed;

  /// No description provided for @syllabusQuizBestScore.
  ///
  /// In en, this message translates to:
  /// **'Best score: {score} / {total}'**
  String syllabusQuizBestScore(int score, int total);

  /// No description provided for @syllabusQuizAlreadyPassed.
  ///
  /// In en, this message translates to:
  /// **'You passed this quiz'**
  String get syllabusQuizAlreadyPassed;

  /// No description provided for @syllabusQuizStart.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get syllabusQuizStart;

  /// No description provided for @syllabusQuizProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String syllabusQuizProgress(int current, int total);

  /// No description provided for @syllabusQuizQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get syllabusQuizQuestionLabel;

  /// No description provided for @syllabusQuizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get syllabusQuizNext;

  /// No description provided for @syllabusQuizPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get syllabusQuizPrevious;

  /// No description provided for @syllabusQuizSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get syllabusQuizSubmit;

  /// No description provided for @syllabusQuizTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get syllabusQuizTimeRemaining;

  /// No description provided for @syllabusQuizTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time is up — submitting your answers.'**
  String get syllabusQuizTimeUp;

  /// No description provided for @syllabusQuizConfirmExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave quiz?'**
  String get syllabusQuizConfirmExitTitle;

  /// No description provided for @syllabusQuizConfirmExitMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress on this attempt will be lost.'**
  String get syllabusQuizConfirmExitMessage;

  /// No description provided for @syllabusQuizLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get syllabusQuizLeave;

  /// No description provided for @syllabusQuizResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz result'**
  String get syllabusQuizResultTitle;

  /// No description provided for @syllabusQuizResultPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed!'**
  String get syllabusQuizResultPassed;

  /// No description provided for @syllabusQuizResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Not passed'**
  String get syllabusQuizResultFailed;

  /// No description provided for @syllabusQuizYourScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} / {total}'**
  String syllabusQuizYourScore(int score, int total);

  /// No description provided for @syllabusQuizTimeTaken.
  ///
  /// In en, this message translates to:
  /// **'Time taken: {time}'**
  String syllabusQuizTimeTaken(String time);

  /// No description provided for @syllabusQuizReviewSection.
  ///
  /// In en, this message translates to:
  /// **'Answer review'**
  String get syllabusQuizReviewSection;

  /// No description provided for @syllabusQuizReviewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String syllabusQuizReviewQuestion(int number);

  /// No description provided for @syllabusQuizYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get syllabusQuizYourAnswer;

  /// No description provided for @syllabusQuizCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get syllabusQuizCorrectAnswer;

  /// No description provided for @syllabusQuizExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get syllabusQuizExplanation;

  /// No description provided for @syllabusQuizRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get syllabusQuizRetry;

  /// No description provided for @syllabusQuizBackToCourse.
  ///
  /// In en, this message translates to:
  /// **'Back to course'**
  String get syllabusQuizBackToCourse;

  /// No description provided for @syllabusQuizExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get syllabusQuizExcellent;

  /// No description provided for @syllabusQuizGoodEffort.
  ///
  /// In en, this message translates to:
  /// **'Good effort!'**
  String get syllabusQuizGoodEffort;

  /// No description provided for @syllabusQuizKeepLearning.
  ///
  /// In en, this message translates to:
  /// **'Keep learning!'**
  String get syllabusQuizKeepLearning;

  /// No description provided for @syllabusQuizNotReady.
  ///
  /// In en, this message translates to:
  /// **'This quiz is not ready yet.'**
  String get syllabusQuizNotReady;

  /// No description provided for @syllabusQuizBismillahTitle.
  ///
  /// In en, this message translates to:
  /// **'Begin with Bismillah'**
  String get syllabusQuizBismillahTitle;

  /// No description provided for @syllabusQuizBismillahArabic.
  ///
  /// In en, this message translates to:
  /// **'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'**
  String get syllabusQuizBismillahArabic;

  /// No description provided for @syllabusQuizBismillahTranslation.
  ///
  /// In en, this message translates to:
  /// **'In the name of Allah, the Most Gracious, the Most Merciful.'**
  String get syllabusQuizBismillahTranslation;

  /// No description provided for @syllabusQuizBismillahIntention.
  ///
  /// In en, this message translates to:
  /// **'O Allah, grant me beneficial knowledge and a sound understanding.'**
  String get syllabusQuizBismillahIntention;

  /// No description provided for @syllabusQuizBismillahBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin quiz'**
  String get syllabusQuizBismillahBegin;

  /// No description provided for @lmsXpSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning progress'**
  String get lmsXpSectionTitle;

  /// No description provided for @lmsXpLabel.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String lmsXpLabel(int xp);

  /// No description provided for @lmsXpToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to next level'**
  String lmsXpToNextLevel(int xp);

  /// No description provided for @lmsLevelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Level up!'**
  String get lmsLevelUpTitle;

  /// No description provided for @lmsLevelUpTapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get lmsLevelUpTapToContinue;

  /// No description provided for @lessonDiscussionTitle.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get lessonDiscussionTitle;

  /// No description provided for @lessonDiscussionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Start the conversation with your study group.'**
  String get lessonDiscussionEmpty;

  /// No description provided for @lessonDiscussionHint.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts on this lesson…'**
  String get lessonDiscussionHint;

  /// No description provided for @lessonDiscussionPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get lessonDiscussionPost;

  /// No description provided for @lessonDiscussionPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not post comment. Try again.'**
  String get lessonDiscussionPostFailed;

  /// No description provided for @lessonDiscussionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load discussion.'**
  String get lessonDiscussionLoadFailed;

  /// No description provided for @lessonDiscussionEnrollPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enroll in this course to join the discussion.'**
  String get lessonDiscussionEnrollPrompt;

  /// No description provided for @lessonDiscussionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get lessonDiscussionEditTitle;

  /// No description provided for @lessonDiscussionEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save comment. Try again.'**
  String get lessonDiscussionEditFailed;

  /// No description provided for @lessonDiscussionEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get lessonDiscussionEdited;

  /// No description provided for @courseCertificateTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate of Completion'**
  String get courseCertificateTitle;

  /// No description provided for @courseCertificateArabic.
  ///
  /// In en, this message translates to:
  /// **'بارك الله فيك'**
  String get courseCertificateArabic;

  /// No description provided for @courseCertificatePresentedTo.
  ///
  /// In en, this message translates to:
  /// **'Presented to'**
  String get courseCertificatePresentedTo;

  /// No description provided for @courseCertificateForCourse.
  ///
  /// In en, this message translates to:
  /// **'For completing the course'**
  String get courseCertificateForCourse;

  /// No description provided for @courseCertificateDate.
  ///
  /// In en, this message translates to:
  /// **'Completed on {date}'**
  String courseCertificateDate(String date);

  /// No description provided for @courseCertificateShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get courseCertificateShare;

  /// No description provided for @courseCertificateView.
  ///
  /// In en, this message translates to:
  /// **'View certificate'**
  String get courseCertificateView;

  /// No description provided for @syllabusBookmarkedFilter.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get syllabusBookmarkedFilter;

  /// No description provided for @syllabusBookmarksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bookmarked lessons yet.'**
  String get syllabusBookmarksEmpty;

  /// No description provided for @syllabusAudioLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this audio lesson.'**
  String get syllabusAudioLoadFailed;

  /// No description provided for @quranTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranTitle;

  /// No description provided for @quranSurahList.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get quranSurahList;

  /// No description provided for @quranReader.
  ///
  /// In en, this message translates to:
  /// **'Mushaf Reader'**
  String get quranReader;

  /// No description provided for @quranMeccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get quranMeccan;

  /// No description provided for @quranMedinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get quranMedinan;

  /// No description provided for @quranAyahs.
  ///
  /// In en, this message translates to:
  /// **'{count} Ayahs'**
  String quranAyahs(int count);

  /// No description provided for @quranPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String quranPage(int page);

  /// No description provided for @quranJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz}'**
  String quranJuz(int juz);

  /// No description provided for @quranTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get quranTranslation;

  /// No description provided for @quranSelectTranslator.
  ///
  /// In en, this message translates to:
  /// **'Select Translator'**
  String get quranSelectTranslator;

  /// No description provided for @quranSelectQari.
  ///
  /// In en, this message translates to:
  /// **'Select Qari'**
  String get quranSelectQari;

  /// No description provided for @quranTranslatorKhan.
  ///
  /// In en, this message translates to:
  /// **'Muhiuddin Khan'**
  String get quranTranslatorKhan;

  /// No description provided for @quranTranslatorSahih.
  ///
  /// In en, this message translates to:
  /// **'Sahih International'**
  String get quranTranslatorSahih;

  /// No description provided for @quranSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search surahs...'**
  String get quranSearchHint;

  /// No description provided for @quranContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue from page {page}'**
  String quranContinueReading(int page);

  /// No description provided for @quranOpenReader.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get quranOpenReader;

  /// No description provided for @quranFontSize.
  ///
  /// In en, this message translates to:
  /// **'Arabic text size'**
  String get quranFontSize;

  /// No description provided for @quranNoTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation hidden or unavailable'**
  String get quranNoTranslation;

  /// No description provided for @quranAyahLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayah {ayah}'**
  String quranAyahLabel(int ayah);

  /// No description provided for @quranJumpToPage.
  ///
  /// In en, this message translates to:
  /// **'Jump to page'**
  String get quranJumpToPage;

  /// No description provided for @quranJumpToSurah.
  ///
  /// In en, this message translates to:
  /// **'Jump to surah'**
  String get quranJumpToSurah;

  /// No description provided for @quranMushafMode.
  ///
  /// In en, this message translates to:
  /// **'Mushaf view'**
  String get quranMushafMode;

  /// No description provided for @quranSurahMode.
  ///
  /// In en, this message translates to:
  /// **'Surah list'**
  String get quranSurahMode;

  /// No description provided for @quranPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String quranPageOf(int page, int total);

  /// No description provided for @quranTranslationFontSize.
  ///
  /// In en, this message translates to:
  /// **'Translation text size'**
  String get quranTranslationFontSize;

  /// No description provided for @quranPageTheme.
  ///
  /// In en, this message translates to:
  /// **'Page theme'**
  String get quranPageTheme;

  /// No description provided for @quranJumpToAyah.
  ///
  /// In en, this message translates to:
  /// **'Jump to ayah'**
  String get quranJumpToAyah;

  /// No description provided for @quranJumpToAyahHint.
  ///
  /// In en, this message translates to:
  /// **'Enter ayah number'**
  String get quranJumpToAyahHint;

  /// No description provided for @quranAyahCopied.
  ///
  /// In en, this message translates to:
  /// **'Ayah copied to clipboard'**
  String get quranAyahCopied;

  /// No description provided for @qiblaTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaTitle;

  /// No description provided for @qiblaGrantLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Location Permission'**
  String get qiblaGrantLocationPermission;

  /// No description provided for @qiblaOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get qiblaOpenSettings;

  /// No description provided for @qiblaNorth.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get qiblaNorth;

  /// No description provided for @qiblaEast.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get qiblaEast;

  /// No description provided for @qiblaSouth.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get qiblaSouth;

  /// No description provided for @qiblaWest.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get qiblaWest;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @historyLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get historyLight;

  /// No description provided for @historyMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get historyMinimal;

  /// No description provided for @historyMotivationFull.
  ///
  /// In en, this message translates to:
  /// **'MashaAllah! You have completed full amal for {days} days this month. May Allah accept it.'**
  String historyMotivationFull(int days);

  /// No description provided for @historyMotivationPartial.
  ///
  /// In en, this message translates to:
  /// **'You are trying regularly — that is the most important thing. It will gradually increase InshaAllah.'**
  String get historyMotivationPartial;

  /// No description provided for @historyMotivationMinimal.
  ///
  /// In en, this message translates to:
  /// **'Every small amal is valuable to Allah. Try to do a little more today.'**
  String get historyMotivationMinimal;

  /// No description provided for @historyMotivationNoData.
  ///
  /// In en, this message translates to:
  /// **'No logs for a few days — no problem. Start again from today, Allah is Most Forgiving.'**
  String get historyMotivationNoData;

  /// No description provided for @historyMotivationDefault.
  ///
  /// In en, this message translates to:
  /// **'Log your amal daily — even small but regular amal is best.'**
  String get historyMotivationDefault;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @streakSheetLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get streakSheetLast7Days;

  /// No description provided for @streakSheetPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get streakSheetPrevious;

  /// No description provided for @streakSheetNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get streakSheetNext;

  /// No description provided for @streakSheetCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get streakSheetCompleted;

  /// No description provided for @streakSheetMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get streakSheetMissed;

  /// No description provided for @streakSheetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get streakSheetToday;

  /// No description provided for @streakSheetPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get streakSheetPending;

  /// No description provided for @streakSheetPreAccount.
  ///
  /// In en, this message translates to:
  /// **'Before account'**
  String get streakSheetPreAccount;

  /// No description provided for @streakSheetNoLog.
  ///
  /// In en, this message translates to:
  /// **'No log submitted for this day'**
  String get streakSheetNoLog;

  /// No description provided for @streakSheetNotYetSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Log not submitted yet'**
  String get streakSheetNotYetSubmitted;

  /// No description provided for @streakSheetFreezeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Freeze available'**
  String get streakSheetFreezeAvailable;

  /// No description provided for @streakSheetFreezeUsed.
  ///
  /// In en, this message translates to:
  /// **'Freeze used this week'**
  String get streakSheetFreezeUsed;

  /// No description provided for @streakSheetScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get streakSheetScore;

  /// No description provided for @streakSheetBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get streakSheetBestStreak;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReports;

  /// No description provided for @reportsWeeklyTab.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reportsWeeklyTab;

  /// No description provided for @reportsMonthlyTab.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get reportsMonthlyTab;

  /// No description provided for @reportsCustomTab.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportsCustomTab;

  /// No description provided for @reportsWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly report'**
  String get reportsWeeklyTitle;

  /// No description provided for @reportsMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly report'**
  String get reportsMonthlyTitle;

  /// No description provided for @reportsCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom report'**
  String get reportsCustomTitle;

  /// No description provided for @reportsAvgScore.
  ///
  /// In en, this message translates to:
  /// **'avg score / 100'**
  String get reportsAvgScore;

  /// No description provided for @reportsDaysLogged.
  ///
  /// In en, this message translates to:
  /// **'{logged}/{total} days logged'**
  String reportsDaysLogged(Object logged, Object total);

  /// No description provided for @reportsCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'current streak'**
  String get reportsCurrentStreak;

  /// No description provided for @reportsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'best streak'**
  String get reportsBestStreak;

  /// No description provided for @reportsConsistency.
  ///
  /// In en, this message translates to:
  /// **'consistency'**
  String get reportsConsistency;

  /// No description provided for @reportsBestDayScore.
  ///
  /// In en, this message translates to:
  /// **'best day score'**
  String get reportsBestDayScore;

  /// No description provided for @reportsCommunityRank.
  ///
  /// In en, this message translates to:
  /// **'community rank'**
  String get reportsCommunityRank;

  /// No description provided for @reportsRankUnavailable.
  ///
  /// In en, this message translates to:
  /// **'current period only'**
  String get reportsRankUnavailable;

  /// No description provided for @reportsDaysInRange.
  ///
  /// In en, this message translates to:
  /// **'days in range'**
  String get reportsDaysInRange;

  /// No description provided for @reportsDaysLoggedLabel.
  ///
  /// In en, this message translates to:
  /// **'days logged'**
  String get reportsDaysLoggedLabel;

  /// No description provided for @reportsChartDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily scores'**
  String get reportsChartDaily;

  /// No description provided for @reportsChartWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly avg scores'**
  String get reportsChartWeekly;

  /// No description provided for @reportsAmalBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Amal Performance'**
  String get reportsAmalBreakdown;

  /// No description provided for @reportsInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get reportsInsights;

  /// No description provided for @reportsBestDayInsight.
  ///
  /// In en, this message translates to:
  /// **'Best day was {day} with a score of {score}/100'**
  String reportsBestDayInsight(Object day, Object score);

  /// No description provided for @reportsWeakestAmalInsight.
  ///
  /// In en, this message translates to:
  /// **'Weakest amal: {label} — completed {done} of {total} days'**
  String reportsWeakestAmalInsight(Object label, Object done, Object total);

  /// No description provided for @reportsStrongestAmalInsight.
  ///
  /// In en, this message translates to:
  /// **'Strongest amal: {label} — completed {done} of {total} days'**
  String reportsStrongestAmalInsight(Object label, Object done, Object total);

  /// No description provided for @reportsTrendUp.
  ///
  /// In en, this message translates to:
  /// **'Score improved by +{points} pts vs previous period'**
  String reportsTrendUp(Object points);

  /// No description provided for @reportsTrendDown.
  ///
  /// In en, this message translates to:
  /// **'Score dropped by {points} pts vs previous period'**
  String reportsTrendDown(Object points);

  /// No description provided for @reportsTrendFlat.
  ///
  /// In en, this message translates to:
  /// **'Score is unchanged vs previous period'**
  String get reportsTrendFlat;

  /// No description provided for @reportsRankInsight.
  ///
  /// In en, this message translates to:
  /// **'You ranked #{rank} in the community this period'**
  String reportsRankInsight(Object rank);

  /// No description provided for @reportsHadithOfPeriod.
  ///
  /// In en, this message translates to:
  /// **'Hadith of the period'**
  String get reportsHadithOfPeriod;

  /// No description provided for @reportsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get reportsShare;

  /// No description provided for @reportsSharing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get reportsSharing;

  /// No description provided for @reportsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load report right now.'**
  String get reportsLoadFailed;

  /// No description provided for @reportsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get reportsRetry;

  /// No description provided for @reportsEmptyPeriod.
  ///
  /// In en, this message translates to:
  /// **'No amal logs in this period yet. Start logging to see your report.'**
  String get reportsEmptyPeriod;

  /// No description provided for @reportsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get reportsThisWeek;

  /// No description provided for @reportsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get reportsThisMonth;

  /// No description provided for @reportsCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get reportsCustomRange;

  /// No description provided for @reportsPickRange.
  ///
  /// In en, this message translates to:
  /// **'Pick date range'**
  String get reportsPickRange;

  /// No description provided for @reportsSelectStart.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get reportsSelectStart;

  /// No description provided for @reportsSelectEnd.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get reportsSelectEnd;

  /// No description provided for @reportsApplyRange.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get reportsApplyRange;

  /// No description provided for @reportsCustomRangeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Maximum range is 90 days.'**
  String get reportsCustomRangeTooLong;

  /// No description provided for @reportsInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'End date must be on or after start date.'**
  String get reportsInvalidRange;

  /// No description provided for @reportsRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a start date, then an end date (max 90 days).'**
  String get reportsRangeHint;

  /// No description provided for @reportsEmDash.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get reportsEmDash;
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
