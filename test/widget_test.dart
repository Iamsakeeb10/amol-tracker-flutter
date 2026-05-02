import 'package:amol_tracker_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, _) => const AmolTrackerApp(),
      ),
    );
  }

  testWidgets('App boots and Sign In screen renders', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Amol Tracker'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('Tapping "Continue as guest" navigates to onboarding',
      (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Build a daily habit'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Skipping onboarding lands on Home with bottom nav',
      (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Sunday'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Friends'), findsWidgets);
    expect(find.text('More'), findsWidgets);
  });
}
