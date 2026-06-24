import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/mushaf_layout_info.dart';
import '../models/quran_ayah.dart';
import '../models/quran_surah.dart';
import 'quran_arabic_text_loader.dart';

const _assetDbPath = 'assets/quran_complete.sqlite';
const _dbFileName = 'quran_complete_v3.db';
const _tanzilArabicJoin =
    'INNER JOIN tanzil.quran_text t ON t.sura = a.surah AND t.aya = a.ayah';

class QuranDatabaseService {
  QuranDatabaseService(this._db);

  final Database _db;

  static Future<QuranDatabaseService>? _openFuture;
  static QuranDatabaseService? _cached;

  static Future<QuranDatabaseService> open() {
    final cached = _cached;
    if (cached != null && cached._db.isOpen) return Future.value(cached);
    return _openFuture ??= _openNew();
  }

  static Future<QuranDatabaseService> _openNew() async {
    try {
      final dbPath = await _resolveDbPath();
      final arabicDbPath = await QuranArabicTextLoader.ensureCachedDbPath();
      final db = await openDatabase(dbPath, readOnly: false);
      await _attachTanzilIfNeeded(db, arabicDbPath);
      final service = QuranDatabaseService(db);
      _cached = service;
      return service;
    } catch (error) {
      _openFuture = null;
      rethrow;
    }
  }

  static Future<void> _attachTanzilIfNeeded(
    Database db,
    String arabicDbPath,
  ) async {
    final escapedArabicPath = arabicDbPath.replaceAll("'", "''");
    try {
      await db.execute("ATTACH DATABASE '$escapedArabicPath' AS tanzil");
    } on DatabaseException catch (error) {
      if (!_isTanzilAlreadyAttached(error)) rethrow;
    }
  }

  static bool _isTanzilAlreadyAttached(DatabaseException error) {
    final message = error.toString().toLowerCase();
    return message.contains('already in use') ||
        message.contains('already exists');
  }

  static void _clearCacheIfCurrent(QuranDatabaseService service) {
    if (identical(_cached, service)) {
      _cached = null;
      _openFuture = null;
    }
  }

  static Future<String> _resolveDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/$_dbFileName';
    final file = File(dbPath);
    if (!await file.exists()) {
      final data = await rootBundle.load(_assetDbPath);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
    return dbPath;
  }

  Future<List<QuranSurah>> getAllSurahs() async {
    final rows = await _db.query(
      'suras',
      orderBy: 'id ASC',
    );
    return rows.map(QuranSurah.fromMap).toList(growable: false);
  }

  Future<QuranSurah?> getSurahById(int id) async {
    final rows = await _db.query(
      'suras',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return QuranSurah.fromMap(rows.first);
  }

  Future<List<QuranAyah>> getAyahsForPage(
    int page, {
    required String translator,
  }) async {
    final rows = await _db.rawQuery('''
      SELECT
        a.surah,
        a.ayah,
        t.text,
        a.page,
        a.juz,
        tr.text AS translation
      FROM ayat a
      $_tanzilArabicJoin
      LEFT JOIN translations tr
        ON tr.surah = a.surah
       AND tr.ayah = a.ayah
       AND tr.translator = ?
      WHERE a.page = ?
      ORDER BY a.surah ASC, a.ayah ASC
    ''', [translator, page]);
    return rows.map(QuranAyah.fromMap).toList(growable: false);
  }

  /// Loads ayahs (with translation) for explicit surah:ayah keys on a mushaf page.
  Future<List<QuranAyah>> getAyahsForKeys(
    List<MushafAyahKey> keys, {
    required String translator,
  }) async {
    if (keys.isEmpty) return const [];

    final conditions =
        keys.map((_) => '(a.surah = ? AND a.ayah = ?)').join(' OR ');
    final args = <Object?>[translator];
    for (final key in keys) {
      args.add(key.surah);
      args.add(key.ayah);
    }

    final rows = await _db.rawQuery('''
      SELECT
        a.surah,
        a.ayah,
        t.text,
        a.page,
        a.juz,
        tr.text AS translation
      FROM ayat a
      $_tanzilArabicJoin
      LEFT JOIN translations tr
        ON tr.surah = a.surah
       AND tr.ayah = a.ayah
       AND tr.translator = ?
      WHERE $conditions
      ORDER BY a.surah ASC, a.ayah ASC
    ''', args);

    return rows.map(QuranAyah.fromMap).toList(growable: false);
  }

  Future<List<QuranAyah>> getAyahsForSurah(
    int surahId, {
    required String translator,
    bool includeTranslation = true,
  }) async {
    if (!includeTranslation) {
      final rows = await _db.rawQuery('''
        SELECT
          a.surah,
          a.ayah,
          t.text,
          a.page,
          a.juz
        FROM ayat a
        $_tanzilArabicJoin
        WHERE a.surah = ?
        ORDER BY a.ayah ASC
      ''', [surahId]);
      return rows.map(QuranAyah.fromMap).toList(growable: false);
    }

    final rows = await _db.rawQuery('''
      SELECT
        a.surah,
        a.ayah,
        t.text,
        a.page,
        a.juz,
        tr.text AS translation
      FROM ayat a
      $_tanzilArabicJoin
      LEFT JOIN translations tr
        ON tr.surah = a.surah
       AND tr.ayah = a.ayah
       AND tr.translator = ?
      WHERE a.surah = ?
      ORDER BY a.ayah ASC
    ''', [translator, surahId]);
    return rows.map(QuranAyah.fromMap).toList(growable: false);
  }

  Future<int?> getJuzForPage(int page) async {
    final value = Sqflite.firstIntValue(
      await _db.rawQuery(
        'SELECT juz FROM ayat WHERE page = ? LIMIT 1',
        [page],
      ),
    );
    return value;
  }

  Future<int?> getSurahForPage(int page) async {
    final value = Sqflite.firstIntValue(
      await _db.rawQuery(
        'SELECT surah FROM ayat WHERE page = ? ORDER BY ayah ASC LIMIT 1',
        [page],
      ),
    );
    return value;
  }

  Future<int> getPageCount() async {
    final value = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT MAX(page) AS max_page FROM ayat'),
    );
    return value ?? 604;
  }

  Future<List<int>> getSurahStartsOnPage(int page) async {
    final rows = await _db.rawQuery(
      '''
      SELECT DISTINCT surah
      FROM ayat
      WHERE page = ? AND ayah = 1
      ORDER BY surah ASC
      ''',
      [page],
    );
    return rows.map((row) => row['surah']! as int).toList(growable: false);
  }

  Future<int?> getJuzForAyah(int surah, int ayah) async {
    return Sqflite.firstIntValue(
      await _db.rawQuery(
        'SELECT juz FROM ayat WHERE surah = ? AND ayah = ? LIMIT 1',
        [surah, ayah],
      ),
    );
  }

  Future<void> close() async {
    try {
      await _db.execute('DETACH DATABASE tanzil');
    } on DatabaseException catch (_) {
      // Ignore if the Tanzil database was not attached on this connection.
    }
    await _db.close();
    _clearCacheIfCurrent(this);
  }
}
