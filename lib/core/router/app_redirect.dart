import 'package:firebase_auth/firebase_auth.dart';

import '../constants/admin_config.dart';
import '../services/firestore_service.dart';
import 'routes.dart';

/// Auth-aware redirect used by [GoRouter] (except on launch/dev).
Future<String?> redirectForLocation(
  FirestoreService firestoreService,
  String location,
) async {
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

  final isAdminRoute = location.startsWith('/admin');
  if (isAdminRoute && !AdminConfig.isAdmin(authUser.uid)) {
    return AppRoutes.home;
  }

  return null;
}

/// First real screen after the launch route (sign-in, onboarding, or home).
Future<String> destinationAfterLaunch(FirestoreService firestoreService) async {
  return await redirectForLocation(firestoreService, AppRoutes.home) ??
      AppRoutes.home;
}
