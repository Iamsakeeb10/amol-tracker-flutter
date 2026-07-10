import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/colors.dart';
import 'core/utils/fcm_notification_display.dart';
import 'features/widget/home_widget_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.notification == null) {
    await FcmNotificationDisplay.show(message);
  }
}

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized(); // CHANGE THIS LINE
  FlutterNativeSplash.preserve(widgetsBinding: binding); // ADD THIS

  tz.initializeTimeZones();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Capture Flutter framework errors and Dart isolate errors (release only)
  if (kReleaseMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await LocalStorageService.initialize();
  // Immediately push hijri date + cached streak to widget (no auth needed).
  unawaited(HomeWidgetService.quickPreloadWidget());

  runApp(const ProviderScope(child: _RootApp()));
}

class _RootApp extends StatelessWidget {
  const _RootApp();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) => const ColoredBox(
        color: AppColors.emeraldDeep,
        child: AmolTrackerApp(),
      ),
    );
  }
}
