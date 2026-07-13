import 'package:firebase_auth/firebase_auth.dart';

import '../constants/admin_config.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/syllabus_service.dart';
import 'routes.dart';

/// Auth-aware redirect used by [GoRouter] (except on launch/dev).
Future<String?> redirectForLocation(
  FirestoreService firestoreService,
  String location,
) async {
  try {
    final authUser = FirebaseAuth.instance.currentUser;
    final isSigningIn = location == AppRoutes.signIn;
    final isOnboarding = location == AppRoutes.onboarding;
    final isDev = location == AppRoutes.dev;
    final isLaunch = location == AppRoutes.launch;

    if (isDev || isLaunch) return null;
    if (authUser == null) {
      return isSigningIn ? null : AppRoutes.signIn;
    }

    final userExists = await firestoreService.userExists(authUser.uid);
    if (!userExists) {
      return isOnboarding ? null : AppRoutes.onboarding;
    }

    if (isSigningIn || isOnboarding) {
      return AppRoutes.home;
    }

    if (location.startsWith('/admin')) {
      final user = await firestoreService.fetchUser(authUser.uid);
      final email = user?.email;
      final role = user?.role;

      if (AdminConfig.isFullAdminRoute(location)) {
        if (!AdminConfig.isFullAdmin(email, role: role)) {
          return AppRoutes.home;
        }
        return null;
      }

      if (AdminConfig.isCourseAdminRoute(location)) {
        if (AdminConfig.canAccessCourseAdmin(email, role: role)) {
          return null;
        }
        final isListedModerator =
            await SyllabusService().isListedCourseModerator(email ?? '');
        if (!isListedModerator) {
          return AppRoutes.home;
        }
        return null;
      }

      if (!AdminConfig.isFullAdmin(email, role: role)) {
        return AppRoutes.home;
      }
    }

    return null;
  } catch (e, st) {
    AnalyticsService.instance.recordError(
      e,
      st,
      reason: 'GoRouter redirect failed — Firestore unavailable',
    );
    // Admin routes fail-closed, regular routes fail-open
    if (location.startsWith('/admin')) {
      return AppRoutes.home;
    }
    return null;
  }
}

/// First real screen after the launch route (sign-in, onboarding, or home).
Future<String> destinationAfterLaunch(FirestoreService firestoreService) async {
  return await redirectForLocation(firestoreService, AppRoutes.home) ??
      AppRoutes.home;
}
