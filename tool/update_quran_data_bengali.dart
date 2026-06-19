// Writes Bangla surah names (transliteration, not meaning) into
// assets/quran-data.xml as the `bname` attribute on each <sura> element.
//
// Usage (from project root):
//   dart run tool/update_quran_data_bengali.dart

import 'dart:io';

import 'package:xml/xml.dart';

import 'surah_names_bn.dart';

const _metadataXml = 'assets/quran-data.xml';

void main() {
  if (surahNamesBn.length != 114) {
    stderr.writeln('Expected 114 surah names, got ${surahNamesBn.length}');
    exit(1);
  }

  final file = File(_metadataXml);
  final document = XmlDocument.parse(file.readAsStringSync());
  var updated = 0;

  for (final sura in document.findAllElements('sura')) {
    final id = int.parse(sura.getAttribute('index') ?? '0');
    final bname = surahNamesBn[id];
    if (bname == null || bname.isEmpty) {
      stderr.writeln('Missing Bangla name for sura $id');
      exit(1);
    }
    sura.setAttribute('bname', bname);
    updated++;
  }

  file.writeAsStringSync('${document.toXmlString()}\n');
  stdout.writeln('Updated $updated surah entries in $_metadataXml');
}
