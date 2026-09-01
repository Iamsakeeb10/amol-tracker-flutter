import 'package:amol_tracker_app/core/router/safe_back_button_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('SafeBackButtonDispatcher', () {
    test('returns false without throwing when route matches are empty', () async {
      late GoRouter router;
      final dispatcher = SafeBackButtonDispatcher(() => router);
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );

      expect(router.routerDelegate.currentConfiguration.isEmpty, isTrue);

      expect(await dispatcher.didPopRoute(), isFalse);
    });

    testWidgets('uses custom dispatcher with MaterialApp.router delegates', (
      tester,
    ) async {
      late GoRouter router;
      final dispatcher = SafeBackButtonDispatcher(() => router);
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Text('home'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routeInformationProvider: router.routeInformationProvider,
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          backButtonDispatcher: dispatcher,
        ),
      );

      expect(await dispatcher.didPopRoute(), isA<bool>());

      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.isEmpty, isFalse);
    });
  });
}
