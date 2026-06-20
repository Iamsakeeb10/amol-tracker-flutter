import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mushaf_layout_info.dart';
import '../models/quran_ayah.dart';
import '../models/quran_mushaf_page_data.dart';
import '../models/quran_reading_prefs.dart';
import '../models/quran_surah.dart';
import 'mushaf_database_provider.dart';
import 'quran_database_provider.dart';
import 'quran_surah_provider.dart';

/// Cache key for mushaf page queries (page number only — layout is fixed).
class MushafPageQuery {
  const MushafPageQuery({required this.page});

  final int page;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MushafPageQuery && page == other.page;

  @override
  int get hashCode => page.hashCode;
}

/// Cache key for mushaf page translations (610-page layout → ayah keys).
class MushafPageAyahsQuery {
  const MushafPageAyahsQuery({
    required this.page,
    required this.translator,
  });

  final int page;
  final String translator;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MushafPageAyahsQuery &&
          page == other.page &&
          translator == other.translator;

  @override
  int get hashCode => Object.hash(page, translator);
}

final mushafLayoutInfoProvider = FutureProvider<MushafLayoutInfo>((ref) async {
  ref.keepAlive();
  final db = await ref.watch(mushafDatabaseProvider.future);
  return db.getLayoutInfo();
});

final quranPageCountProvider = FutureProvider<int>((ref) async {
  ref.keepAlive();
  final db = await ref.watch(mushafDatabaseProvider.future);
  return db.getPageCount();
});

final mushafSurahStartPagesProvider =
    FutureProvider<Map<int, int>>((ref) async {
  ref.keepAlive();
  final db = await ref.watch(mushafDatabaseProvider.future);
  return db.getAllSurahStartPages();
});

final quranMushafPageProvider =
    FutureProvider.family<QuranMushafPageData, MushafPageQuery>((ref, query) async {
  ref.keepAlive();
  final mushafDb = await ref.watch(mushafDatabaseProvider.future);
  final quranDb = await ref.watch(quranDatabaseProvider.future);
  final surahs = await ref.watch(quranSurahListProvider.future);
  final info = await ref.watch(mushafLayoutInfoProvider.future);

  final lineRows = await mushafDb.getLinesForPage(query.page);
  if (lineRows.isEmpty) {
    return QuranMushafPageData(
      page: query.page,
      juz: 1,
      linesPerPage: info.linesPerPage,
      lines: const [],
    );
  }

  final surahNameById = {for (final s in surahs) s.id: s.nameAr};

  final wordIds = <int>[];
  for (final line in lineRows) {
    if (line.firstWordId != null && line.lastWordId != null) {
      wordIds.add(line.firstWordId!);
      wordIds.add(line.lastWordId!);
    }
  }

  Map<int, MushafWord> wordsById = const {};
  if (wordIds.isNotEmpty) {
    final minId = wordIds.reduce((a, b) => a < b ? a : b);
    final maxId = wordIds.reduce((a, b) => a > b ? a : b);
    final wordsInRange = await mushafDb.getWordsInIdRange(minId, maxId);
    wordsById = {for (final w in wordsInRange) w.id: w};
  }

  final layoutSurahNames = lineRows
      .where((line) => line.lineType == 'surah_name')
      .map((line) => line.surahNumber)
      .whereType<int>()
      .toSet();

  final surahsStartingOnPage = await mushafDb.getSurahsStartingOnPage(query.page);
  final injectableSurahs = surahsStartingOnPage
      .where((id) => !layoutSurahNames.contains(id))
      .toList(growable: false);
  final firstWordIdBySurah =
      await mushafDb.getFirstWordIdBySurah(injectableSurahs);
  final surahIdByFirstWordId = {
    for (final entry in firstWordIdBySurah.entries) entry.value: entry.key,
  };
  final injectedSurahs = <int>{};

  final renderedLines = <MushafRenderedLine>[];
  for (final line in lineRows) {
    if (line.lineType == 'ayah' && line.firstWordId != null) {
      final surahId = surahIdByFirstWordId[line.firstWordId];
      if (surahId != null && injectedSurahs.add(surahId)) {
        renderedLines.add(
          _surahNameLine(surahId, surahNameById),
        );
      }
    }
    renderedLines.add(
      _renderLine(line, wordsById, surahNameById),
    );
  }

  final firstWord = await mushafDb.getFirstWordOnPage(query.page);
  var juz = 1;
  if (firstWord != null) {
    juz = await quranDb.getJuzForAyah(firstWord.surah, firstWord.ayah) ?? 1;
  }

  return QuranMushafPageData(
    page: query.page,
    juz: juz,
    linesPerPage: info.linesPerPage,
    lines: renderedLines,
  );
});

final quranMushafPageAyahsProvider =
    FutureProvider.family<List<QuranAyah>, MushafPageAyahsQuery>((ref, query) async {
  ref.keepAlive();
  final mushafDb = await ref.watch(mushafDatabaseProvider.future);
  final quranDb = await ref.watch(quranDatabaseProvider.future);
  final keys = await mushafDb.getAyahKeysOnPage(query.page);
  return quranDb.getAyahsForKeys(keys, translator: query.translator);
});

MushafRenderedLine _surahNameLine(
  int surahId,
  Map<int, String> surahNameById,
) {
  return MushafRenderedLine(
    lineNumber: 0,
    lineType: 'surah_name',
    isCentered: true,
    surahNumber: surahId,
    text: surahNameById[surahId] ?? '',
  );
}

MushafRenderedLine _renderLine(
  MushafLineRow line,
  Map<int, MushafWord> wordsById,
  Map<int, String> surahNameById,
) {
  switch (line.lineType) {
    case 'surah_name':
      final surahId = line.surahNumber ?? 1;
      return MushafRenderedLine(
        lineNumber: line.lineNumber,
        lineType: line.lineType,
        isCentered: line.isCentered,
        surahNumber: surahId,
        text: surahNameById[surahId] ?? '',
      );
    case 'basmallah':
      return MushafRenderedLine(
        lineNumber: line.lineNumber,
        lineType: line.lineType,
        isCentered: line.isCentered,
        text: mushafBismillahText,
      );
    default:
      final first = line.firstWordId;
      final last = line.lastWordId;
      if (first == null || last == null) {
        return MushafRenderedLine(
          lineNumber: line.lineNumber,
          lineType: line.lineType,
          isCentered: line.isCentered,
          text: '',
        );
      }
      final lineWords = <MushafWord>[];
      for (var id = first; id <= last; id++) {
        final word = wordsById[id];
        if (word != null) lineWords.add(word);
      }
      final segments = buildMushafLineSegments(lineWords);
      return MushafRenderedLine(
        lineNumber: line.lineNumber,
        lineType: line.lineType,
        isCentered: line.isCentered,
        segments: segments,
        text: mushafSegmentsToPlainText(segments),
      );
  }
}

const mushafBismillahText =
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

/// Convenience: current mushaf page query from reading prefs.
MushafPageQuery currentMushafPageQuery(QuranReadingPrefs prefs) {
  return MushafPageQuery(page: prefs.lastMushafPage);
}

// Re-export for providers that need surah list on page — kept for compatibility.
final quranSurahsForPageProvider =
    FutureProvider.family<List<QuranSurah>, int>((ref, page) async {
  final startPages = await ref.watch(mushafSurahStartPagesProvider.future);
  final surahs = await ref.watch(quranSurahListProvider.future);
  return surahs
      .where((s) => startPages[s.id] == page)
      .toList(growable: false);
});
