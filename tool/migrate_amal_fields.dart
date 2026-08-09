import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  const batchSize = 500;

  const femaleDeprioritizedIds = <String>{
    'fard_salah',
    'fard',
    'takbir',
  };

  const disableDuringSpecialTimeIds = <String>{
    'fard_salah',
    'fard',
    'takbir',
    'quran',
    'mulk',
    'sunnah',
    'post_azkar',
  };

  final options = FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: const String.fromEnvironment('FIREBASE_SENDER_ID'),
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );

  if (options.apiKey.isEmpty) {
    stdout.writeln(
      'Error: Firebase options not provided via environment variables.',
    );
    stdout.writeln(
      'Set FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_SENDER_ID, '
      'FIREBASE_PROJECT_ID, FIREBASE_STORAGE_BUCKET',
    );
    exit(1);
  }

  await Firebase.initializeApp(options: options);

  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('amal_fields').get();
  final total = snapshot.docs.length;

  if (total == 0) {
    stdout.writeln('No amal_fields documents found.');
    exit(0);
  }

  var migrated = 0;
  var batch = firestore.batch();
  var count = 0;

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final id = (data['id'] as String?)?.trim().isNotEmpty == true
        ? data['id'] as String
        : doc.id;

    final femaleDeprioritized = femaleDeprioritizedIds.contains(id);
    final disableDuringSpecialTime = disableDuringSpecialTimeIds.contains(id);

    batch.update(doc.reference, {
      'genderVisibility': 'all',
      'femaleDeprioritized': femaleDeprioritized,
      'disableDuringSpecialTime': disableDuringSpecialTime,
    });

    count++;
    migrated++;

    if (count >= batchSize) {
      await batch.commit();
      batch = firestore.batch();
      count = 0;
      stdout.writeln('Migrated $migrated/$total fields');
    }
  }

  if (count > 0) {
    await batch.commit();
  }

  stdout.writeln('Migrated $migrated/$total fields');
}
