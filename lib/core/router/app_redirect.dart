import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../constants/admin_config.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/syllabus_service.dart';
import 'routes.dart';

/// Auth-aware redirect used by [GoRouter] (except on launch/dev).
Future<String?> redirectForLocation(
  FirestoreService firestoreService,
  GoRouterState state,
) async {
  final location = state.uri.path;
  try {
    final authUser = FirebaseAuth.instance.currentUser;
    final isSigningIn = location == AppRoutes.signIn;
    final isOnboarding = location == AppRoutes.onboarding;
    final isDev = location == AppRoutes.dev;
    final isLaunch = location == AppRoutes.launch;

    if (isDev || isLaunch) return null;
    
    // If user is not logged in
    if (authUser == null) {
      if (isSigningIn) return null;
      final returnUrl = Uri.encodeComponent(state.uri.toString());
      return '${AppRoutes.signIn}?continue=$returnUrl';
    }

    // User is logged in but hasn't completed onboarding
    final userExists = await firestoreService.userExists(authUser.uid);
    if (!userExists) {
      if (isOnboarding) return null;
      final continueUrl = state.uri.queryParameters['continue'];
      if (continueUrl != null && continueUrl.isNotEmpty) {
        return '${AppRoutes.onboarding}?continue=${Uri.encodeComponent(continueUrl)}';
      }
      return AppRoutes.onboarding;
    }

    // User is logged in and exists, redirect away from auth screens
    if (isSigningIn || isOnboarding) {
      final continueUrl = state.uri.queryParameters['continue'];
      if (continueUrl != null && continueUrl.isNotEmpty) {
        return continueUrl;
      }
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
Future<String> destinationAfterLaunch(FirestoreService firestoreService) {
  return resolveLaunchDestination(
    firestoreService: firestoreService,
    authUid: FirebaseAuth.instance.currentUser?.uid,
    refreshAuthToken: () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true);
      }
    },
    signOut: () => AuthService().signOut(),
    recordError: AnalyticsService.instance.recordError,
  );
}

/// Resolves the post-launch route with Firestore/auth error handling.
@visibleForTesting
Future<String> resolveLaunchDestination({
  FirestoreService? firestoreService,
  required String? authUid,
  required Future<void> Function() refreshAuthToken,
  required Future<void> Function() signOut,
  Future<bool> Function(String uid)? checkUserExists,
  Future<void> Function(
    Object error,
    StackTrace stack, {
    String? reason,
  })? recordError,
}) async {
  assert(
    firestoreService != null || checkUserExists != null,
    'Provide firestoreService or checkUserExists',
  );

  if (authUid == null) return AppRoutes.signIn;

  try {
    await refreshAuthToken();
    final exists = checkUserExists != null
        ? await checkUserExists(authUid)
        : await firestoreService!.userExists(authUid);
    if (!exists) return AppRoutes.onboarding;
    return AppRoutes.home;
  } catch (e, st) {
    final reportError = recordError ?? AnalyticsService.instance.recordError;
    await reportError(
      e,
      st,
      reason: 'Launch destination lookup failed',
    );

    if (e is FirebaseException && e.code == 'permission-denied') {
      await signOut();
    }

    return AppRoutes.signIn;
  }
}
