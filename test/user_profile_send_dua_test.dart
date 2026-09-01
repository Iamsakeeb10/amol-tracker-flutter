import 'package:amol_tracker_app/features/community/presentation/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required Future<bool> Function(String phrase) onSend,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: DuaPhraseSheet(onSend: onSend),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('DuaPhraseSheet', () {
    testWidgets('send button is disabled until a phrase is selected', (
      tester,
    ) async {
      var sendCount = 0;
      await pumpSheet(
        tester,
        onSend: (_) async {
          sendCount++;
          return true;
        },
      );

      final sendButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'পাঠান'),
      );
      expect(sendButton.onPressed, isNull);

      await tester.tap(find.text('পাঠান'));
      await tester.pump();
      expect(sendCount, 0);
    });

    testWidgets('tapping send invokes onSend with the selected phrase', (
      tester,
    ) async {
      String? sentPhrase;
      await pumpSheet(
        tester,
        onSend: (phrase) async {
          sentPhrase = phrase;
          return true;
        },
      );

      await tester.tap(find.text('মাশা আল্লাহ'));
      await tester.pumpAndSettle();

      final sendButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'পাঠান'),
      );
      expect(sendButton.onPressed, isNotNull);

      await tester.tap(find.text('পাঠান'));
      await tester.pumpAndSettle();

      expect(sentPhrase, 'মাশা আল্লাহ');
    });
  });
}
