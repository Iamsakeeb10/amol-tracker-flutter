import 'package:amol_tracker_app/core/router/app_redirect.dart';
import 'package:amol_tracker_app/core/router/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var refreshCalled = false;
  var signOutCalled = false;

  Future<void> refreshAuthToken() async {
    refreshCalled = true;
  }

  Future<void> signOut() async {
    signOutCalled = true;
  }

  Future<void> noopRecordError(
    Object error,
    StackTrace stack, {
    String? reason,
  }) async {}

  setUp(() {
    refreshCalled = false;
    signOutCalled = false;
  });

  group('resolveLaunchDestination', () {
    test('returns sign-in when auth uid is null', () async {
      final destination = await resolveLaunchDestination(
        authUid: null,
        refreshAuthToken: refreshAuthToken,
        signOut: signOut,
        checkUserExists: (_) async => true,
        recordError: noopRecordError,
      );

      expect(destination, AppRoutes.signIn);
      expect(refreshCalled, isFalse);
      expect(signOutCalled, isFalse);
    });

    test('returns home when user profile exists', () async {
      final destination = await resolveLaunchDestination(
        authUid: 'uid-1',
        refreshAuthToken: refreshAuthToken,
        signOut: signOut,
        checkUserExists: (_) async => true,
        recordError: noopRecordError,
      );

      expect(destination, AppRoutes.home);
      expect(refreshCalled, isTrue);
      expect(signOutCalled, isFalse);
    });

    test('returns onboarding when user profile is missing', () async {
      final destination = await resolveLaunchDestination(
        authUid: 'uid-1',
        refreshAuthToken: refreshAuthToken,
        signOut: signOut,
        checkUserExists: (_) async => false,
        recordError: noopRecordError,
      );

      expect(destination, AppRoutes.onboarding);
      expect(refreshCalled, isTrue);
      expect(signOutCalled, isFalse);
    });

    test('signs out and returns sign-in on permission-denied', () async {
      final destination = await resolveLaunchDestination(
        authUid: 'uid-1',
        refreshAuthToken: refreshAuthToken,
        signOut: signOut,
        checkUserExists: (_) async {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'The caller does not have permission',
          );
        },
        recordError: noopRecordError,
      );

      expect(destination, AppRoutes.signIn);
      expect(refreshCalled, isTrue);
      expect(signOutCalled, isTrue);
    });

    test('returns sign-in on other Firestore errors without signing out', () async {
      final destination = await resolveLaunchDestination(
        authUid: 'uid-1',
        refreshAuthToken: refreshAuthToken,
        signOut: signOut,
        checkUserExists: (_) async {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
            message: 'Service unavailable',
          );
        },
        recordError: noopRecordError,
      );

      expect(destination, AppRoutes.signIn);
      expect(refreshCalled, isTrue);
      expect(signOutCalled, isFalse);
    });

    test('returns sign-in on generic errors without signing out', () async {
      final destination = await resolveLaunchDestination(
        authUid: 'uid-1',
        refreshAuthToken: refreshAuthToken,
        signOut: signOut,
        checkUserExists: (_) async {
          throw StateError('unexpected');
        },
        recordError: noopRecordError,
      );

      expect(destination, AppRoutes.signIn);
      expect(refreshCalled, isTrue);
      expect(signOutCalled, isFalse);
    });
  });
}
