import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/user_profile_screen.dart';
import '../../features/history/presentation/screens/day_detail_screen.dart';
import '../../features/history/presentation/screens/edit_amal_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/day_complete_screen.dart';
import '../../models/amal_log_model.dart';
import '../../features/home/presentation/screens/empty_state_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import '../../features/settings/presentation/screens/quiet_hours_screen.dart';
import '../../features/settings/presentation/screens/reminder_times_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/dhikr/presentation/screens/dhikr_counter_screen.dart';
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
          return DayDetailScreen(hijriDate: date);
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
          return EditAmalScreen(
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
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: AppColors.emeraldDeep,
      body: Center(
        child: Text(
          'Route not found: ${state.uri.path}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    ),
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
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
