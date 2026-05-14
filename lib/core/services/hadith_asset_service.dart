import 'dart:convert';

import 'package:flutter/services.dart';

class HadithAssetService {
  const HadithAssetService._();

  static const String assetPath = 'assets/hadiths/hadiths.json';
  static Future<List<String>>? _cachedHadithTexts;

  static Future<List<String>> loadHadithTexts() {
    return _cachedHadithTexts ??= _loadHadithTexts();
  }

  static Future<List<String>> _loadHadithTexts() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .map(_formatHadith)
          .where((hadith) => hadith.isNotEmpty)
          .toList(growable: false);
    } catch (e, st) {
      print('HadithAssetService error: $e\n$st'); // ← add this
      return const [];
    }
  }

  static String _formatHadith(Object? entry) {
    if (entry is String) return entry.trim();
    if (entry is! Map) return '';

    final text = entry['text']?.toString().trim() ?? '';
    final reference = entry['reference']?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    if (reference.isEmpty) return text;
    return '$text - $reference';
  }
}
