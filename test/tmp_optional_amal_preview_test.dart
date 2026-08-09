import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amol_tracker_app/core/constants/amal_fields.dart';
import 'package:amol_tracker_app/core/theme/colors.dart';
import 'package:amol_tracker_app/features/home/presentation/widgets/home_optional_amal_section.dart';
import 'package:amol_tracker_app/l10n/app_localizations.dart';

Future<void> _loadBengaliFont() async {
  final loader = FontLoader('NotoSansBengali');
  final bytes = await File('assets/fonts/NotoSansBengali-Variable.ttf')
      .readAsBytes();
  loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  testWidgets('optional amal header preview', (tester) async {
    await _loadBengaliFont();
    tester.view.physicalSize = const Size(390 * 3, 200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            locale: const Locale('bn'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              backgroundColor: AppColors.emeraldDeep,
              body: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: HomeOptionalAmalSection(
                  fields: const [
                    AmalField(
                      id: 'fard',
                      label: {'bn': 'ফরজ'},
                      sublabel: {'bn': ''},
                      points: 2,
                      order: 1,
                    ),
                    AmalField(
                      id: 'takbir',
                      label: {'bn': 'তাকবীর'},
                      sublabel: {'bn': ''},
                      points: 2,
                      order: 2,
                    ),
                  ],
                  uid: 'u1',
                  locale: 'bn',
                  readOnly: false,
                  onTapDetails: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomeOptionalAmalSection),
      matchesGoldenFile('tmp_optional_amal_preview.png'),
    );
  });
}
