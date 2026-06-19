import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quran_ayah.dart';
import '../models/quran_reading_prefs.dart';
import '../models/quran_surah.dart';
import 'quran_database_provider.dart';
import 'quran_reading_prefs_provider.dart';

final quranPageAyahsProvider =
    FutureProvider.family<List<QuranAyah>, int>((ref, page) async {
  final db = await ref.watch(quranDatabaseProvider.future);
  final prefs = ref.watch(quranReadingPrefsProvider);
  return db.getAyahsForPage(
    page,
    translator: prefs.translator.dbKey,
  );
});

final quranPageSurahProvider =
    FutureProvider.family<QuranSurah?, int>((ref, page) async {
  final db = await ref.watch(quranDatabaseProvider.future);
  final surahId = await db.getSurahForPage(page);
  if (surahId == null) return null;
  return db.getSurahById(surahId);
});

final quranPageJuzProvider = FutureProvider.family<int?, int>((ref, page) async {
  final db = await ref.watch(quranDatabaseProvider.future);
  return db.getJuzForPage(page);
});
