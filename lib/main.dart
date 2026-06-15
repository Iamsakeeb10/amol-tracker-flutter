import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // ADD THIS
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/colors.dart';
import 'core/utils/fcm_notification_display.dart';
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
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await LocalStorageService.initialize();

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
