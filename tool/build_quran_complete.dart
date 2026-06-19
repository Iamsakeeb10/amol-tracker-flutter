// One-time / on-demand build script for the bundled Quran database.
//
// Usage (from project root):
//   dart pub get
//   dart run tool/build_quran_complete.dart
//
// Inputs (must exist):
//   assets/quran.sqlite       — Arabic ayahs + page/juz
//   assets/quran-data.xml     — 114 surah metadata
//   assets/bn.bengali.xml     — Bengali (Muhiuddin Khan)
//   assets/en.sahih.xml       — English (Sahih International)
//
// Output:
//   assets/quran_complete.sqlite — copy-ready DB for the app

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:xml/xml.dart';

const _sourceDb = 'assets/quran.sqlite';
const _outputDb = 'assets/quran_complete.sqlite';
const _metadataXml = 'assets/quran-data.xml';
const _khanXml = 'assets/bn.bengali.xml';
const _sahihXml = 'assets/en.sahih.xml';
const _batchSize = 500;

void main() {
  for (final path in [_sourceDb, _metadataXml, _khanXml, _sahihXml]) {
    if (!File(path).existsSync()) {
      stderr.writeln('Missing required file: $path');
      exit(1);
    }
  }

  final output = File(_outputDb);
  if (output.existsSync()) {
    output.deleteSync();
  }
  File(_sourceDb).copySync(_outputDb);

  final db = sqlite3.open(output.path);
  try {
    db.execute('PRAGMA journal_mode = OFF');
    db.execute('PRAGMA synchronous = OFF');

    _createTables(db);
    _populateSuras(db);
    _populateTranslations(db, _khanXml, 'khan');
    _populateTranslations(db, _sahihXml, 'sahih');

    final suraCount =
        db.select('SELECT COUNT(*) AS c FROM suras').first['c'] as int;
    final khanCount = db
        .select("SELECT COUNT(*) AS c FROM translations WHERE translator = 'khan'")
        .first['c'] as int;
    final sahihCount = db
        .select("SELECT COUNT(*) AS c FROM translations WHERE translator = 'sahih'")
        .first['c'] as int;
    final ayahCount =
        db.select('SELECT COUNT(*) AS c FROM ayat').first['c'] as int;

    stdout.writeln('Built $_outputDb');
    stdout.writeln('  ayat: $ayahCount');
    stdout.writeln('  suras: $suraCount');
    stdout.writeln('  translations (khan): $khanCount');
    stdout.writeln('  translations (sahih): $sahihCount');
    stdout.writeln('  size: ${(output.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB');
  } finally {
    db.dispose();
  }
}

void _createTables(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS suras (
      id INTEGER PRIMARY KEY,
      name_ar TEXT NOT NULL,
      name_en TEXT NOT NULL,
      name_bn TEXT NOT NULL DEFAULT '',
      name_transliteration TEXT NOT NULL,
      ayah_count INTEGER NOT NULL,
      type TEXT NOT NULL,
      revelation_order INTEGER NOT NULL,
      start_page INTEGER NOT NULL DEFAULT 1
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS translations (
      surah INTEGER NOT NULL,
      ayah INTEGER NOT NULL,
      text TEXT NOT NULL,
      translator TEXT NOT NULL,
      PRIMARY KEY (surah, ayah, translator)
    )
  ''');

  db.execute('DELETE FROM suras');
  db.execute('DELETE FROM translations');
}

void _populateSuras(Database db) {
  final document = XmlDocument.parse(File(_metadataXml).readAsStringSync());
  final startPages = {
    for (final row in db.select(
      'SELECT surah, MIN(page) AS start_page FROM ayat GROUP BY surah',
    ))
      row['surah'] as int: row['start_page'] as int? ?? 1,
  };

  final stmt = db.prepare('''
    INSERT INTO suras (
      id, name_ar, name_en, name_bn, name_transliteration,
      ayah_count, type, revelation_order, start_page
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''');

  db.execute('BEGIN');
  try {
    for (final sura in document.findAllElements('sura')) {
      final id = int.parse(sura.getAttribute('index') ?? '0');
      stmt.execute([
        id,
        sura.getAttribute('name') ?? '',
        sura.getAttribute('ename') ?? '',
        sura.getAttribute('bname') ?? '',
        sura.getAttribute('tname') ?? '',
        int.parse(sura.getAttribute('ayas') ?? '0'),
        sura.getAttribute('type') ?? '',
        int.parse(sura.getAttribute('order') ?? '0'),
        startPages[id] ?? 1,
      ]);
    }
    db.execute('COMMIT');
  } catch (error) {
    db.execute('ROLLBACK');
    rethrow;
  } finally {
    stmt.dispose();
  }
}

void _populateTranslations(Database db, String xmlPath, String translator) {
  final document = XmlDocument.parse(File(xmlPath).readAsStringSync());
  final stmt = db.prepare('''
    INSERT OR REPLACE INTO translations (surah, ayah, text, translator)
    VALUES (?, ?, ?, ?)
  ''');

  db.execute('BEGIN');
  try {
    var batchCount = 0;
    for (final sura in document.findAllElements('sura')) {
      final surahId = int.parse(sura.getAttribute('index') ?? '0');
      for (final aya in sura.findAllElements('aya')) {
        stmt.execute([
          surahId,
          int.parse(aya.getAttribute('index') ?? '0'),
          aya.getAttribute('text') ?? '',
          translator,
        ]);
        batchCount++;
        if (batchCount % _batchSize == 0) {
          db.execute('COMMIT');
          db.execute('BEGIN');
        }
      }
    }
    db.execute('COMMIT');
  } catch (error) {
    db.execute('ROLLBACK');
    rethrow;
  } finally {
    stmt.dispose();
  }
}
