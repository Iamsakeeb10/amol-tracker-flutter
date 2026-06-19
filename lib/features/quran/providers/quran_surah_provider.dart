import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quran_surah.dart';
import 'quran_database_provider.dart';

final quranSurahListProvider = FutureProvider<List<QuranSurah>>((ref) async {
  ref.keepAlive();
  final db = await ref.watch(quranDatabaseProvider.future);
  return db.getAllSurahs();
});

final quranSurahByIdProvider =
    FutureProvider.family<QuranSurah?, int>((ref, surahId) async {
  final db = await ref.watch(quranDatabaseProvider.future);
  return db.getSurahById(surahId);
});
