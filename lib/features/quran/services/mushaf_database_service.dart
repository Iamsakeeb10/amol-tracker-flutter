import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/mushaf_layout_info.dart';

const _layoutAssetPath = 'assets/qpc-nastaleeq-15-lines.db';
const _wordsAssetPath = 'assets/qpc-nastaleeq.db';
const _layoutFileName = 'qpc_nastaleeq_layout_v1.db';
const _wordsFileName = 'qpc_nastaleeq_words_v1.db';

class MushafDatabaseService {
  MushafDatabaseService(this._layoutDb, this._wordsDb);

  final Database _layoutDb;
  final Database _wordsDb;
  Map<int, int>? _surahStartPagesCache;

  static Future<MushafDatabaseService> open() async {
    final layoutPath = await _resolveDbPath(_layoutAssetPath, _layoutFileName);
    final wordsPath = await _resolveDbPath(_wordsAssetPath, _wordsFileName);
    final layoutDb = await openDatabase(layoutPath, readOnly: true);
    final wordsDb = await openDatabase(wordsPath, readOnly: true);
    return MushafDatabaseService(layoutDb, wordsDb);
  }

  static Future<String> _resolveDbPath(String assetPath, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/$fileName';
    final file = File(dbPath);
    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return dbPath;
  }

  Future<MushafLayoutInfo> getLayoutInfo() async {
    final rows = await _layoutDb.query('info', limit: 1);
    if (rows.isEmpty) {
      return const MushafLayoutInfo(
        name: 'QPC Nastaleeq 15 lines',
        pageCount: 610,
        linesPerPage: 15,
        fontName: 'qpc-nastaleeq',
      );
    }
    return MushafLayoutInfo.fromMap(rows.first);
  }

  Future<int> getPageCount() async {
    final info = await getLayoutInfo();
    return info.pageCount;
  }

  Future<List<MushafLineRow>> getLinesForPage(int pageNumber) async {
    final rows = await _layoutDb.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );
    return rows.map(MushafLineRow.fromMap).toList(growable: false);
  }

  Future<List<MushafWord>> getWordsInIdRange(int firstId, int lastId) async {
    final rows = await _wordsDb.query(
      'words',
      where: 'id >= ? AND id <= ?',
      whereArgs: [firstId, lastId],
      orderBy: 'id ASC',
    );
    return rows.map(MushafWord.fromMap).toList(growable: false);
  }

  Future<MushafWord?> getFirstWordOnPage(int pageNumber) async {
    final lines = await getLinesForPage(pageNumber);
    for (final line in lines) {
      if (line.lineType != 'ayah' || line.firstWordId == null) continue;
      final rows = await _wordsDb.query(
        'words',
        where: 'id = ?',
        whereArgs: [line.firstWordId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return MushafWord.fromMap(rows.first);
    }
    return null;
  }

  Future<int?> getStartPageForSurah(int surahId) async {
    final wordRows = await _wordsDb.query(
      'words',
      columns: ['id'],
      where: 'surah = ? AND ayah = 1 AND word = 1',
      whereArgs: [surahId],
      limit: 1,
    );
    if (wordRows.isEmpty) return null;
    final wordId = parseMushafInt(wordRows.first['id']);
    if (wordId == null) return null;

    final pageRows = await _layoutDb.rawQuery(
      '''
      SELECT MIN(page_number) AS page
      FROM pages
      WHERE line_type = 'ayah'
        AND first_word_id <= ?
        AND last_word_id >= ?
      ''',
      [wordId, wordId],
    );
    return parseMushafInt(pageRows.first['page']);
  }

  Future<Map<int, int>> getFirstWordIdBySurah(Iterable<int> surahIds) async {
    final ids = surahIds.toList(growable: false);
    if (ids.isEmpty) return const {};

    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await _wordsDb.rawQuery(
      '''
      SELECT id, surah
      FROM words
      WHERE ayah = 1 AND word = 1 AND surah IN ($placeholders)
      ''',
      ids,
    );

    final result = <int, int>{};
    for (final row in rows) {
      final surahId = parseMushafInt(row['surah']);
      final wordId = parseMushafInt(row['id']);
      if (surahId != null && wordId != null) {
        result[surahId] = wordId;
      }
    }
    return result;
  }

  Future<List<int>> getSurahsStartingOnPage(int pageNumber) async {
    final startPages = await getAllSurahStartPages();
    return startPages.entries
        .where((entry) => entry.value == pageNumber)
        .map((entry) => entry.key)
        .toList(growable: false)
      ..sort();
  }

  Future<Map<int, int>> getAllSurahStartPages() async {
    if (_surahStartPagesCache != null) return _surahStartPagesCache!;

    final wordRows = await _wordsDb.query(
      'words',
      columns: ['id', 'surah'],
      where: 'ayah = 1 AND word = 1',
      orderBy: 'surah ASC',
    );
    final pageRows = await _layoutDb.query(
      'pages',
      columns: ['page_number', 'first_word_id', 'last_word_id'],
      where: "line_type = 'ayah'",
      orderBy: 'page_number ASC',
    );

    final pageRanges = pageRows
        .map((row) {
          final pageNumber = parseMushafInt(row['page_number']);
          final first = parseMushafInt(row['first_word_id']);
          final last = parseMushafInt(row['last_word_id']);
          if (pageNumber == null || first == null || last == null) return null;
          return (page: pageNumber, first: first, last: last);
        })
        .whereType<({int page, int first, int last})>()
        .toList(growable: false);

    final startPages = <int, int>{};
    for (final row in wordRows) {
      final surahId = parseMushafInt(row['surah']);
      final wordId = parseMushafInt(row['id']);
      if (surahId == null || wordId == null) continue;

      int? minPage;
      for (final range in pageRanges) {
        if (wordId < range.first || wordId > range.last) continue;
        if (minPage == null || range.page < minPage) {
          minPage = range.page;
        }
      }
      if (minPage != null) {
        startPages[surahId] = minPage;
      }
    }

    _surahStartPagesCache = startPages;
    return startPages;
  }

  /// Distinct surah:ayah pairs appearing on a mushaf page (610-page layout).
  Future<List<MushafAyahKey>> getAyahKeysOnPage(int pageNumber) async {
    final lines = await getLinesForPage(pageNumber);
    final wordIds = <int>[];
    for (final line in lines) {
      if (line.firstWordId != null && line.lastWordId != null) {
        wordIds.add(line.firstWordId!);
        wordIds.add(line.lastWordId!);
      }
    }
    if (wordIds.isEmpty) return const [];

    final minId = wordIds.reduce((a, b) => a < b ? a : b);
    final maxId = wordIds.reduce((a, b) => a > b ? a : b);
    final rows = await _wordsDb.rawQuery(
      '''
      SELECT DISTINCT surah, ayah
      FROM words
      WHERE id >= ? AND id <= ?
      ORDER BY surah ASC, ayah ASC
      ''',
      [minId, maxId],
    );

    return rows
        .map((row) {
          final surah = parseMushafInt(row['surah']);
          final ayah = parseMushafInt(row['ayah']);
          if (surah == null || ayah == null) return null;
          return MushafAyahKey(surah: surah, ayah: ayah);
        })
        .whereType<MushafAyahKey>()
        .toList(growable: false);
  }

  Future<void> close() async {
    await _layoutDb.close();
    await _wordsDb.close();
  }
}
