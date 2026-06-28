// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'আমল ট্র্যাকার';

  @override
  String get settings => 'সেটিংস';

  @override
  String get notificationsSection => 'নোটিফিকেশন';

  @override
  String get privacySection => 'প্রাইভেসি';

  @override
  String get appSection => 'অ্যাপ';

  @override
  String get languageSection => 'ভাষা';

  @override
  String get language => 'ভাষা';

  @override
  String get english => 'English';

  @override
  String get bangla => 'বাংলা';

  @override
  String get morningNotification => 'সকালের নোটিফিকেশন';

  @override
  String get morningNotificationTime => 'প্রতি সকাল ৬:০০ AM';

  @override
  String get morningNotificationTimeLabel => 'সকালের সময়';

  @override
  String get eveningNotification => 'সন্ধ্যার নোটিফিকেশন';

  @override
  String get eveningNotificationTime => 'প্রতি সন্ধ্যা ৬:৩০ PM';

  @override
  String get eveningNotificationTimeLabel => 'সন্ধ্যার সময়';

  @override
  String get notificationTimeTapToChange => 'ট্যাপ করে সময় পরিবর্তন করুন';

  @override
  String get streakWarning => 'স্ট্রিক ওয়ার্নিং';

  @override
  String get streakWarningSubtitle => 'স্ট্রিক হারানোর আগে জানিয়ে দেবে';

  @override
  String get communityActivity => 'কমিউনিটি অ্যাক্টিভিটি';

  @override
  String get communityActivitySubtitle => 'কমিউনিটি থেকে আপডেট পাবেন';

  @override
  String get studyReviewReminder => 'অধ্যয়ন পুনরালোচনা';

  @override
  String get studyReviewReminderSubtitle =>
      'এনরোল করা পাঠের স্পেসড রিভিউ অনুস্মারক';

  @override
  String get notificationTypeStudyReview => 'অধ্যয়ন পুনরালোচনা';

  @override
  String get reminderTimes => 'রিমাইন্ডার সময়';

  @override
  String get reminderTimesDescription =>
      'সকালের ও সন্ধ্যার নোটিফিকেশনের নির্দিষ্ট সময় সেট করুন।';

  @override
  String get prayerAdhanReminder => 'নামাযের আযান রিমাইন্ডার';

  @override
  String get prayerAdhanReminderSubtitle =>
      'প্রতিটি ওয়াক্তের আলাদা রিমাইন্ডার';

  @override
  String get prayerAdhanScreenTitle => 'নামাযের আযান রিমাইন্ডার';

  @override
  String get prayerAdhanDescription =>
      'প্রতিটি ওয়াক্তের আযান রিমাইন্ডার পান। সময় বাংলাদেশের জন্য হিসাব করা হয়।';

  @override
  String get prayerAdhanTodayTimes => 'আজকের নামাযের সময়';

  @override
  String get prayerAdhanReminderTimes => 'রিমাইন্ডার সময়';

  @override
  String get prayerAdhanReminderTimesDescription =>
      'কাস্টম সময় সেট করতে ট্যাপ করুন। প্রতিদিনের আযানের সময় ব্যবহার করতে রিসেট করুন।';

  @override
  String get prayerAdhanCalculatedTime => 'আযানের সময়';

  @override
  String get prayerAdhanCustomTimeLabel => 'কাস্টম সময়';

  @override
  String get prayerAdhanResetToAdhan => 'আযানের সময় ব্যবহার করুন';

  @override
  String get prayerAdhanOffsetTitle => 'রিমাইন্ডার কখন দেখাবে?';

  @override
  String get prayerAdhanAtTime => 'আযানের সময়';

  @override
  String get prayerAdhanChipAtTime => 'আযান';

  @override
  String prayerAdhanChipMinBefore(Object minutes) {
    return '${minutes}m আগে';
  }

  @override
  String prayerAdhanMinutesBefore(Object minutes) {
    return '$minutes মিনিট আগে';
  }

  @override
  String get prayerAdhanReliabilityTitle =>
      'ব্যাকগ্রাউন্ড রিমাইন্ডারের জন্য সেটআপ প্রয়োজন';

  @override
  String get prayerAdhanReliabilityBody =>
      'অ্যাপ বন্ধ থাকলেও আযান রিমাইন্ডার পেতে সঠিক অ্যালার্ম অনুমতি দিন। নির্ভরযোগ্য ডেলিভারির জন্য ব্যাটারি অপ্টিমাইজেশন বন্ধ করুন।';

  @override
  String get prayerAdhanAllowExactAlarms => 'সঠিক অ্যালার্ম অনুমতি দিন';

  @override
  String get prayerAdhanDisableBatteryOptimization =>
      'ব্যাটারি অপ্টিমাইজেশন বন্ধ করুন';

  @override
  String get prayerFajr => 'ফজর';

  @override
  String get prayerDhuhr => 'যোহর';

  @override
  String get prayerAsr => 'আসর';

  @override
  String get prayerMaghrib => 'মাগরিব';

  @override
  String get prayerIsha => 'ইশা';

  @override
  String get quietHours => 'নোটিফিকেশন বিরতি';

  @override
  String get showOnLeaderboard => 'আমাকে লিডারবোর্ডে দেখান';

  @override
  String get showAnonymous => 'কমিউনিটিতে অ্যানোনিমাস দেখান';

  @override
  String get showAnonymousSubtitle => 'আপনার নাম ও ছবি হাইড থাকবে';

  @override
  String get calendarType => 'ক্যালেন্ডারের ধরন';

  @override
  String get hijri => 'হিজরি';

  @override
  String get hijriCalendar => 'হিজরি ক্যালেন্ডার';

  @override
  String get todayLabel => 'আজ';

  @override
  String get islamicEventsTitle => 'ইসলামিক অনুষ্ঠান';

  @override
  String get eventIslamicNewYear => 'ইসলামিক নববর্ষ';

  @override
  String get eventAshura => 'আশুরা';

  @override
  String get eventMawlid => 'ঈদে মিলাদুন্নবী';

  @override
  String get eventIsraMiraj => 'শবে মেরাজ';

  @override
  String get eventShabeBarat => 'শবে বরাত';

  @override
  String get eventRamadanStart => 'রমজানের শুরু';

  @override
  String get eventLaylatAlQadr => 'লাইলাতুল কদর';

  @override
  String get eventEidAlFitr => 'ঈদুল ফিতর';

  @override
  String get eventArafat => 'আরাফার দিন';

  @override
  String get eventEidAlAdha => 'ঈদুল আযহা';

  @override
  String get ramadanMode => 'রমাদান মোড';

  @override
  String get ramadanModeSubtitle => 'সিডিউল ও নোটিফিকেশন অ্যাডজাস্ট হবে';

  @override
  String get homeWidgetSettingsTitle => 'হোম স্ক্রিন উইজেট';

  @override
  String get homeWidgetSettingsSubtitle => 'যোগ করুন';

  @override
  String get homeWidgetSetupTitle => 'হোম স্ক্রিনে উইজেট যোগ করুন';

  @override
  String get homeWidgetSetupBody =>
      'হোম স্ক্রিন থেকেই আজকের আমল প্রগ্রেস চোখে রাখুন।';

  @override
  String get homeWidgetAddButton => 'উইজেট যোগ করুন';

  @override
  String get homeWidgetUnsupportedMessage =>
      'এই লঞ্চারে সরাসরি যোগ করা সাপোর্টেড নয়।';

  @override
  String get homeWidgetPinRequested =>
      'উইজেট যোগ করার অনুরোধ পাঠানো হয়েছে। হোম স্ক্রিনে কনফার্ম করুন।';

  @override
  String get homeWidgetPinFailed =>
      'এখনই উইজেট যোগ করা গেল না। নিচের ম্যানুয়াল ধাপগুলো অনুসরণ করুন।';

  @override
  String get homeWidgetIosGuide =>
      'iPhone-এ: হোম স্ক্রিনে দীর্ঘক্ষণ চাপ দিন, + চাপুন, তারপর \"Amol Tracker\" উইজেট সার্চ করুন।';

  @override
  String get homeWidgetFallbackSteps =>
      'ম্যানুয়াল ধাপ: হোম স্ক্রিনে দীর্ঘক্ষণ চাপ দিন -> Widgets -> Amol Tracker -> Add.';

  @override
  String get signOut => 'লগআউট';

  @override
  String get signOutTitle => 'লগআউট';

  @override
  String get signOutConfirm => 'আপনি কি নিশ্চিত লগআউট করতে চান?';

  @override
  String get cancel => 'ক্যানসেল';

  @override
  String get more => 'আরও';

  @override
  String get navHome => 'হোম';

  @override
  String get navHistory => 'ইতিহাস';

  @override
  String get navCommunity => 'কমিউনিটি';

  @override
  String get navDua => 'দোয়া';

  @override
  String get navMore => 'আরও';

  @override
  String get quickNavSection => 'দ্রুত নেভিগেশন';

  @override
  String get morningEveningDua => 'সকাল ও সন্ধ্যার দোয়া';

  @override
  String get duaTitle => 'দোয়াসমূহ';

  @override
  String get duaFavoritesTab => 'পছন্দ';

  @override
  String get duaCategoriesTab => 'বিষয়';

  @override
  String get duaAllTab => 'সব দোয়া';

  @override
  String get duaSearchHint => 'দোয়া খুঁজুন...';

  @override
  String get duaReference => 'রেফারেন্স';

  @override
  String get duaTransliteration => 'উচ্চারণ';

  @override
  String get duaTranslation => 'অনুবাদ';

  @override
  String get duaNoFavorites => 'এখনও পছন্দ নেই।\nযেকোনো দোয়ায় ★ চাপুন।';

  @override
  String get duaNoResults => 'কোনো ফলাফল পাওয়া যায়নি';

  @override
  String get duaFavAdded => 'পছন্দে যোগ হয়েছে';

  @override
  String get duaFavRemoved => 'পছন্দ থেকে সরানো হয়েছে';

  @override
  String get duaFavAdd => 'পছন্দে যোগ করুন';

  @override
  String get duaFavRemove => 'পছন্দ থেকে সরান';

  @override
  String get duaCopy => 'কপি';

  @override
  String get duaShare => 'শেয়ার';

  @override
  String get duaCopied => 'ক্লিপবোর্ডে কপি হয়েছে';

  @override
  String duaPageCounter(int current, int total) {
    return '$current / $total';
  }

  @override
  String get duaReaderOptions => 'পড়ার সেটিংস';

  @override
  String get duaReaderTextSize => 'টেক্সট সাইজ';

  @override
  String get duaReaderTextSizeNormal => 'সাধারণ';

  @override
  String get duaReaderTextSizeMedium => 'মাঝারি';

  @override
  String get duaReaderTextSizeLarge => 'বড়';

  @override
  String get duaReaderShowIntroduction => 'ভূমিকা';

  @override
  String get duaReaderShowTransliteration => 'উচ্চারণ';

  @override
  String get duaReaderShowTranslation => 'অনুবাদ';

  @override
  String get duaReaderShowReference => 'রেফারেন্স';

  @override
  String get duaReaderFocusMode => 'ফোকাস মোড';

  @override
  String get duaReaderFocusModeExit => 'ফোকাস মোড বন্ধ';

  @override
  String get duaReaderPrevious => 'আগের দোয়া';

  @override
  String get duaReaderNext => 'পরের দোয়া';

  @override
  String get duaReaderMore => 'আরও অপশন';

  @override
  String get duaReaderTextSizeDecrease => 'টেক্সট ছোট করুন';

  @override
  String get duaReaderTextSizeIncrease => 'টেক্সট বড় করুন';

  @override
  String routeNotFound(String path) {
    return 'রুট পাওয়া যায়নি: $path';
  }

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get devMenu => 'ডেভ মেনু';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get viewProfile => 'প্রোফাইল দেখুন';

  @override
  String get exploreSection => 'এক্সপ্লোর';

  @override
  String get leaderboard => 'লিডারবোর্ড';

  @override
  String get weekly => 'সাপ্তাহিক';

  @override
  String get notifications => 'নোটিফিকেশন';

  @override
  String get profileAndBadges => 'প্রোফাইল ও ব্যাজ';

  @override
  String get preferencesSection => 'প্রেফারেন্স';

  @override
  String get emptyDevSection => 'খালি / ডেভ';

  @override
  String get emptyStatePreview => 'এম্পটি স্টেট প্রিভিউ';

  @override
  String get devMenuAllScreens => 'ডেভ মেনু (সব স্ক্রিন)';

  @override
  String get quietHoursDescription =>
      'এই সময়ে নোটিফিকেশন সাইলেন্ট থাকবে। তবে নোটিফিকেশন সিডিউল চলবে।';

  @override
  String get from => 'শুরু';

  @override
  String get to => 'শেষ';

  @override
  String silentFromTo(Object from, Object to) {
    return '$from থেকে $to পর্যন্ত সাইলেন্ট';
  }

  @override
  String hoursSilence(Object hours) {
    return '$hours ঘণ্টা সাইলেন্ট';
  }

  @override
  String hoursMinutesSilence(Object hours, Object minutes) {
    return '$hours ঘন্টা $minutes মিনিট সাইলেন্ট';
  }

  @override
  String get save => 'সেভ করুন';

  @override
  String get saveFabLabel => 'সেভ';

  @override
  String get alerts => 'অ্যালার্ট';

  @override
  String get markAllRead => 'সবগুলো রিড';

  @override
  String get failedLoadNotifications => 'নোটিফিকেশন লোড করা যায়নি।';

  @override
  String get noNotificationsYet => 'এখনও কোনো নোটিফিকেশন নেই';

  @override
  String get justNow => 'এইমাত্র';

  @override
  String minutesAgo(Object minutes) {
    return '$minutesমি আগে';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hoursঘন্টা আগে';
  }

  @override
  String daysAgo(Object days) {
    return '$daysদিন আগে';
  }

  @override
  String weeksAgo(Object weeks) {
    return '$weeksসপ্তাহ আগে';
  }

  @override
  String get welcome => 'স্বাগতম';

  @override
  String get today => 'আজ';

  @override
  String get noAmalLoggedYet => 'এখনও কোনো আমল লগ হয়নি';

  @override
  String get freshStartMessage =>
      'আজ নতুন শুরু। প্রথম আমলটা টিক দিন - একটা হলেও হবে।';

  @override
  String get logTodayAmal => 'আজকের আমল লগ করুন';

  @override
  String get joinCommunity => 'কমিউনিটিতে যোগ দিন';

  @override
  String get joinCommunitySubtitle =>
      'আজকের কমিউনিটি শিট দেখুন, সবার সাথে মোটিভেটেড থাকুন।';

  @override
  String get openCommunity => 'কমিউনিটি খুলুন';

  @override
  String get signInTagline => 'প্রতিদিনের আমল, একসাথে';

  @override
  String get continueWithGoogle => 'Google দিয়ে কন্টিনিউ';

  @override
  String get continueAsGuest => 'গেস্ট হিসেবে কন্টিনিউ';

  @override
  String get continueTerms =>
      'কন্টিনিউ করলে আমাদের টার্মস ও প্রাইভেসিতে সম্মতি দিচ্ছেন।';

  @override
  String googleSignInFailed(Object error) {
    return 'Google লগইন ব্যর্থ: $error';
  }

  @override
  String guestSignInFailed(Object error) {
    return 'গেস্ট লগইন ব্যর্থ: $error';
  }

  @override
  String get skip => 'স্কিপ';

  @override
  String get pleaseWait => 'একটু অপেক্ষা করুন...';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get next => 'পরেরটা';

  @override
  String get buildDailyHabitTitle => 'প্রতিদিনের অভ্যাস গড়ে তুলুন';

  @override
  String get buildDailyHabitBody =>
      '৯টি দৈনিক আমল ট্র্যাক করুন - ফরজ, সুন্নাহ, আযকার, কুরআন। ছোট ছোট ধারাবাহিক স্টেপ।';

  @override
  String get streaksKeepYouGoingTitle => 'স্ট্রিক আপনাকে চালিয়ে রাখবে';

  @override
  String get streaksKeepYouGoingBody =>
      'চেইন ভাঙবেন না। ৭, ৩০, ১০০ দিন পূর্ণ করুন - নেকি অর্জন করুন।';

  @override
  String get setupProfileTitle => 'প্রোফাইল সেটআপ করুন';

  @override
  String get setupProfileBody =>
      'কমিউনিটিতে যোগ দেওয়ার আগে নাম আর প্রাইভেসি সেট করুন।';

  @override
  String get starter => 'স্টার্টার';

  @override
  String get habit => 'হ্যাবিট';

  @override
  String get devoted => 'ডিভোটেড';

  @override
  String get displayName => 'ডিসপ্লে নাম';

  @override
  String get yourName => 'আপনার নাম';

  @override
  String get showAnonymousCommunity => 'কমিউনিটিতে অ্যানোনিমাস দেখান';

  @override
  String get notificationsEnabled => 'নোটিফিকেশন চালু হয়েছে';

  @override
  String get allowNotifications => 'নোটিফিকেশন অ্যালাও করুন';

  @override
  String onboardingFailed(Object error) {
    return 'অনবোর্ডিং সম্পন্ন করা যায়নি: $error';
  }

  @override
  String get anonymous => 'Anonymous';

  @override
  String get user => 'User';

  @override
  String get daily => 'দৈনিক';

  @override
  String get streak => 'স্ট্রিক';

  @override
  String get historyDays => 'দিন';

  @override
  String get pointsAbbr => 'পয়েন্ট';

  @override
  String get you => 'আপনি';

  @override
  String get leaderboardBeFirstToday => 'আজ প্রথম লগটা আপনিই দিন!';

  @override
  String leaderboardYourRank(Object rank, Object score, Object stat) {
    return 'আপনার র‍্যাঙ্ক: #$rank · $score $stat';
  }

  @override
  String leaderboardYourRankNumber(int rank) {
    return 'আপনার র‍্যাঙ্ক: #$rank';
  }

  @override
  String get leaderboardLoadFailed =>
      'এই মুহূর্তে লিডারবোর্ড লোড করা যাচ্ছে না।';

  @override
  String get leaderboardNudgeKeepClimbing =>
      'চালিয়ে যান - প্রতিটি আমল গুরুত্বপূর্ণ।';

  @override
  String get leaderboardNudgeTop => 'আপনি টপে আছেন - ধারাবাহিক থাকুন।';

  @override
  String leaderboardNudgeBehindDays(Object behind) {
    return '২য় স্থানের থেকে $behind দিন পিছিয়ে - স্ট্রিক ধরে রাখুন।';
  }

  @override
  String leaderboardNudgeBehindPoints(Object behind) {
    return '২য় স্থানের থেকে $behind পয়েন্ট পিছিয়ে - আজ লগ করে গ্যাপ কমান।';
  }

  @override
  String leaderboardNudgeBehindFirstDays(Object behind) {
    return '১ম স্থানের থেকে $behind দিন পিছিয়ে - স্ট্রিক ধরে রাখুন।';
  }

  @override
  String leaderboardNudgeBehindFirstPoints(Object behind) {
    return '১ম স্থানের থেকে $behind পয়েন্ট পিছিয়ে - আজ লগ করে এগিয়ে যান।';
  }

  @override
  String get leaderboardQuizTab => 'কুইজ';

  @override
  String get leaderboardQuizBeFirst => 'কুইজ পাস করার জন্য প্রথম হন!';

  @override
  String leaderboardNudgeBehindQuizPoints(Object behind) {
    return '২য় স্থানের থেকে $behind পয়েন্ট পিছিয়ে - আরও কুইজ পাস করে এগিয়ে যান।';
  }

  @override
  String leaderboardNudgeBehindFirstQuizPoints(Object behind) {
    return '১ম স্থানের থেকে $behind পয়েন্ট পিছিয়ে - আরও কুইজ পাস করে শীর্ষে উঠুন।';
  }

  @override
  String get leaderboardQuizAttempts => 'চেষ্টা';

  @override
  String leaderboardQuizStat(int points, int attempts) {
    return '$points পয়েন্ট · $attempts চেষ্টা';
  }

  @override
  String leaderboardYourRankQuiz(int rank, String stat) {
    return 'আপনার র‍্যাঙ্ক: #$rank · $stat';
  }

  @override
  String get leaderboardQuizTiebreakerHint =>
      'সমান পয়েন্টে কম চেষ্টায় এগিয়ে থাকবেন।';

  @override
  String get history => 'হিস্টোরি';

  @override
  String get historyLoadFailed => 'হিস্টোরি লোড করা যায়নি।';

  @override
  String historyConsistency(Object value) {
    return '$value% কনসিস্টেন্সি';
  }

  @override
  String get historyLoggedDays => 'লগ করা দিন';

  @override
  String historyOfDays(Object days) {
    return 'মোট $days দিনের মধ্যে';
  }

  @override
  String get historyAvgScore => 'গড় স্কোর';

  @override
  String get historyNoLogsYet => 'এখনও লগ নেই';

  @override
  String get historyThisMonth => 'এই মাসে';

  @override
  String get historyBestStreak => 'সেরা স্ট্রিক';

  @override
  String get historyStartLogging => 'হিস্টোরি তৈরি করতে আজ থেকে লগ শুরু করুন';

  @override
  String get historyWeakestAmal => 'সবচেয়ে দুর্বল আমল';

  @override
  String historyWeakestAmalDetail(Object label, Object days) {
    return '$label - এই মাসে $days দিন মিস হয়েছে';
  }

  @override
  String get historyFull => 'পূর্ণ';

  @override
  String get historyPartial => 'আংশিক';

  @override
  String get historyMiss => 'মিস';

  @override
  String get dayDetailTitle => 'দিনের বিস্তারিত';

  @override
  String get dayDetailLoadFailed => 'এই দিনের তথ্য লোড করা যায়নি।';

  @override
  String get readOnly => 'শুধু দেখুন';

  @override
  String get score => 'স্কোর';

  @override
  String get outOf100 => '১০০ এর মধ্যে';

  @override
  String get dayDetailStreakThatDay => 'সেদিনের স্ট্রিক';

  @override
  String get dayDetailNotStored => 'সংরক্ষিত নেই';

  @override
  String get amal => 'আমল';

  @override
  String get dayDetailNoLogForDay => 'এই হিজরি দিনের জন্য কোনো লগ সাবমিট হয়নি।';

  @override
  String get dayDetailLockedPastDays =>
      'লকড — অ্যাকাউন্ট তৈরি হওয়ার আগের দিনগুলো এডিট করা যাবে না।';

  @override
  String get editDayAmal => 'এই দিনের আমল সম্পাদনা করুন';

  @override
  String get dayDetailTodayGoHome => 'আজকের আমল লগ করতে হোম স্ক্রীনে যান';

  @override
  String get dayDetailGoToHome => 'হোমে যান';

  @override
  String get editTodayAmal => 'আজকের আমল সম্পাদনা করুন';

  @override
  String memberSince(Object year) {
    return '$year সাল থেকে মেম্বার';
  }

  @override
  String get best => 'সেরা';

  @override
  String get avg => 'গড়';

  @override
  String get thisWeek => 'এই সপ্তাহ';

  @override
  String get anonymousEnabled => 'অ্যানোনিমাস চালু';

  @override
  String get realNameVisible => 'আসল নাম দেখা যাচ্ছে';

  @override
  String get badges => 'ব্যাজ';

  @override
  String get communityUpper => 'কমিউনিটি';

  @override
  String get community => 'কমিউনিটি';

  @override
  String get sheet => 'শিট';

  @override
  String get feed => 'ফিড';

  @override
  String get offlineShowingLatest => 'অফলাইন - সর্বশেষ ডেটা দেখানো হচ্ছে।';

  @override
  String get date => 'তারিখ';

  @override
  String get searchByName => 'নাম দিয়ে সার্চ করুন';

  @override
  String get logTodayToAppear => 'এখানে দেখাতে আজ লগ করুন';

  @override
  String get noLogsForDay => 'এই দিনে কোনো লগ পাওয়া যায়নি';

  @override
  String get noMoreRows => 'আর কোনো রো নেই';

  @override
  String get unableLoadActivityFeed => 'অ্যাক্টিভিটি ফিড লোড করা যায়নি।';

  @override
  String get noActivityYet =>
      'এখনও কোনো অ্যাক্টিভিটি নেই। কমিউনিটি আপডেট এখানে দেখাবে।';

  @override
  String get userProfile => 'ইউজার প্রোফাইল';

  @override
  String get profileUnavailable => 'এই প্রোফাইলটি পাওয়া যাচ্ছে না।';

  @override
  String get communityMember => 'কমিউনিটি মেম্বার';

  @override
  String get selected => 'সিলেক্টেড';

  @override
  String get todaysAmal => 'আজকের আমল';

  @override
  String amalOnDate(Object date) {
    return '$date তারিখের আমল';
  }

  @override
  String get last7Days => 'শেষ ৭ দিন';

  @override
  String get profileSettings => 'প্রোফাইল সেটিংস';

  @override
  String get saving => 'সেভ হচ্ছে...';

  @override
  String get saveProfile => 'প্রোফাইল সেভ করুন';

  @override
  String get sending => 'পাঠানো হচ্ছে...';

  @override
  String get sendDua => 'দোয়া পাঠান';

  @override
  String get alreadySentDuaToday => 'আজকে আপনি ইতিমধ্যে দোয়া পাঠিয়েছেন';

  @override
  String get communityMemberSentDua =>
      'কমিউনিটি থেকে কেউ আপনাকে দোয়া পাঠিয়েছে 🤲';

  @override
  String duaFromSender(Object name) {
    return '$name আপনাকে দোয়া পাঠিয়েছেন 🤲';
  }

  @override
  String get duaSent => 'দোয়া পাঠানো হয়েছে ✓';

  @override
  String get noRecentLogs => 'সাম্প্রতিক কোনো লগ নেই।';

  @override
  String get friendsUpper => 'ফ্রেন্ডস';

  @override
  String get together => 'একসাথে';

  @override
  String get invite => 'ইনভাইট';

  @override
  String get activityFeed => 'অ্যাক্টিভিটি ফিড';

  @override
  String get yourGroup => 'আপনার গ্রুপ';

  @override
  String get manage => 'ম্যানেজ';

  @override
  String groupMembersDesc(Object count, Object desc) {
    return '$count জন ভাই · $desc';
  }

  @override
  String get viewSheetArrow => 'শিট দেখুন →';

  @override
  String get done => 'সম্পন্ন';

  @override
  String get pending => 'অপেক্ষমাণ';

  @override
  String get inviteAndJoin => 'ইনভাইট ও জয়েন';

  @override
  String get yourInviteCode => 'আপনার ইনভাইট কোড';

  @override
  String get inviteCodeValid => 'ভ্যালিড · ৫ জন ভাই জয়েন করতে পারবেন';

  @override
  String get inviteCodeCopied => 'ইনভাইট কোড কপি হয়েছে';

  @override
  String get copyCode => 'কোড কপি';

  @override
  String get shareLink => 'লিংক শেয়ার';

  @override
  String get joinGroupUpper => 'গ্রুপে জয়েন করুন';

  @override
  String get enterInviteCode => 'ইনভাইট কোড লিখুন';

  @override
  String get joinedMock => 'জয়েন হয়েছে (মক)';

  @override
  String get joinGroup => 'গ্রুপে জয়েন করুন';

  @override
  String get friend => 'ফ্রেন্ড';

  @override
  String get topScorer => 'টপ স্কোরার';

  @override
  String get duaSentMock => 'দোয়া পাঠানো হয়েছে (মক)';

  @override
  String get remove => 'রিমুভ';

  @override
  String get group => 'গ্রুপ';

  @override
  String get admin => 'অ্যাডমিন';

  @override
  String get inviteCodeUpper => 'ইনভাইট কোড';

  @override
  String get copy => 'কপি';

  @override
  String get share => 'শেয়ার';

  @override
  String get refresh => 'রিফ্রেশ';

  @override
  String get members => 'মেম্বারস';

  @override
  String get groupSettings => 'গ্রুপ সেটিংস';

  @override
  String get publicLeaderboard => 'পাবলিক লিডারবোর্ড';

  @override
  String get publicLeaderboardSubtitle => 'সব মেম্বার র‍্যাঙ্ক দেখতে পারবে';

  @override
  String get quietHoursActive => 'নোটিফিকেশন বিরতি চালু';

  @override
  String get quietHoursActiveSubtitle => 'রাতে নোটিফিকেশন মিউট থাকবে';

  @override
  String get deleteGroup => 'গ্রুপ ডিলিট';

  @override
  String get deleteThisGroup => 'এই গ্রুপ ডিলিট করবেন?';

  @override
  String get deleteGroupWarning =>
      'সব মেম্বার অ্যাক্সেস হারাবে। এটা আর ফেরানো যাবে না।';

  @override
  String get delete => 'ডিলিট';

  @override
  String dayStreak(Object days) {
    return '$days দিনের স্ট্রিক';
  }

  @override
  String get groupSheet => 'গ্রুপ শিট';

  @override
  String allActiveToday(Object count) {
    return 'আজ $count জন অ্যাক্টিভ';
  }

  @override
  String get groupStreak => 'গ্রুপ স্ট্রিক';

  @override
  String get groupAvg => 'গ্রুপ গড়';

  @override
  String get memberUpper => 'মেম্বার';

  @override
  String get numericLegend => 'সংখ্যা (ফরজ, তাকবির)';

  @override
  String get homeOfflineSyncMessage =>
      'অফলাইন - আপনার লগ এই ডিভাইসে সেভ থাকবে, ইন্টারনেট এলে অটো সিঙ্ক হবে।';

  @override
  String get loggedToday => 'আজ লগ করা হয়েছে ✓';

  @override
  String get markAllDone => 'সবগুলো সম্পন্ন';

  @override
  String get deselectAll => 'সবগুলো বাতিল';

  @override
  String get submitTodaysLog => 'আজকের লগ সাবমিট করুন';

  @override
  String get saveTodaysAmal => 'আজকের আমল সংরক্ষণ করুন';

  @override
  String draftSavedTapSaveToFinish(Object saveButton) {
    return 'খসড়া সংরক্ষিত। আজকের হিসাব শেষ করতে \"$saveButton\" চাপুন।';
  }

  @override
  String get completeAllAmalAutoSave =>
      'আজকের আমল সংরক্ষণ করতে উপরের সব আমল সম্পন্ন করুন।';

  @override
  String get amalAutoSaving => 'আজকের আমল সংরক্ষণ হচ্ছে…';

  @override
  String get progressAutosavedHint =>
      'আপনার অগ্রগতি খসড়া হিসেবে অটো সেভ হচ্ছে।';

  @override
  String get welcomeUpper => 'স্বাগতম';

  @override
  String get firstAmalStartsToday => 'আপনার প্রথম আমল আজ থেকেই শুরু।';

  @override
  String get onFire => 'দারুণ চলছে';

  @override
  String bestStreakKeepGoing(Object days) {
    return 'সেরা: $days দিন · চালিয়ে যান';
  }

  @override
  String get todaysProgress => 'আজকের প্রগ্রেস';

  @override
  String scoreOutOfPoints(Object score, Object max) {
    return '$score / $max পয়েন্ট';
  }

  @override
  String get outOf100Compact => '/১০০';

  @override
  String get weekdayMon => 'সো';

  @override
  String get weekdayTue => 'ম';

  @override
  String get weekdayWed => 'মং';

  @override
  String get weekdayThu => 'বু';

  @override
  String get weekdayFri => 'বৃ';

  @override
  String get weekdaySat => 'শু';

  @override
  String get weekdaySun => 'শ';

  @override
  String get dayCompleteSubtitle => 'আজকের আমল সফলভাবে সম্পন্ন করেছেন।';

  @override
  String pointsEarned(Object points) {
    return '+$points পয়েন্ট অর্জন';
  }

  @override
  String get hadithOfDay => 'আজকের হাদিস';

  @override
  String get todaysSummary => 'আজকের সারাংশ';

  @override
  String get backToHome => 'হোমে ফিরে যান';

  @override
  String pointsValue(Object points) {
    return '$points পয়েন্ট';
  }

  @override
  String get tapScreenToJump => 'স্ক্রিনে ট্যাপ করে দ্রুত যান (UI টেস্টিং)';

  @override
  String get badgeThreeDaysTitle => '৩ দিনের স্ট্রিক';

  @override
  String get badgeThreeDaysDesc => 'টানা ৩ দিন আমল সম্পন্ন করুন।';

  @override
  String get badgeSevenDaysTitle => '৭ দিনের স্ট্রিক';

  @override
  String get badgeSevenDaysDesc => 'টানা ৭ দিন আমল সম্পন্ন করুন।';

  @override
  String get badgeFourteenDaysTitle => '১৪ দিনের স্ট্রিক';

  @override
  String get badgeFourteenDaysDesc => 'টানা ১৪ দিন আমল সম্পন্ন করুন।';

  @override
  String get badgeThirtyDaysTitle => '৩০ দিনের স্ট্রিক';

  @override
  String get badgeThirtyDaysDesc => 'টানা ৩০ দিন আমল সম্পন্ন করুন।';

  @override
  String get badgeSixtyDaysTitle => '৬০ দিনের স্ট্রিক';

  @override
  String get badgeSixtyDaysDesc => 'টানা ৬০ দিন আমল সম্পন্ন করুন।';

  @override
  String get badgeHundredDaysTitle => '১০০ দিনের স্ট্রিক';

  @override
  String get badgeHundredDaysDesc => 'টানা ১০০ দিন আমল সম্পন্ন করুন।';

  @override
  String get badgeTopCommunityTitle => 'কমিউনিটির টপ';

  @override
  String get badgeTopCommunityDesc => 'গ্লোবাল সাপ্তাহিক লিডারবোর্ডে #১ হন।';

  @override
  String get badgePerfectWeekTitle => 'পারফেক্ট সপ্তাহ';

  @override
  String get badgePerfectWeekDesc => 'টানা ৭ দিন ৮০+ স্কোর করুন।';

  @override
  String get badgeCourseGraduateTitle => 'কোর্স গ্র্যাজুয়েট';

  @override
  String get badgeCourseGraduateDesc =>
      'একটি সিলেবাস কোর্সের সব পাঠ সম্পন্ন করুন।';

  @override
  String get exitAppTitle => 'অ্যাপ বন্ধ করবে?';

  @override
  String get exitAppConfirm => 'আজকের আমল লগ করা হয়েছে কি?';

  @override
  String get exitAppStay => 'থাকো';

  @override
  String get exitApp => 'বন্ধ করো';

  @override
  String get dhikrCounter => 'দুআ ও জিকির কাউন্টার';

  @override
  String get subhanAllah => 'সুবহানাল্লাহ';

  @override
  String get alhamdulillah => 'আলহামদুলিল্লাহ';

  @override
  String get allahuAkbar => 'আল্লাহু আকবার';

  @override
  String dhikrTarget(int count) {
    return 'লক্ষ্য: $count';
  }

  @override
  String get dhikrCount => 'গণনা';

  @override
  String get dhikrCompleted => 'সম্পন্ন!';

  @override
  String get dhikrReset => 'রিসেট';

  @override
  String get dhikrCustom => 'কাস্টম';

  @override
  String get dhikrAddCustom => 'কাস্টম জিকির যোগ করুন';

  @override
  String get dhikrAdd => 'যোগ';

  @override
  String get dhikrCustomName => 'জিকিরের নাম';

  @override
  String get dhikrCustomTarget => 'লক্ষ্য সংখ্যা';

  @override
  String get dhikrTodaySessions => 'আজকের সম্পন্ন জিকির';

  @override
  String get dhikrNoSessions => 'আজ এখনো কোনো জিকির সম্পন্ন হয়নি।';

  @override
  String get dhikrSelectDhikr => 'জিকির নির্বাচন করুন';

  @override
  String get dhikrShortcutSubtitle =>
      'সুবহানাল্লাহ, আলহামদুলিল্লাহ ও আরও গণনা করুন';

  @override
  String get dhikrTapToCount => 'গণনার জন্য ট্যাপ করুন';

  @override
  String get dhikrNameRequired => 'জিকিরের নাম লিখুন।';

  @override
  String get dhikrTargetInvalid => 'লক্ষ্য কমপক্ষে ১ হতে হবে।';

  @override
  String get dhikrDuplicateName => 'এই নামে একটি জিকির ইতিমধ্যে আছে।';

  @override
  String get asmaUlHusna => 'আসমাউল হুসনা';

  @override
  String get husnaSubtitle => 'আল্লাহর ৯৯টি নাম';

  @override
  String husnaLearnedCount(int learned) {
    return '৯৯টির মধ্যে $learnedটি শিখেছেন';
  }

  @override
  String get husnaMarkLearned => 'শিখেছি হিসেবে চিহ্নিত করুন';

  @override
  String get husnaMarkNotLearned => 'চিহ্ন সরান';

  @override
  String get husnaQuiz => 'কুইজ মোড';

  @override
  String get husnaQuizQuestion => 'এই অর্থ কোন নামের?';

  @override
  String get husnaQuizCorrect => 'সঠিক!';

  @override
  String get husnaQuizWrong => 'ভুল';

  @override
  String husnaQuizScore(int score, int total) {
    return 'স্কোর: $score / $total';
  }

  @override
  String get husnaQuizFinished => 'কুইজ সম্পন্ন';

  @override
  String get husnaNoNamesLearned => 'কুইজ খুলতে আগে কমপক্ষে ৪টি নাম শিখুন';

  @override
  String husnaNumber(int number) {
    return '#$number';
  }

  @override
  String get husnaBenefit => 'চিন্তা';

  @override
  String get husnaMeaning => 'অর্থ';

  @override
  String get husnaNextQuestion => 'পরবর্তী';

  @override
  String get husnaStartQuiz => 'কুইজ শুরু';

  @override
  String get husnaRetryQuiz => 'আবার চেষ্টা';

  @override
  String get husnaSearch => 'নাম খুঁজুন...';

  @override
  String get husnaFilterAll => 'সব';

  @override
  String get husnaFilterLearned => 'শিখেছি';

  @override
  String get husnaFilterNotLearned => 'শিখিনি';

  @override
  String husnaQuizProgress(int current, int total) {
    return 'প্রশ্ন $current / $total';
  }

  @override
  String get husnaQuizExcellent => 'চমৎকার!';

  @override
  String get husnaQuizGoodEffort => 'ভালো চেষ্টা!';

  @override
  String get husnaQuizKeepLearning => 'শেখা চালিয়ে যান!';

  @override
  String get husnaSwipeHint => 'পরের নাম দেখতে সোয়াইপ করুন';

  @override
  String get husnaPronunciation => 'উচ্চারণ';

  @override
  String husnaCorrectAnswer(String name) {
    return 'সঠিক উত্তর: $name';
  }

  @override
  String get announcementDismiss => 'বুঝেছি';

  @override
  String get announcementTypeReminder => 'রিমাইন্ডার';

  @override
  String get announcementTypeAnnouncement => 'ঘোষণা';

  @override
  String get announcementTypeDua => 'দোয়া';

  @override
  String get announcementTypeHadith => 'হাদিস';

  @override
  String get adminSectionTitle => 'অ্যাডমিন';

  @override
  String get adminAnnouncementsTitle => 'ঘোষণা';

  @override
  String get adminAmalFieldsTitle => 'আমল ফিল্ড';

  @override
  String get adminAmalFieldFormCreate => 'আমল ফিল্ড তৈরি';

  @override
  String get adminAmalFieldFormEdit => 'আমল ফিল্ড সম্পাদনা';

  @override
  String get adminAmalFieldId => 'ফিল্ড ID';

  @override
  String get adminAmalFieldLabelEn => 'লেবেল (ইংরেজি)';

  @override
  String get adminAmalFieldLabelBn => 'লেবেল (বাংলা, ঐচ্ছিক)';

  @override
  String get adminAmalFieldSublabelEn => 'বিবরণ (ইংরেজি)';

  @override
  String get adminAmalFieldSublabelBn => 'বিবরণ (বাংলা, ঐচ্ছিক)';

  @override
  String get adminAmalFieldPoints => 'পয়েন্ট';

  @override
  String get adminAmalFieldMaxValue => 'সর্বোচ্চ মান';

  @override
  String get adminAmalFieldOrder => 'প্রদর্শন ক্রম';

  @override
  String get adminAmalFieldTypeBoolean => 'হ্যাঁ / না';

  @override
  String get adminAmalFieldTypeNumeric => 'সংখ্যাসূচক';

  @override
  String get adminAmalFieldIdRequired => 'ফিল্ড ID প্রয়োজন।';

  @override
  String get adminAmalFieldIdInvalid =>
      'ছোট হাতের অক্ষর, সংখ্যা ও আন্ডারস্কোর ব্যবহার করুন।';

  @override
  String get adminAmalFieldLabelRequired => 'ইংরেজি লেবেল প্রয়োজন।';

  @override
  String get adminAmalFieldPointsInvalid =>
      'পয়েন্ট ০ থেকে ১০০ এর মধ্যে হতে হবে।';

  @override
  String get adminAmalFieldMaxValueInvalid => 'সর্বোচ্চ মান কমপক্ষে ১ হতে হবে।';

  @override
  String get adminAmalFieldOrderInvalid => 'ক্রম ০ বা তার বেশি হতে হবে।';

  @override
  String get adminAmalFieldSaved => 'আমল ফিল্ড সংরক্ষিত হয়েছে।';

  @override
  String get adminAmalFieldSaveFailed => 'আমল ফিল্ড সংরক্ষণ করা যায়নি।';

  @override
  String get adminAmalFieldToggleFailed => 'আমল ফিল্ড আপডেট করা যায়নি।';

  @override
  String get adminAmalFieldIdImmutable =>
      'তৈরির পর ফিল্ড ID পরিবর্তন করা যাবে না।';

  @override
  String get adminAmalFieldPreviewRequired =>
      'প্রিভিউ করতে ইংরেজি লেবেল লিখুন।';

  @override
  String get adminAmalFieldEmptyList => 'এখনো কোনো আমল ফিল্ড নেই। + চাপুন।';

  @override
  String get adminAmalFieldsLoadFailed => 'আমল ফিল্ড লোড করা যায়নি।';

  @override
  String get adminAmalFieldIdentitySection => 'পরিচয়';

  @override
  String get adminAmalFieldLabelsSection => 'লেবেল';

  @override
  String get adminAmalFieldScoringSection => 'স্কোরিং';

  @override
  String get adminAmalFieldDisplaySection => 'প্রদর্শন';

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
  String get adminStatusLive => 'লাইভ';

  @override
  String get adminStatusScheduled => 'নির্ধারিত';

  @override
  String get adminStatusExpired => 'মেয়াদোত্তীর্ণ';

  @override
  String get adminStatusOff => 'বন্ধ';

  @override
  String get adminFormType => 'ধরন';

  @override
  String get adminFormTitle => 'শিরোনাম';

  @override
  String get adminFormMessage => 'বার্তা';

  @override
  String get adminFormArabicText => 'আরবি টেক্সট (ঐচ্ছিক)';

  @override
  String get adminFormImageUrl => 'ছবির URL (ঐচ্ছিক)';

  @override
  String get adminFormActive => 'সক্রিয়';

  @override
  String get adminFormShowOnce => 'প্রতি ব্যবহারকারীকে একবার দেখান';

  @override
  String get adminFormStartsAt => 'শুরু সময়';

  @override
  String get adminFormExpiresAt => 'শেষ সময়';

  @override
  String get adminFormPreview => 'প্রিভিউ';

  @override
  String get adminFormSave => 'সংরক্ষণ';

  @override
  String get adminFormClearDate => 'মুছুন';

  @override
  String get adminFormCreateTitle => 'ঘোষণা তৈরি করুন';

  @override
  String get adminFormEditTitle => 'ঘোষণা সম্পাদনা';

  @override
  String get adminFormTitleRequired => 'শিরোনাম প্রয়োজন।';

  @override
  String get adminFormMessageRequired => 'বার্তা প্রয়োজন।';

  @override
  String get adminFormSaved => 'ঘোষণা সংরক্ষিত হয়েছে।';

  @override
  String get adminDeleteTitle => 'ঘোষণা মুছবেন?';

  @override
  String get adminDeleteConfirm => 'এটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get adminEmptyList => 'এখনো কোনো ঘোষণা নেই। + চাপুন।';

  @override
  String get adminNotAuthorized => 'আপনার এই স্ক্রিনে প্রবেশের অনুমতি নেই।';

  @override
  String get adminLoadFailed => 'ঘোষণা লোড করা যায়নি।';

  @override
  String get adminSaveFailed => 'ঘোষণা সংরক্ষণ করা যায়নি।';

  @override
  String get adminDeleteFailed => 'ঘোষণা মুছে ফেলা যায়নি।';

  @override
  String get adminToggleFailed => 'ঘোষণা আপডেট করা যায়নি।';

  @override
  String get adminDateRangeInvalid => 'শেষ সময় শুরুর সময়ের পরে হতে হবে।';

  @override
  String get adminPreviewRequired => 'প্রিভিউ করতে শিরোনাম ও বার্তা লিখুন।';

  @override
  String get adminPushNotificationTitle => 'পুশ নোটিফিকেশন';

  @override
  String get adminPushScreenTitle => 'পুশ পাঠান';

  @override
  String get adminPushTitle => 'শিরোনাম';

  @override
  String get adminPushMessage => 'বার্তা';

  @override
  String get adminPushType => 'ধরন';

  @override
  String get adminPushTypeSyllabusCourse => 'সিলেবাস কোর্স';

  @override
  String get adminPushTypeSyllabusReview => 'অধ্যয়ন পুনরালোচনা';

  @override
  String get adminPushTitleRequired => 'শিরোনাম প্রয়োজন।';

  @override
  String get adminPushMessageRequired => 'বার্তা প্রয়োজন।';

  @override
  String get adminPushSend => 'সকল ব্যবহারকারীকে পাঠান';

  @override
  String get adminPushSent => 'নোটিফিকেশন সফলভাবে পাঠানো হয়েছে।';

  @override
  String get adminPushFailed => 'নোটিফিকেশন পাঠাতে ব্যর্থ।';

  @override
  String get adminPushGatewayNotConfigured => 'পুশ গেটওয়ে কনফিগার করা নেই।';

  @override
  String get adminPushGatewayKeyMissing =>
      'গেটওয়ে কী নেই। --dart-define=DUA_PUSH_GATEWAY_KEY=your_key দিয়ে চালান';

  @override
  String get adminCoursesTitle => 'কোর্স';

  @override
  String get adminCourseCreateTitle => 'কোর্স তৈরি';

  @override
  String get adminCourseEditTitle => 'কোর্স সম্পাদনা';

  @override
  String get adminCourseEmptyList => 'এখনো কোনো কোর্স নেই। + চাপুন।';

  @override
  String get adminCourseLoadFailed => 'কোর্স লোড করা যায়নি।';

  @override
  String get adminCourseDeleteTitle => 'কোর্স মুছবেন?';

  @override
  String get adminCourseDeleteFailed => 'কোর্স মুছে ফেলা যায়নি।';

  @override
  String get adminCoursePublishFailed => 'কোর্স স্ট্যাটাস আপডেট করা যায়নি।';

  @override
  String get adminCourseFormSaved => 'কোর্স সংরক্ষিত হয়েছে।';

  @override
  String get adminCoursePublishedPushTitle => 'নতুন কোর্স উপলব্ধ';

  @override
  String adminCoursePublishedPushMessage(String title) {
    return 'একটি নতুন সিলেবাস কোর্স প্রকাশিত হয়েছে: $title। এনরোল করতে সিলেবাস খুলুন।';
  }

  @override
  String get adminCourseManageLessons => 'পাঠ পরিচালনা';

  @override
  String get adminCourseDescription => 'বিবরণ';

  @override
  String get adminCourseDescriptionRequired => 'বিবরণ প্রয়োজন।';

  @override
  String get adminCourseCoverUrl => 'কভার ছবির URL (ঐচ্ছিক)';

  @override
  String get adminCourseTags => 'ট্যাগ (কমা দিয়ে)';

  @override
  String get adminCourseModerators => 'মডারেটর UID (কমা দিয়ে)';

  @override
  String get adminCourseDetailsSection => 'কোর্স বিবরণ';

  @override
  String get adminCourseModeratorsSection => 'মডারেটর';

  @override
  String get adminCourseStatusSection => 'স্ট্যাটাস';

  @override
  String get adminCourseStatusPublished => 'প্রকাশিত';

  @override
  String get adminCourseStatusDraft => 'খসড়া';

  @override
  String get adminLessonsTitle => 'পাঠ';

  @override
  String get adminLessonsSubtitle => 'টেনে সাজান। প্রস্তুত হলে প্রকাশ করুন।';

  @override
  String get adminLessonCreateTitle => 'পাঠ যোগ';

  @override
  String get adminLessonEditTitle => 'পাঠ সম্পাদনা';

  @override
  String get adminLessonEmptyList => 'এখনো কোনো পাঠ নেই। + চাপুন।';

  @override
  String get adminLessonLoadFailed => 'পাঠ লোড করা যায়নি।';

  @override
  String get adminLessonDeleteTitle => 'পাঠ মুছবেন?';

  @override
  String get adminLessonDeleteFailed => 'পাঠ মুছে ফেলা যায়নি।';

  @override
  String get adminLessonReorderFailed => 'পাঠের ক্রম সংরক্ষণ করা যায়নি।';

  @override
  String get adminLessonFormSaved => 'পাঠ সংরক্ষিত হয়েছে।';

  @override
  String get adminLessonDetailsSection => 'পাঠ বিবরণ';

  @override
  String get adminLessonResourceType => 'রিসোর্স ধরন';

  @override
  String get adminLessonTypeYoutube => 'YouTube';

  @override
  String get adminLessonTypePdf => 'PDF';

  @override
  String get adminLessonTypeLink => 'লিংক';

  @override
  String get adminLessonTypeText => 'টেক্সট';

  @override
  String get adminLessonTypeAudio => 'অডিও';

  @override
  String get adminLessonAudioUrl => 'অডিও ফাইল URL (MP3/M4A)';

  @override
  String get adminLessonAudioUrlInvalid =>
      'বৈধ http(s) URL দিন যা .mp3 বা .m4a দিয়ে শেষ হয়।';

  @override
  String get adminLessonYoutubeUrl => 'YouTube URL';

  @override
  String get adminLessonPdfUrl => 'PDF URL';

  @override
  String get adminLessonLinkUrl => 'লিংক URL';

  @override
  String get adminLessonTextContent => 'টেক্সট বিষয়বস্তু';

  @override
  String get adminLessonResourceUrlRequired =>
      'রিসোর্স URL বা বিষয়বস্তু প্রয়োজন।';

  @override
  String get adminLessonThumbnailUrl => 'থাম্বনেইল URL (ঐচ্ছিক)';

  @override
  String get adminLessonDuration => 'সময়কাল (মিনিট, ঐচ্ছিক)';

  @override
  String get adminLessonPublished => 'প্রকাশিত';

  @override
  String get adminQuizTitle => 'কুইজ';

  @override
  String get adminQuizCreateTitle => 'কুইজ তৈরি';

  @override
  String get adminQuizEditTitle => 'কুইজ সম্পাদনা';

  @override
  String get adminQuizFormSaved => 'কুইজ সংরক্ষিত হয়েছে।';

  @override
  String get adminQuizDetailsSection => 'কুইজ সেটিংস';

  @override
  String get adminQuizLinkedLesson => 'সংযুক্ত পাঠ (ঐচ্ছিক)';

  @override
  String get adminQuizScopeCourse => 'কোর্স-স্তরের কুইজ';

  @override
  String get adminQuizTimeLimit => 'সময়সীমা (সেকেন্ড, ০ = নেই)';

  @override
  String get adminQuizPassingScore => 'পাস স্কোর (প্রয়োজনীয় সঠিক উত্তর)';

  @override
  String get adminQuizQuestionsSection => 'প্রশ্ন';

  @override
  String get adminQuizQuestionsEmpty =>
      'এখনো কোনো প্রশ্ন নেই। সংরক্ষণের আগে অন্তত একটি যোগ করুন।';

  @override
  String get adminQuizEmptyList => 'এখনো কোনো কুইজ নেই।';

  @override
  String get adminQuizQuestionsRequired => 'অন্তত একটি প্রশ্ন যোগ করুন।';

  @override
  String get adminQuizPassingScoreTooHigh =>
      'পাস স্কোর প্রশ্ন সংখ্যার বেশি হতে পারে না।';

  @override
  String get adminQuizAddQuestion => 'প্রশ্ন যোগ';

  @override
  String get adminQuizQuestionCreateTitle => 'প্রশ্ন যোগ';

  @override
  String get adminQuizQuestionEditTitle => 'প্রশ্ন সম্পাদনা';

  @override
  String get adminQuizQuestionDeleteTitle => 'প্রশ্ন মুছবেন?';

  @override
  String get adminQuizQuestionTextSection => 'প্রশ্ন';

  @override
  String get adminQuizQuestionText => 'প্রশ্নের টেক্সট';

  @override
  String get adminQuizQuestionTextRequired => 'প্রশ্নের টেক্সট প্রয়োজন।';

  @override
  String get adminQuizOptionsSection => 'উত্তরের অপশন';

  @override
  String get adminQuizSelectCorrectHint =>
      'সঠিক উত্তরের জন্য রেডিও বাটন নির্বাচন করুন।';

  @override
  String adminQuizOptionLabel(int number) {
    return 'অপশন $number';
  }

  @override
  String get adminQuizOptionRequired => 'অপশন প্রয়োজন।';

  @override
  String get adminQuizOptionsMinRequired => 'অন্তত দুটি অপশন প্রয়োজন।';

  @override
  String get adminQuizCorrectAnswerRequired =>
      'টেক্সট সহ একটি সঠিক উত্তর নির্বাচন করুন।';

  @override
  String get adminQuizExplanationSection => 'ব্যাখ্যা';

  @override
  String get adminQuizExplanation => 'ব্যাখ্যা (কুইজের পর দেখানো হবে)';

  @override
  String get adminQuizQuestionDone => 'সম্পন্ন';

  @override
  String adminQuizCorrectAnswer(String answer) {
    return 'উত্তর: $answer';
  }

  @override
  String adminQuizOptionCount(int count) {
    return '$count অপশন';
  }

  @override
  String get syllabusTitle => 'পাঠ্যক্রম';

  @override
  String get syllabusSearchHint => 'কোর্স খুঁজুন…';

  @override
  String get syllabusEmptyList => 'এখনো কোনো প্রকাশিত কোর্স নেই।';

  @override
  String get syllabusLoadFailed => 'কোর্স লোড করা যায়নি।';

  @override
  String get syllabusNoSearchResults =>
      'আপনার অনুসন্ধানের সাথে কোনো কোর্স মিলেনি।';

  @override
  String get syllabusAllTags => 'সব';

  @override
  String get syllabusEnroll => 'ভর্তি হন';

  @override
  String get syllabusEnrolled => 'ভর্তি হয়েছেন';

  @override
  String get syllabusEnrollPrompt =>
      'এই কোর্সে আপনার অগ্রগতি ট্র্যাক করতে ভর্তি হন।';

  @override
  String get syllabusEnrollSuccess => 'আপনি ভর্তি হয়েছেন!';

  @override
  String syllabusProgressLabel(int completed, int total) {
    return '$total পাঠের মধ্যে $completed';
  }

  @override
  String get syllabusCourseCompleted => 'কোর্স সম্পন্ন';

  @override
  String get syllabusLessonsSection => 'পাঠ';

  @override
  String get syllabusNoLessons => 'এখনো কোনো পাঠ প্রকাশিত হয়নি।';

  @override
  String syllabusLessonCount(int count) {
    return '$countটি পাঠ';
  }

  @override
  String get syllabusCourseLoadFailed => 'কোর্স লোড করা যায়নি।';

  @override
  String get syllabusLessonLoadFailed => 'পাঠ লোড করা যায়নি।';

  @override
  String get syllabusMarkComplete => 'সম্পন্ন হিসেবে চিহ্নিত করুন';

  @override
  String get syllabusLessonCompleted => 'পাঠ সম্পন্ন';

  @override
  String get syllabusLessonCompleteSuccess => 'অগ্রগতি সংরক্ষিত!';

  @override
  String get syllabusEnrollToComplete =>
      'পাঠের অগ্রগতি ট্র্যাক করতে এই কোর্সে ভর্তি হন।';

  @override
  String get syllabusOpenPdf => 'PDF খুলুন';

  @override
  String get syllabusOpenLink => 'লিংক খুলুন';

  @override
  String get syllabusInvalidYoutubeUrl => 'এই পাঠের YouTube URL সঠিক নয়।';

  @override
  String get syllabusVideoNowPlaying => 'এখন চলছে';

  @override
  String get syllabusVideoRewind => '১০ সেকেন্ড পেছনে';

  @override
  String get syllabusVideoForward => '১০ সেকেন্ড এগিয়ে';

  @override
  String get syllabusVideoRestart => 'আবার শুরু';

  @override
  String get syllabusVideoMute => 'নিঃশব্দ';

  @override
  String get syllabusVideoUnmute => 'শব্দ চালু';

  @override
  String get syllabusVideoOpenYoutube => 'YouTube-এ খুলুন';

  @override
  String get syllabusLaunchUrlFailed => 'এই রিসোর্স খোলা যায়নি।';

  @override
  String get syllabusQuizTitle => 'কুইজ';

  @override
  String get syllabusQuizLoadFailed => 'এই কুইজ লোড করা যায়নি।';

  @override
  String get syllabusQuizRulesTitle => 'শুরু করার আগে';

  @override
  String syllabusQuizQuestionCount(int count) {
    return '$countটি প্রশ্ন';
  }

  @override
  String syllabusQuizTimeLimitLabel(String limit) {
    return 'সময়সীমা: $limit';
  }

  @override
  String get syllabusQuizNoTimeLimit => 'সময়সীমা নেই';

  @override
  String syllabusQuizPassingScoreLabel(int score) {
    return '$scoreটি সঠিক উত্তরে পাস';
  }

  @override
  String get syllabusQuizPreviousAttempts => 'আপনার চেষ্টা';

  @override
  String syllabusQuizAttemptCount(int count) {
    return '$countটি চেষ্টা';
  }

  @override
  String syllabusQuizAttemptNumber(int number) {
    return 'চেষ্টা #$number';
  }

  @override
  String syllabusQuizAttemptsLabel(int count, int score, int total) {
    return '$countটি চেষ্টা · সেরা $score/$total';
  }

  @override
  String syllabusQuizAttemptHistoryRow(int score, int total, String date) {
    return '$score/$total · $date';
  }

  @override
  String get syllabusQuizAttemptPassed => 'পাস';

  @override
  String get syllabusQuizAttemptFailed => 'অসফল';

  @override
  String syllabusQuizBestScore(int score, int total) {
    return 'সর্বোচ্চ স্কোর: $score / $total';
  }

  @override
  String get syllabusQuizAlreadyPassed => 'আপনি এই কুইজে পাস করেছেন';

  @override
  String get syllabusQuizStart => 'কুইজ শুরু করুন';

  @override
  String syllabusQuizProgress(int current, int total) {
    return 'প্রশ্ন $current / $total';
  }

  @override
  String get syllabusQuizQuestionLabel => 'প্রশ্ন';

  @override
  String get syllabusQuizNext => 'পরবর্তী';

  @override
  String get syllabusQuizPrevious => 'পূর্ববর্তী';

  @override
  String get syllabusQuizSubmit => 'জমা দিন';

  @override
  String get syllabusQuizTimeRemaining => 'বাকি সময়';

  @override
  String get syllabusQuizTimeUp => 'সময় শেষ — আপনার উত্তর জমা দেওয়া হচ্ছে।';

  @override
  String get syllabusQuizConfirmExitTitle => 'কুইজ ছেড়ে যাবেন?';

  @override
  String get syllabusQuizConfirmExitMessage =>
      'এই চেষ্টার অগ্রগতি হারিয়ে যাবে।';

  @override
  String get syllabusQuizLeave => 'ছেড়ে যান';

  @override
  String get syllabusQuizResultTitle => 'কুইজ ফলাফল';

  @override
  String get syllabusQuizResultPassed => 'পাস!';

  @override
  String get syllabusQuizResultFailed => 'পাস হয়নি';

  @override
  String syllabusQuizYourScore(int score, int total) {
    return 'স্কোর: $score / $total';
  }

  @override
  String syllabusQuizTimeTaken(String time) {
    return 'সময় লেগেছে: $time';
  }

  @override
  String get syllabusQuizReviewSection => 'উত্তর পর্যালোচনা';

  @override
  String syllabusQuizReviewQuestion(int number) {
    return 'প্রশ্ন $number';
  }

  @override
  String get syllabusQuizYourAnswer => 'আপনার উত্তর';

  @override
  String get syllabusQuizCorrectAnswer => 'সঠিক উত্তর';

  @override
  String get syllabusQuizExplanation => 'ব্যাখ্যা';

  @override
  String get syllabusQuizRetry => 'আবার চেষ্টা করুন';

  @override
  String get syllabusQuizBackToCourse => 'কোর্সে ফিরে যান';

  @override
  String get syllabusQuizExcellent => 'অসাধারণ!';

  @override
  String get syllabusQuizGoodEffort => 'ভালো চেষ্টা!';

  @override
  String get syllabusQuizKeepLearning => 'শেখা চালিয়ে যান!';

  @override
  String get syllabusQuizNotReady => 'এই কুইজ এখনো প্রস্তুত নয়।';

  @override
  String get syllabusQuizBismillahTitle => 'বিসমিল্লাহ দিয়ে শুরু করুন';

  @override
  String get syllabusQuizBismillahArabic =>
      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  String get syllabusQuizBismillahTranslation =>
      'পরম করুণাময় ও অসীম দয়ালু আল্লাহর নামে।';

  @override
  String get syllabusQuizBismillahIntention =>
      'হে আল্লাহ, আমাকে উপকারী জ্ঞান ও সঠিক বোঝাপড়া দান করুন।';

  @override
  String get syllabusQuizBismillahBegin => 'কুইজ শুরু করুন';

  @override
  String get lmsXpSectionTitle => 'শিক্ষার অগ্রগতি';

  @override
  String lmsXpLabel(int xp) {
    return '$xp XP';
  }

  @override
  String lmsXpToNextLevel(int xp) {
    return 'পরবর্তী স্তরে $xp XP';
  }

  @override
  String get lmsLevelUpTitle => 'নতুন স্তর!';

  @override
  String get lmsLevelUpTapToContinue => 'চালিয়ে যেতে ট্যাপ করুন';

  @override
  String get lessonDiscussionTitle => 'আলোচনা';

  @override
  String get lessonDiscussionEmpty =>
      'এখনো কোনো মন্তব্য নেই। আপনার পড়াশোনার দলের সাথে কথোপকথন শুরু করুন।';

  @override
  String get lessonDiscussionHint => 'এই পাঠ সম্পর্কে আপনার মতামত শেয়ার করুন…';

  @override
  String get lessonDiscussionPost => 'পোস্ট';

  @override
  String get lessonDiscussionPostFailed =>
      'মন্তব্য পোস্ট করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get lessonDiscussionLoadFailed => 'আলোচনা লোড করা যায়নি।';

  @override
  String get lessonDiscussionEnrollPrompt =>
      'আলোচনায় যোগ দিতে এই কোর্সে এনরোল করুন।';

  @override
  String get lessonDiscussionEditTitle => 'মন্তব্য সম্পাদনা';

  @override
  String get lessonDiscussionEditFailed =>
      'মন্তব্য সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get lessonDiscussionEdited => 'সম্পাদিত';

  @override
  String get courseCertificateTitle => 'সমাপনী সনদ';

  @override
  String get courseCertificateArabic => 'بارك الله فيك';

  @override
  String get courseCertificatePresentedTo => 'সম্মানিত';

  @override
  String get courseCertificateForCourse => 'কোর্স সম্পন্নের জন্য';

  @override
  String courseCertificateDate(String date) {
    return 'সম্পন্ন: $date';
  }

  @override
  String get courseCertificateShare => 'শেয়ার';

  @override
  String get courseCertificateView => 'সনদ দেখুন';

  @override
  String get syllabusBookmarkedFilter => 'বুকমার্ক';

  @override
  String get syllabusBookmarksEmpty => 'এখনো কোনো বুকমার্ক নেই।';

  @override
  String get syllabusAudioLoadFailed => 'অডিও লেসন লোড করা যায়নি।';

  @override
  String get quranTitle => 'কুরআন';

  @override
  String get quranSurahList => 'সূরাসমূহ';

  @override
  String get quranReader => 'মুসহাফ পাঠ';

  @override
  String get quranMeccan => 'মাক্কী';

  @override
  String get quranMedinan => 'মাদানী';

  @override
  String quranAyahs(int count) {
    return '$count আয়াত';
  }

  @override
  String quranPage(int page) {
    return 'পৃষ্ঠা $page';
  }

  @override
  String quranJuz(int juz) {
    return 'পারা $juz';
  }

  @override
  String get quranTranslation => 'অনুবাদ';

  @override
  String get quranSelectTranslator => 'অনুবাদক নির্বাচন';

  @override
  String get quranSelectQari => 'ক্বারী নির্বাচন';

  @override
  String get quranTranslatorKhan => 'মুহিউদ্দীন খান';

  @override
  String get quranTranslatorSahih => 'সহীহ ইন্টারন্যাশনাল';

  @override
  String get quranSearchHint => 'সূরা খুঁজুন...';

  @override
  String quranContinueReading(int page) {
    return 'পৃষ্ঠা $page থেকে চালিয়ে যান';
  }

  @override
  String get quranOpenReader => 'খুলুন';

  @override
  String get quranFontSize => 'আরবি টেক্সট সাইজ';

  @override
  String get quranNoTranslation => 'অনুবাদ লুকানো বা উপলব্ধ নয়';

  @override
  String quranAyahLabel(int ayah) {
    return 'আয়াত $ayah';
  }

  @override
  String get quranJumpToPage => 'পৃষ্ঠায় যান';

  @override
  String get quranJumpToSurah => 'সূরায় যান';

  @override
  String get quranMushafMode => 'মুসহাফ দেখুন';

  @override
  String get quranSurahMode => 'সূরার তালিকা';

  @override
  String quranPageOf(int page, int total) {
    return 'পৃষ্ঠা $page / $total';
  }

  @override
  String get quranTranslationFontSize => 'অনুবাদ টেক্সট সাইজ';

  @override
  String get quranPageTheme => 'পৃষ্ঠার থিম';

  @override
  String get quranJumpToAyah => 'আয়াতে যান';

  @override
  String get quranJumpToAyahHint => 'আয়াত নম্বর লিখুন';

  @override
  String get quranAyahCopied => 'আয়াত ক্লিপবোর্ডে কপি হয়েছে';

  @override
  String get qiblaTitle => 'কিবলা';

  @override
  String get qiblaGrantLocationPermission => 'লোকেশন পারমিশন দিন';

  @override
  String get qiblaOpenSettings => 'সেটিংস খুলুন';

  @override
  String get qiblaNorth => 'উ';

  @override
  String get qiblaEast => 'পূ';

  @override
  String get qiblaSouth => 'দ';

  @override
  String get qiblaWest => 'প';

  @override
  String get termsAndConditions => 'শর্তাবলী';

  @override
  String get privacyPolicy => 'প্রাইভেসি পলিসি';
}
