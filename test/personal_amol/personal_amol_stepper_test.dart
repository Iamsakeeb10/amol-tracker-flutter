import 'package:amol_tracker_app/features/personal_amol/presentation/widgets/personal_amol_stepper.dart';
import 'package:amol_tracker_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({
    required int doneCount,
    required int target,
    required bool Function() onDialogOpened,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: GestureDetector(
            onTap: () => onDialogOpened(),
            child: PersonalAmolStepper(
              doneCount: doneCount,
              target: target,
              onIncrement: () {},
              onDecrement: () {},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpStepper(
    WidgetTester tester, {
    required int doneCount,
    required int target,
    required bool Function() onDialogOpened,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => wrap(
          doneCount: doneCount,
          target: target,
          onDialogOpened: onDialogOpened,
          locale: locale,
        ),
      ),
    );
  }

  testWidgets('tapping + at the target shows snackbar, no dialog', (tester) async {
    var dialogOpened = false;
    await pumpStepper(
      tester,
      doneCount: 5,
      target: 5,
      onDialogOpened: () => dialogOpened = true,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(dialogOpened, isFalse);
    expect(find.text('Target reached!'), findsOneWidget);
  });

  testWidgets('tapping − at 0 shows snackbar, no dialog', (tester) async {
    var dialogOpened = false;
    await pumpStepper(
      tester,
      doneCount: 0,
      target: 5,
      onDialogOpened: () => dialogOpened = true,
    );

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(dialogOpened, isFalse);
    expect(find.text('Already at 0'), findsOneWidget);
  });

  testWidgets('snackbar close action dismisses it immediately', (tester) async {
    await pumpStepper(
      tester,
      doneCount: 5,
      target: 5,
      onDialogOpened: () => false,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Target reached!'), findsOneWidget);

    await tester.tap(find.byType(SnackBarAction), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Target reached!'), findsNothing);
  });

  testWidgets('limit snackbar is localized in bn', (tester) async {
    await pumpStepper(
      tester,
      doneCount: 0,
      target: 5,
      onDialogOpened: () => false,
      locale: const Locale('bn'),
    );

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(
      find.text('গণনা এখন ০, আর কমানো যাবে না'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('middle taps still work and do not open dialogue', (tester) async {
    var dialogOpened = false;
    await pumpStepper(
      tester,
      doneCount: 2,
      target: 5,
      onDialogOpened: () => dialogOpened = true,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(dialogOpened, isFalse, reason: 'parent onTap must not fire');
    expect(find.text('Target reached!'), findsNothing);
    expect(find.text('Already at 0'), findsNothing);
  });
}
