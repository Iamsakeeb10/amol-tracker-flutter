import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'quran_test_app.dart';

/// Entry point for testing Indopak Nastaleeq + quran.sqlite.
///
/// Run with: `flutter run -t lib/main_quran_test.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  runApp(const QuranTestApp());
}
