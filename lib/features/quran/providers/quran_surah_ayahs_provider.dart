import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quran_ayah.dart';
import '../models/quran_reading_prefs.dart';
import 'quran_database_provider.dart';
import 'quran_reading_prefs_provider.dart';

final quranSurahAyahsProvider =
    FutureProvider.family<List<QuranAyah>, int>((ref, surahId) async {
  final db = await ref.watch(quranDatabaseProvider.future);
  final prefs = ref.watch(quranReadingPrefsProvider);
  return db.getAyahsForSurah(
    surahId,
    translator: prefs.translator.dbKey,
  );
});
