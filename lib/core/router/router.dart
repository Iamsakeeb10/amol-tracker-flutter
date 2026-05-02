import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/friends/presentation/screens/friend_profile_screen.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/friends/presentation/screens/group_manage_screen.dart';
import '../../features/friends/presentation/screens/group_sheet_screen.dart';
import '../../features/friends/presentation/screens/invite_screen.dart';
import '../../features/history/presentation/screens/day_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/day_complete_screen.dart';
import '../../features/home/presentation/screens/empty_state_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import '../../features/settings/presentation/screens/quiet_hours_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/dev_screen.dart';
import 'routes.dart';

GoRouter buildAppRouter() => GoRouter(
  initialLocation: AppRoutes.signIn,
  debugLogDiagnostics: false,
  routes: [
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

    // Main shell with bottom nav (4 tabs: Home, History, Friends, More)
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
          path: AppRoutes.friends,
          name: 'friends',
          builder: (_, _) => const FriendsScreen(),
        ),
        GoRoute(
          path: AppRoutes.more,
          name: 'more',
          builder: (_, _) => const MoreScreen(),
        ),
      ],
    ),

    // Full-screen routes (no bottom nav)
    GoRoute(
      path: AppRoutes.dayComplete,
      name: 'dayComplete',
      builder: (_, _) => const DayCompleteScreen(),
    ),
    GoRoute(
      path: AppRoutes.emptyState,
      name: 'emptyState',
      builder: (_, _) => const EmptyStateScreen(),
    ),
    GoRoute(
      path: AppRoutes.dayDetail,
      name: 'dayDetail',
      builder: (_, _) => const DayDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.invite,
      name: 'invite',
      builder: (_, _) => const InviteScreen(),
    ),
    GoRoute(
      path: AppRoutes.groupSheet,
      name: 'groupSheet',
      builder: (_, _) => const GroupSheetScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.friendProfile}/:id',
      name: 'friendProfile',
      builder: (_, state) =>
          FriendProfileScreen(friendId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.groupManage,
      name: 'groupManage',
      builder: (_, _) => const GroupManageScreen(),
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
      path: AppRoutes.settings,
      name: 'settings',
      builder: (_, _) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.quietHours,
      name: 'quietHours',
      builder: (_, _) => const QuietHoursScreen(),
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(
      child: Text(
        'Route not found: ${state.uri.path}',
        style: const TextStyle(color: Colors.white70),
      ),
    ),
  ),
);

