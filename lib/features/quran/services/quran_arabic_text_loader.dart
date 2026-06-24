import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _assetDbPath = 'assets/quran_tanzil_text.db';
const _dbFileName = 'quran_tanzil_text_v1.db';

/// Resolves the on-device path for the pre-built Tanzil Arabic text database.
class QuranArabicTextLoader {
  QuranArabicTextLoader._();

  /// Returns the path to a SQLite DB with table `quran_text(sura, aya, text)`.
  static Future<String> ensureCachedDbPath() async {
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
}
