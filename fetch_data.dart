import 'dart:convert';
import 'dart:io';

// ─── CONFIG ──────────────────────────────────────────────────────────────────
const String apiKey =
    'OZ1eE9Dc0FiyveNYKwi7zJ9Crm5fJyHOd1b0MnWXTNqrpbFT'; // <-- replace this
const String lang = 'bn'; // Bengali — change if needed
const String baseUrl = 'https://islamicapi.com/api/v1/dua/';
// ─────────────────────────────────────────────────────────────────────────────

final httpClient = HttpClient();

// ─── UNICODE CLEANER ─────────────────────────────────────────────────────────
// Removes invisible/control characters that appear in Bengali + Arabic API data.
// Safe: keeps all visible Bengali, Arabic, Latin, punctuation, newlines, tabs.
//
// Stripped characters:
//   U+200B  Zero Width Space
//   U+200C  Zero Width Non-Joiner (ZWNJ)
//   U+200D  Zero Width Joiner (ZWJ)
//   U+200E  Left-to-Right Mark
//   U+200F  Right-to-Left Mark
//   U+FEFF  BOM / Zero Width No-Break Space
//   U+00AD  Soft Hyphen
//   U+2060  Word Joiner
//   U+2061-U+2064  Invisible math operators
//   U+202A-U+202E  Directional formatting characters
//   U+2066-U+2069  Isolate formatting characters
//   U+FFF9-U+FFFB  Interlinear annotation characters
String cleanText(String text) {
  return text.replaceAll(
    RegExp(
      r'[\u00AD\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u2069\uFEFF\uFFF9-\uFFFB]',
    ),
    '',
  );
}

// Recursively walks any JSON value and cleans every string it finds.
dynamic cleanJson(dynamic value) {
  if (value is String) return cleanText(value);
  if (value is Map)
    return value.map((k, v) => MapEntry(k as String, cleanJson(v)));
  if (value is List) return value.map(cleanJson).toList();
  return value; // int, double, bool, null — untouched
}
// ─────────────────────────────────────────────────────────────────────────────

Future<Map<String, dynamic>> fetchJson(Map<String, String> params) async {
  final uri = Uri.parse(
    baseUrl,
  ).replace(queryParameters: {...params, 'api_key': apiKey, 'lang': lang});

  print('  -> GET $uri');

  final request = await httpClient.getUrl(uri);
  final response = await request.close();

  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode} for $uri');
  }

  final body = await response.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<void> saveJson(String path, Object data) async {
  // Clean all invisible unicode characters before writing to disk
  final cleaned = cleanJson(data);

  final file = File(path);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(cleaned),
    encoding: utf8,
  );

  final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
  print('  OK Saved $path ($sizeKb KB, unicode-cleaned)');
}

// ─── INVISIBLE CHARACTER AUDIT ───────────────────────────────────────────────
// Call this on raw JSON string BEFORE cleaning to see what was found.
void auditInvisibleChars(String label, String rawJson) {
  final targets = {
    '\u200B': 'U+200B Zero Width Space',
    '\u200C': 'U+200C ZWNJ',
    '\u200D': 'U+200D ZWJ',
    '\u200E': 'U+200E LRM',
    '\u200F': 'U+200F RLM',
    '\uFEFF': 'U+FEFF BOM',
    '\u00AD': 'U+00AD Soft Hyphen',
    '\u2060': 'U+2060 Word Joiner',
    '\u202A': 'U+202A LRE',
    '\u202B': 'U+202B RLE',
    '\u202C': 'U+202C PDF',
    '\u202D': 'U+202D LRO',
    '\u202E': 'U+202E RLO',
  };

  print('');
  print('-- Invisible char audit: $label --');
  bool found = false;
  for (final entry in targets.entries) {
    final count = entry.key.allMatches(rawJson).length;
    if (count > 0) {
      print('  FOUND x$count  ${entry.value}');
      found = true;
    }
  }
  if (!found) print('  None found — data is clean');
  print('');
}
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  print('\nDua Asset Fetcher');
  print('========================================');

  if (apiKey == 'YOUR_REAL_API_KEY') {
    print('\nERROR: Please replace YOUR_REAL_API_KEY with your actual key.');
    exit(1);
  }

  // Ensure assets directory exists
  await Directory('assets').create(recursive: true);

  try {
    // ── 1. Categories ────────────────────────────────────────────────────────
    print('\n[1/3] Fetching categories...');
    final catResponse = await fetchJson({'type': 'category'});
    if (catResponse['status'] != 'success') {
      throw Exception('API error: ${catResponse['message']}');
    }
    final catRawJson = jsonEncode(catResponse['data']);
    auditInvisibleChars('categories', catRawJson);
    await saveJson('assets/categories.json', catResponse['data']);

    // ── 2. Sub-categories ────────────────────────────────────────────────────
    print('\n[2/3] Fetching sub-categories...');
    final subCatResponse = await fetchJson({'type': 'sub-category'});
    if (subCatResponse['status'] != 'success') {
      throw Exception('API error: ${subCatResponse['message']}');
    }
    final subRawJson = jsonEncode(subCatResponse['data']);
    auditInvisibleChars('sub-categories', subRawJson);
    await saveJson('assets/sub_categories.json', subCatResponse['data']);

    // ── 3. All Duas ──────────────────────────────────────────────────────────
    print('\n[3/3] Fetching all duas (this may take a moment)...');
    final duaResponse = await fetchJson({'type': 'translation'});
    if (duaResponse['status'] != 'success') {
      throw Exception('API error: ${duaResponse['message']}');
    }
    final duaRawJson = jsonEncode(duaResponse['data']);
    auditInvisibleChars('duas', duaRawJson);
    await saveJson('assets/duas.json', duaResponse['data']);

    // ── Summary ──────────────────────────────────────────────────────────────
    final cats = (catResponse['data'] as List).length;
    final subs = (subCatResponse['data'] as List).length;
    final duas = (duaResponse['data'] as List).length;

    print('\n========================================');
    print('Done!');
    print('   Categories    : $cats');
    print('   Sub-categories: $subs');
    print('   Duas          : $duas');
    print('\nNext steps:');
    print('  1. Check pubspec.yaml has the assets/ entries');
    print('  2. Run: flutter pub get');
    print('  3. Run: flutter run');
    print('');
  } catch (e) {
    print('\nFailed: $e');
    exit(1);
  } finally {
    httpClient.close();
  }
}
