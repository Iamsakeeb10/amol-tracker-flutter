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

  static const editAmal = 'editAmal';
  static const editAmalPattern = '/history/edit-amal/:date';

  static String editAmalPath(String hijriDate) =>
      '/history/edit-amal/$hijriDate';

  static const community = '/community';
  static const userProfile = '/community/user-profile';

  static const dua = '/dua';
  static const more = '/more';
  static const leaderboard = '/leaderboard';
  static const reports = '/reports';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const settings = '/settings';
  static const feedback = '/settings/feedback';
  static const submitFeedback = '/settings/feedback/submit';
  static const quietHours = '/settings/quiet-hours';
  static const reminderTimes = '/settings/reminder-times';
  static const prayerAdhan = '/settings/prayer-adhan';

  static const dhikr = '/dhikr';
  static const asmaUlHusna = '/asma-ul-husna';
  static const hijriCalendar = '/hijri-calendar';
  static const qibla = '/qibla';

  static const quran = '/quran';
  static const quranSurahScrollPattern = '/quran/surah/:surahId';

  static String quranSurahScrollPath(int surahId) => '/quran/surah/$surahId';

  static const syllabus = '/syllabus';
  static const courseDetailPattern = '/syllabus/courses/:courseId';

  static String courseDetailPath(String courseId) =>
      '/syllabus/courses/$courseId';

  static const lessonViewerPattern =
      '/syllabus/courses/:courseId/lessons/:lessonId';

  static String lessonViewerPath(String courseId, String lessonId) =>
      '/syllabus/courses/$courseId/lessons/$lessonId';

  static const quizIntroPattern =
      '/syllabus/courses/:courseId/quizzes/:quizId';

  static String quizIntroPath(String courseId, String quizId) =>
      '/syllabus/courses/$courseId/quizzes/$quizId';

  static const quizBismillahPattern =
      '/syllabus/courses/:courseId/quizzes/:quizId/bismillah';

  static String quizBismillahPath(String courseId, String quizId) =>
      '/syllabus/courses/$courseId/quizzes/$quizId/bismillah';

  static const quizPlayPattern =
      '/syllabus/courses/:courseId/quizzes/:quizId/play';

  static String quizPlayPath(String courseId, String quizId) =>
      '/syllabus/courses/$courseId/quizzes/$quizId/play';

  static const quizResultPattern =
      '/syllabus/courses/:courseId/quizzes/:quizId/result';

  static String quizResultPath(String courseId, String quizId) =>
      '/syllabus/courses/$courseId/quizzes/$quizId/result';

  static const dev = '/dev';

  static const adminAnnouncements = '/admin/announcements';
  static const adminFeedbacks = '/admin/feedbacks';
  static const adminAnnouncementForm = '/admin/announcement-form';
  static const adminPushNotification = '/admin/push-notification';
  static const adminAmalFields = '/admin/amal-fields';
  static const adminAmalFieldForm = '/admin/amal-field-form';

  static const adminCourses = '/admin/courses';
  static const adminCourseForm = '/admin/course-form';
  static const adminLessonsPattern = '/admin/courses/:courseId/lessons';
  static const adminLessonForm = '/admin/lesson-form';
  static const adminQuizForm = '/admin/quiz-form';
  static const adminQuestionEditor = '/admin/question-editor';

  static const adminAppConfigList = '/admin/app-configs';
  static const adminAppConfigForm = '/admin/app-config-form';
  static const adminKnowledgeBattle = '/admin/knowledge-battle';

  static String adminLessonsPath(String courseId) =>
      '/admin/courses/$courseId/lessons';
}
