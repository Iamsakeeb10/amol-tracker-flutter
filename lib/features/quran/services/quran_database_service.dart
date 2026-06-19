import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/quran_ayah.dart';
import '../models/quran_surah.dart';

const _assetDbPath = 'assets/quran_complete.sqlite';
const _dbFileName = 'quran_complete_v3.db';

class QuranDatabaseService {
  QuranDatabaseService(this._db);

  final Database _db;

  static Future<QuranDatabaseService> open() async {
    final dbPath = await _resolveDbPath();
    final db = await openDatabase(dbPath, readOnly: false);
    return QuranDatabaseService(db);
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
        a.text,
        a.page,
        a.juz,
        t.text AS translation
      FROM ayat a
      LEFT JOIN translations t
        ON t.surah = a.surah
       AND t.ayah = a.ayah
       AND t.translator = ?
      WHERE a.page = ?
      ORDER BY a.surah ASC, a.ayah ASC
    ''', [translator, page]);
    return rows.map(QuranAyah.fromMap).toList(growable: false);
  }

  Future<List<QuranAyah>> getAyahsForSurah(
    int surahId, {
    required String translator,
  }) async {
    final rows = await _db.rawQuery('''
      SELECT
        a.surah,
        a.ayah,
        a.text,
        a.page,
        a.juz,
        t.text AS translation
      FROM ayat a
      LEFT JOIN translations t
        ON t.surah = a.surah
       AND t.ayah = a.ayah
       AND t.translator = ?
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

  Future<void> close() => _db.close();
}
