import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/admin/presentation/screens/admin_announcement_form_screen.dart';
import '../../features/admin/presentation/screens/admin_announcements_screen.dart';
import '../../features/admin/presentation/screens/admin_amal_field_form_screen.dart';
import '../../features/admin/presentation/screens/admin_amal_fields_screen.dart';
import '../../features/admin/presentation/screens/admin_course_form_screen.dart';
import '../../features/admin/presentation/screens/admin_course_list_screen.dart';
import '../../features/admin/presentation/screens/admin_lesson_form_screen.dart';
import '../../features/admin/presentation/screens/admin_lesson_list_screen.dart';
import '../../features/admin/presentation/screens/admin_question_editor_screen.dart';
import '../../features/admin/presentation/screens/admin_quiz_form_screen.dart';
import '../../features/admin/presentation/screens/admin_push_notification_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/user_profile_screen.dart';
import '../../features/history/presentation/widgets/edit_amal_route_guard.dart';
import '../../features/history/presentation/widgets/history_date_route_guard.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/day_complete_screen.dart';
import '../../models/amal_log_model.dart';
import '../../core/constants/amal_fields.dart';
import '../../models/announcement_model.dart';
import '../../models/course_model.dart';
import '../../features/admin/presentation/widgets/admin_course_helpers.dart';
import '../../features/admin/presentation/widgets/admin_quiz_helpers.dart';
import '../../features/home/presentation/screens/empty_state_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import '../../features/settings/presentation/screens/quiet_hours_screen.dart';
import '../../features/settings/presentation/screens/prayer_reminder_screen.dart';
import '../../features/settings/presentation/screens/reminder_times_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/asma_ul_husna/presentation/screens/asma_ul_husna_screen.dart';
import '../../features/dhikr/presentation/screens/dhikr_counter_screen.dart';
import '../../features/hijri_calendar/presentation/screens/hijri_calendar_screen.dart';
import '../../features/syllabus/presentation/screens/course_detail_screen.dart';
import '../../features/syllabus/presentation/screens/lesson_viewer_screen.dart';
import '../../features/syllabus/presentation/screens/quiz_intro_screen.dart';
import '../../features/syllabus/presentation/screens/quiz_question_screen.dart';
import '../../features/syllabus/presentation/screens/quiz_result_screen.dart';
import '../../features/syllabus/presentation/screens/syllabus_library_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_launch_route.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/dev_screen.dart';
import '../services/firestore_service.dart';
import '../theme/colors.dart';
import 'app_redirect.dart';
import 'routes.dart';

GoRouter buildAppRouter() {
  final firestoreService = FirestoreService();
  return GoRouter(
    initialLocation: AppRoutes.launch,
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (_, state) =>
        redirectForLocation(firestoreService, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.launch,
        name: 'launch',
        builder: (_, _) =>
            AppLaunchRoute(firestoreService: firestoreService),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.dev,
        name: 'dev',
        builder: (_, _) => const DevScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (_, _) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            builder: (_, _) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.community,
            name: 'community',
            builder: (_, _) => const CommunityScreen(),
          ),
          GoRoute(
            path: AppRoutes.more,
            name: 'more',
            builder: (_, _) => const MoreScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.dayComplete,
        name: 'dayComplete',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! AmalLogModel) {
            return _DayCompleteRedirect();
          }
          return DayCompleteScreen(log: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.emptyState,
        name: 'emptyState',
        builder: (_, _) => const EmptyStateScreen(),
      ),
      GoRoute(
        path: AppRoutes.dayDetailPattern,
        name: 'dayDetail',
        builder: (_, state) {
          final date = state.pathParameters['date'] ?? '';
          return HistoryDateRouteGuard(hijriDate: date);
        },
      ),
      GoRoute(
        path: AppRoutes.editAmalPattern,
        name: AppRoutes.editAmal,
        builder: (_, state) {
          final hijriDate = state.pathParameters['date'] ?? '';
          final existingLog = state.extra is AmalLogModel
              ? state.extra as AmalLogModel
              : null;
          return EditAmalRouteGuard(
            hijriDate: hijriDate,
            existingLog: existingLog,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.userProfile}/:id',
        name: 'userProfile',
        builder: (_, state) {
          final extra = state.extra;
          return UserProfileScreen(
            userId: state.pathParameters['id'] ?? '',
            selectedHijriDate: state.uri.queryParameters['date'],
            selectedLogFallback: extra is AmalLogModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        name: 'leaderboard',
        builder: (_, _) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.dhikr,
        name: 'dhikr',
        builder: (_, _) => const DhikrCounterScreen(),
      ),
      GoRoute(
        path: AppRoutes.asmaUlHusna,
        name: 'asmaUlHusna',
        builder: (_, _) => const AsmaUlHusnaScreen(),
      ),
      GoRoute(
        path: AppRoutes.hijriCalendar,
        name: 'hijriCalendar',
        builder: (_, _) => const HijriCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.syllabus,
        name: 'syllabus',
        builder: (_, _) => const SyllabusLibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.courseDetailPattern,
        name: 'courseDetail',
        builder: (_, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return CourseDetailScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: AppRoutes.lessonViewerPattern,
        name: 'lessonViewer',
        builder: (_, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final lessonId = state.pathParameters['lessonId'] ?? '';
          return LessonViewerScreen(courseId: courseId, lessonId: lessonId);
        },
      ),
      GoRoute(
        path: AppRoutes.quizIntroPattern,
        name: 'quizIntro',
        builder: (_, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final quizId = state.pathParameters['quizId'] ?? '';
          return QuizIntroScreen(courseId: courseId, quizId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.quizPlayPattern,
        name: 'quizPlay',
        builder: (_, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final quizId = state.pathParameters['quizId'] ?? '';
          return QuizQuestionScreen(courseId: courseId, quizId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.quizResultPattern,
        name: 'quizResult',
        builder: (_, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final quizId = state.pathParameters['quizId'] ?? '';
          return QuizResultScreen(courseId: courseId, quizId: quizId);
        },
      ),
      GoRoute(
        path: AppRoutes.adminAnnouncements,
        name: 'adminAnnouncements',
        builder: (_, _) => const AdminAnnouncementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAnnouncementForm,
        name: 'adminAnnouncementForm',
        builder: (_, state) {
          final extra = state.extra;
          return AdminAnnouncementFormScreen(
            existing: extra is AnnouncementModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminPushNotification,
        name: 'adminPushNotification',
        builder: (_, _) => const AdminPushNotificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAmalFields,
        name: 'adminAmalFields',
        builder: (_, _) => const AdminAmalFieldsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAmalFieldForm,
        name: 'adminAmalFieldForm',
        builder: (_, state) {
          final extra = state.extra;
          return AdminAmalFieldFormScreen(
            existing: extra is AmalField ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminCourses,
        name: 'adminCourses',
        builder: (_, _) => const AdminCourseListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCourseForm,
        name: 'adminCourseForm',
        builder: (_, state) {
          final extra = state.extra;
          return AdminCourseFormScreen(
            existing: extra is CourseModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminLessonsPattern,
        name: 'adminLessons',
        builder: (_, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          return AdminLessonListScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: AppRoutes.adminLessonForm,
        name: 'adminLessonForm',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! AdminLessonFormArgs) {
            return const AdminCourseListScreen();
          }
          return AdminLessonFormScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.adminQuizForm,
        name: 'adminQuizForm',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! AdminQuizFormArgs) {
            return const AdminCourseListScreen();
          }
          return AdminQuizFormScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.adminQuestionEditor,
        name: 'adminQuestionEditor',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! AdminQuestionEditorArgs) {
            return const AdminCourseListScreen();
          }
          return AdminQuestionEditorScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'quiet-hours',
            name: 'quietHours',
            builder: (_, _) => const QuietHoursScreen(),
          ),
          GoRoute(
            path: 'reminder-times',
            name: 'reminderTimes',
            builder: (_, _) => const ReminderTimesScreen(),
          ),
          GoRoute(
            path: 'prayer-adhan',
            name: 'prayerAdhan',
            builder: (_, _) => const PrayerReminderScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: AppColors.emeraldDeep,
        body: Center(
          child: Text(
            l10n?.routeNotFound(state.uri.path) ??
                'Route not found: ${state.uri.path}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    },
  );
}

/// Shown briefly when opening day-complete without a submitted [AmalLogModel].
class _DayCompleteRedirect extends StatefulWidget {
  @override
  State<_DayCompleteRedirect> createState() => _DayCompleteRedirectState();
}

class _DayCompleteRedirectState extends State<_DayCompleteRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
