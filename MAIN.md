import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app.dart';
import 'firebase_options.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();

// Firebase
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// Firestore offline persistence
FirebaseFirestore.instance.settings = const Settings(
persistenceEnabled: true,
cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// Hive local storage
await Hive.initFlutter();
await Hive.openBox('amal_logs');
await Hive.openBox('app_settings');

// Timezones for notifications
tz.initializeTimeZones();

runApp(
// Riverpod wrapper — wraps entire app
const ProviderScope(
child: AmolTrackerApp(),
),
);
}
