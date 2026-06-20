import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quran_ayah.dart';
import '../models/quran_reading_prefs.dart';
import 'quran_database_provider.dart';
import 'quran_reading_prefs_provider.dart';

final quranSurahAyahsProvider =
    FutureProvider.family<List<QuranAyah>, int>((ref, surahId) async {
  final db = await ref.watch(quranDatabaseProvider.future);
  final translator = ref.watch(
    quranReadingPrefsProvider.select((prefs) => prefs.translator),
  );
  final showTranslation = ref.watch(
    quranReadingPrefsProvider.select((prefs) => prefs.showTranslation),
  );
  return db.getAyahsForSurah(
    surahId,
    translator: translator.dbKey,
    includeTranslation: showTranslation,
  );
});
