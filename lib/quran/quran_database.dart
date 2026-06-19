import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';

import 'models/quran_ayah.dart';

/// Loads the bundled [assets/quran.sqlite] edition paired with
/// [Indopak Nastaleeq](https://fonts.quran.ws/fonts/indopak-nastaleeq).
///
/// Uses [sqlite3] (FFI) instead of sqflite to avoid platform-channel issues
/// such as `MissingPluginException` on `getDatabasesPath` after hot restart.
class QuranDatabase {
  QuranDatabase._();

  static final QuranDatabase instance = QuranDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) {
      return existing;
    }

    if (kIsWeb) {
      throw UnsupportedError(
        'quran.sqlite is not supported on web. Run on iOS, Android, or desktop.',
      );
    }

    final bytes = await rootBundle.load('assets/quran.sqlite');
    final data = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );

    final tempFile = File('${Directory.systemTemp.path}/quran_test.sqlite');
    if (!await tempFile.exists() || await tempFile.length() != data.length) {
      await tempFile.writeAsBytes(data, flush: true);
    }

    _db = sqlite3.open(tempFile.path, mode: OpenMode.readOnly);
    return _db!;
  }

  Future<int> ayahCount() async {
    final db = await database;
    final row = db.select('SELECT COUNT(*) AS count FROM ayat').first;
    return row['count']! as int;
  }

  Future<List<QuranAyah>> ayatForSurah(int surah) async {
    final db = await database;
    final rows = db.select(
      '''
      SELECT surah, ayah, text, page, juz
      FROM ayat
      WHERE surah = ?
      ORDER BY ayah ASC
      ''',
      [surah],
    );
    return rows.map(QuranAyah.fromMap).toList(growable: false);
  }

  Future<QuranAyah?> ayah({required int surah, required int ayah}) async {
    final db = await database;
    final rows = db.select(
      '''
      SELECT surah, ayah, text, page, juz
      FROM ayat
      WHERE surah = ? AND ayah = ?
      LIMIT 1
      ''',
      [surah, ayah],
    );
    if (rows.isEmpty) {
      return null;
    }
    return QuranAyah.fromMap(rows.first);
  }

  Future<List<QuranAyah>> ayatForPage(int page) async {
    final db = await database;
    final rows = db.select(
      '''
      SELECT surah, ayah, text, page, juz
      FROM ayat
      WHERE page = ?
      ORDER BY surah ASC, ayah ASC
      ''',
      [page],
    );
    return rows.map(QuranAyah.fromMap).toList(growable: false);
  }
}
